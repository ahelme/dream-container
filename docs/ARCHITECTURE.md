# 💭 DreamContainer v2 — Architecture

**Status:** Living document · Decisions as of 2026-08-02
**Companions:** [DreamTeams](https://github.com/ahelme/dream-teams) (collaboration layer) · DreamKit (application template, milestone 3)

---

## 1. What DreamContainer is (and is not)

DreamContainer is a **per-agent runtime for a multi-agent VPS**: one isolated,
RAM-budgeted, scoped-credential Docker container per Claude Code agent, plus
the small set of shared services those containers rely on. A thin
`devcontainer.json` rides on the same image for anyone attaching VS Code, but
headless `docker compose` on a server is the primary citizen.

It is **not** an application stack. Databases, APIs and frontends belong to
each project's own compose files (or DreamKit). v1 bundled these; v2
deliberately does not.

**Design drivers, in priority order:**

1. **Isolation** — one compromised agent must not compromise its neighbours,
   the host, or the credential store. (The problem that motivated v2: many
   agents under one Unix user in one shared environment.)
2. **RAM frugality** — Claude Code is a Node process that comfortably sits at
   0.5–1.5 GB per active session. That is the floor; everything around it
   must be lean. A 4 GB VPS should run 2–3 concurrently *active* agents plus
   several idle ones; 8–16 GB is "many agents" territory.
3. **Zero-ritual ergonomics** — every "remember to…" becomes a property the
   container simply has. Persistent auth, team context, launch flags: baked
   in, not remembered.

## 2. Trust model

| Component | Trust level |
|---|---|
| VPS host (root, systemd, Docker daemon) | Trusted |
| Shared-infra zone (deployer, agent-vault, Postgres, Mattermost, Caddy) | Privileged — hardened, minimal, owner-administered |
| Agent containers | **Semi-trusted** — assumed compromisable via prompt injection or malicious dependencies |
| Content agents read (web, PRs, issues, chat) | Untrusted |

Consequences:

- Agent containers get **no Docker socket, no docker-in-docker, ever**.
  Docker access is root access; the moment agents can talk to a daemon, the
  isolation story is over.
- Credentials follow the rule: **the component that processes untrusted
  input must not hold secrets** (see §6–7).
- Agent containers reach the privileged zone only through narrow,
  authenticated HTTP interfaces (deploy webhook, credential proxy, chat).

> **⚠️ One box, one trust level.** This architecture assumes the host serves
> a single trust level. Running production workloads on the same box as
> semi-trusted agents means a container escape lands in production. The
> same-host mitigations here (separate Docker networks, loopback-only
> management ports, no socket mounts) reduce but cannot remove that risk.
> The architecture is already two-server-shaped — every cross-zone
> interaction is HTTP or git — so when you split agents from
> production/shared-infra, it's hostname changes in `.env`, not a redesign.

## 3. The layers

```
┌────────────────────────────────────────────────────────────┐
│  DreamTeams (collaboration layer — rides on git + chat)    │
│  skills · identities · rituals · coach agent · session logs│
├────────────────────────────────────────────────────────────┤
│  DreamContainer runtime (this repo)                        │
│  one container per agent · scoped creds · RAM limits       │
├────────────────────────────────────────────────────────────┤
│  Shared-infra zone (privileged)                            │
│  deployer · agent-vault · Postgres · Mattermost · Caddy    │
├────────────────────────────────────────────────────────────┤
│  Host: Docker (rootless preferred) · systemd · infisical   │
│  agent (secrets broker) · systemd-creds (at-rest)          │
└────────────────────────────────────────────────────────────┘
```

## 4. The agent container

### Images

- **`dreamcontainer/base`** (default): Debian slim + Claude Code, `gh`, git,
  node, ripgrep, fzf, jq, tmux, the Infisical CLI (a small Go binary). No
  browser, no browser libs, no MCP browser servers, no BuildKit. Target: a
  few hundred MB.
- **`dreamcontainer/browser`**: base + Chromium + Playwright deps +
  `--shm-size` guidance, for the projects that genuinely automate browsers.
  Opt-in per project, never default.

Multi-arch (arm64 + amd64) via `docker buildx bake`, published to GHCR by CI,
**rebuilt weekly** so security patches arrive automatically. All state lives
in volumes, so rebuilds are painless — that *is* the persistent-auth story.

Because every agent container shares one base image, shared libraries land in
the host page cache once, not N times.

### Canonical mounts (fixes the symlink-depth problem by construction)

| Mount | Path | Mode |
|---|---|---|
| Project workspace volume | `/workspace` | rw |
| Claude auth/config volume | `~/.claude` (`CLAUDE_CONFIG_DIR`) | rw |
| gh config volume (fallback auth path) | `~/.config/gh` | rw |
| Teams repo clone | `/team` | rw (git-mediated) |
| Ops/system repo clone | `/team-system` | **ro** + read-only PAT |
| Secrets file (broker-rendered) | `/run/secrets/project.env` | ro, tmpfs-backed |

Every container sees identical paths — `file-paths-registry.sh`-style
depth-counting is gone.

### Baked-in launch semantics

The image's entrypoint exports `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`
and the `claude` launch wrapper always passes `--add-dir /team --add-dir
/team-system`. **There is no bare-launch path**: the docs-verified requirement
(both the env var *and* `--add-dir` are needed for shared CLAUDE.md loading;
`permissions.additionalDirectories` grants file access only, never config)
is satisfied by construction. The container *is* the launch alias.

tmux runs as the session harness so SSH disconnects never kill an agent.

### Resource limits (default-on, sized in `.env`)

```yaml
mem_limit: 3g          # V8 heap capped below this via NODE_OPTIONS
memswap_limit: 4g      # idle agents swap out cheaply
pids_limit: 512
cpus: 2
environment:
  NODE_OPTIONS: "--max-old-space-size=2048"   # GC before the cgroup ceiling
```

Host-side: zram or a modest swapfile. Idle agent sessions swap out
beautifully; an agent you're not talking to costs almost nothing under
memory pressure.

### Per-project plugins manifest

`dream new` consumes an optional `plugins.json` per project: pre-seeds
`.mcp.json`, `enabledPlugins`, and marketplace entries inside the container
(the DreamTeams plugins — teams-chat + transport, team-detect,
cleanup-orphaned-mcp — are the expected first entries).

## 5. Repositories and write tiers

The write-permission boundary is the **repo boundary**, enforced by
per-agent fine-grained PATs (per-repo granularity — which is exactly why
each tier is its own repo). Three shared repos + N project repos:

| Repo | Contents | Agent access | Merge authority |
|---|---|---|---|
| **Teams repo** (`/team`) | agent_docs, ADRs, progress, per-agent session logs, chat identities | **read-write**, push freely *as themselves* | none needed — attribution + revertability via git history |
| **Skills repo** | skills (prose instructions) | read + PR | **coach agent** merges (see below) |
| **System/ops repo** (`/team-system`) | hooks, agent_tools, settings.json (executable guardrails) + deploy scripts, env templates | read-only; scripts team: branch + PR | **human** merges; protected main |
| Project repos | the actual code | per-project scoped PAT | project workflow (pr-test / pr-prod skills) |

Rationale:

- **Agents editing their own skills mid-conversation is a feature** — it
  happens in the agent's own clone and takes effect locally, immediately.
  *Publishing* a skill to the whole team is the injection vector, so that is
  what goes through review. Edit freely, publish through review.
- **The coach agent** (calm observer / team-process role) holds merge rights
  on the skills repo *and nothing else* — its PAT can't deploy, can't reach
  the secrets broker, can't write the system tier. It reviews diffs **as
  data, never as instructions**, against a structured checklist. A fooled
  coach has a small, fully revertable blast radius.
- **Skills are prose; hooks/tools/settings are code.** Code executes with
  the agent's (or deployer's) privileges, so the executable tier stays
  human-merge-only.
- The **deployer executes only from the system repo's main** at a pinned
  ref — a rogue scripts-team agent can propose a malicious deploy script but
  never get it executed without a human merge in between.
- Merge-friendly conventions in the teams repo: per-agent/per-team files,
  append-oriented logs, `git pull --rebase` folded into the resume-context /
  handover rituals, and a `CONVENTIONS.md` stating the two rules: *you own
  files bearing your name; shared files are append-only or generated.*
  (Session logs: per-agent files + generated combined view — see the
  dream-teams `team-log` PR.)
- **Migration path:** GitHub App instead of PATs (installation tokens expire
  in 1 h, scoped at mint time; the App private key lives host-side in the
  broker). Gotcha: installation tokens don't work for ghcr.io.

## 6. Secrets

**Source of truth: Infisical Cloud.** Per-project machine identities
(Universal Auth), scoped to that project's dev/test environment only — never
prod.

**Rule: no Infisical MCP server.** It hands secret values to the agent
through tool calls — found leaking agent-proxied secrets in practice. The
credential *proxy* (§7) is the opposite mechanism: the agent never receives
a value at all.

### Day-one hardening (10 minutes, biggest win per effort)

- Access Token TTL: default **30 days** → set ~1 h with an **Access Token
  Period** for renewal.
- Client Secret TTL: default **never expires** → set one, plus a low
  **max-number-of-uses**.
- **Trusted IPs** (paid feature): pin credentials to the VPS egress IP if
  the plan allows.

### The host-side broker

One `infisical agent` daemon **on the host** (never in agent containers),
run by systemd:

- Bootstrap credential supplied via `LoadCredentialEncrypted=` from a
  **systemd-creds**-encrypted blob (AES-256-GCM, machine-bound — a stolen
  disk image cannot decrypt it elsewhere; zero passphrases, survives
  unattended reboots).
- `remove_client_secret_on_read: true` — the client secret exists on disk
  for milliseconds at boot, then the daemon holds only a renewable token in
  memory. **The machine identity never enters any agent container.**
- Renders each project's secrets into a per-project **tmpfs** file, mounted
  read-only into that project's container as a *file* (`/run/secrets/…`),
  not env vars — env vars leak via `/proc/self/environ`, `docker inspect`,
  and crash dumps.

**Bootstrap delivery** (new project, laptop → VPS): create an Infisical
**share link** (1 view, 5-minute expiry), `curl` it once on the VPS, pipe
straight into `systemd-creds encrypt`. The secret never touches shell
history, chat logs, or a synced password manager.

## 7. Credential proxy (agent-vault)

For the highest-value credentials (GitHub, Anthropic), agents hold only
**placeholder strings**; [Infisical agent-vault](https://github.com/Infisical/agent-vault)
(single Go binary, MITM forward proxy) injects real values at the network
boundary. This is the only layer that defends against a *fully compromised*
agent exfiltrating a credential — there is nothing to exfiltrate.

- **Git-over-HTTPS: verified working** (2026-08-02, empirically, v0.39.x
  source build). Mechanism: a service rule `auth: {type: basic, username:
  GH_USER, password: GH_PAT}` — the proxy strips whatever auth the client
  sent and composes the whole `Authorization: Basic …` header from the
  vault. (Placeholder *substitution* would not work for git — the dummy is
  invisible inside base64 — so use the `basic` auth rule, not substitutions.)
  Git needs no credentials configured at all.
- Containers trust the proxy CA (`agent-vault ca` export; `GIT_SSL_CAINFO` /
  system trust store).
- `unmatched_host_policy=deny` doubles as the **egress allowlist** — the
  firewall-profile feature and the credential broker are one component.
- Backed by Infisical Cloud as its credential store; per-container
  vault-scoped session tokens minted at `dream new` / container start.
- Placement: its own container in the privileged zone's Docker network;
  `:14322` (proxy) reachable from the agent network, `:14321` (management)
  loopback-only. Its docs want a separate host — honoured when the second
  server arrives (§2).
- **Risk posture:** pre-1.0, four months old. Pin the version; treat as a
  hardening layer over a design that is already sound without it (§6 works
  alone). Compatible by construction with Infisical's commercial **Agent
  Proxy** — both are `HTTPS_PROXY`-style brokers, so switching is env-var
  config, not architecture.

## 8. The deployer

**One deployer per trust zone** (i.e., per box today), never per project —
per-project separation lives in its config, not in copies of it.

Agents never run Docker. The deploy path:

1. Agent pushes code (its repo-scoped credential — no new powers).
2. Webhook fires (per-project **HMAC secret**), or `dream deploy` posts to
   the deployer with the same auth.
3. The deployer — the only Docker-daemon client besides the owner — checks
   out the project, **policy-checks the compose file** (~40 lines: reject
   privileged, host network/PID/IPC, added capabilities, bind mounts outside
   the project dir, docker socket), layers on a resource-limit override file
   the project cannot opt out of, and runs
   `docker compose -p <project>-test up -d --build` in the project's slot.
4. Exposure only via shared **Caddy**: `<project>.test.<domain>` with basic
   auth; nothing binds host ports directly.

Deploy scripts and env templates live in the system repo (§5); the deployer
executes only its protected main at a pinned ref. Test-environment secrets
are injected by the deployer from the broker at deploy time — never from
agent-writable repos.

Building images on the deployer (not in agent containers) also keeps
BuildKit's memory spikes out of the agent RAM budget.

## 9. Team chat

- **Milestone 1: Mattermost** (self-hosted, shared-infra zone, ~300–500 MB;
  unlimited per-agent bot identities — DreamTeams' recommended transport).
- **Milestone 2: Buzz** (Block's Nostr-based human+agent chat, launched
  2026-07) as an experimental `teams-chat-buzz` transport plugin. Per-agent
  Nostr keypairs map 1:1 onto the per-container identity model.
- The DreamTeams `team-say`/`team-hear` dispatcher is the owned interface;
  transports are commodity plugins underneath. Switching a team is a `.env`
  change and restart, not a re-provision. **Own the interfaces, rent the
  implementations.**
- Live state (chat, wake signals, presence) lives on the bus; durable,
  reviewable state lives in git. Files stop being the only channel.

## 10. RAM ledger (16 GB VPS reference)

| Component | Idle | Notes |
|---|---|---|
| Agent container (active) | 0.5–1.5 GB | Claude Code's floor; capped at 3 GB |
| Agent container (idle) | ~0 (swapped) | zram/swapfile host-side |
| Postgres (one, shared) | 50–150 MB | one instance, schema per project |
| Mattermost | 300–500 MB | + its Postgres schema |
| agent-vault | tens of MB | single Go binary |
| Caddy | tens of MB | |
| Deployer (webhook svc) | tens of MB | build spikes are transient |
| infisical agent (host) | tens of MB | |

What v2 removed from v1's per-project bill: per-project Postgres + Redis +
API + frontend containers, Chrome + 2 GB shm in every image, docker-in-docker
daemons, `SYS_ADMIN`/`NET_ADMIN` capabilities.

## 11. Milestones

- **M1 — the runtime** *(this repo, now)*: base + browser images, compose
  template with default-on limits, `dream` CLI (`new` / `ls` / `shell` /
  `logs` / `rm` / `refresh`), auth volumes, canonical mounts, baked launch
  semantics, plugins.json, GHCR CI with weekly rebuild, docs.
- **M2 — the privileged zone**: deployer (webhook + policy check + Caddy),
  host broker unit files, agent-vault compose + service rules, Buzz
  transport experiment, coach-agent merge flow for the skills repo.
- **M3 — reach**: DreamKit as reference consumer (`--kit` stays out of the
  core; integration = a documented compose-network convention), GitHub App
  migration, second-server split runbook.

## 12. Decision log (terse)

| # | Decision | Why |
|---|---|---|
| 1 | Rewrite, don't patch v1 | v1's devcontainer bundled an app stack, browser, DinD — RAM-hostile and wrong trust model for a fleet |
| 2 | No docker socket / DinD in agents | socket = root; deployer pattern replaces it |
| 3 | One deployer per trust zone | privileged singleton; config scopes projects |
| 4 | Slim default image, `:browser` variant | Chrome + 2 GB shm only where genuinely needed |
| 5 | Compose-first, devcontainer.json as veneer | headless VPS is the primary citizen |
| 6 | Three shared repos = three write tiers | per-repo PATs enforce tiers on any GitHub plan |
| 7 | Coach agent merges skills; humans merge code guardrails | prose vs executable; small revertable blast radius |
| 8 | Infisical Cloud + host-side `infisical agent` broker | machine identity never enters agent containers |
| 9 | systemd-creds for at-rest bootstrap | machine-bound, zero-friction, unattended reboots |
| 10 | No Infisical MCP | hands values to agents; leaked in practice |
| 11 | agent-vault as hardening layer, pinned | only defense vs compromised-agent exfiltration; pre-1.0 |
| 12 | Git via agent-vault `basic` auth rule | verified empirically 2026-08-02; substitution can't see base64 |
| 13 | Secrets as ro tmpfs files, not env vars | `/proc/self/environ` lesson |
| 14 | Mattermost M1, Buzz M2 | working default first; transport is a plugin |
| 15 | Per-agent session logs + stitcher | kills prepend contention; git-mode conflict-free |
| 16 | Env var + `--add-dir` baked into image | docs-verified requirement; no bare-launch path |
