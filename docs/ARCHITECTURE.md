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
   must be lean. Honest sizing (review finding #11): **4 GB ≈ 2 active
   agents with chat off-box** (or a single active agent alongside a
   local Mattermost + Postgres), leaning on swap for idle sessions;
   "many agents" is genuinely 8–16 GB. The default `mem_limit: 3g` is a
   *ceiling* per container, not a reservation — real steady-state is far
   lower and idle agents swap out — but do not read 3g × N as the required
   RAM; size limits per tier and expect swap to carry idle load.
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
- **`HTTPS_PROXY` is advisory — a compromised agent can ignore it.** The
  egress allowlist and the "nothing to exfiltrate" property (§7) therefore
  hold *only* when direct outbound is blocked at the network layer. The
  agent Docker network MUST be `internal: true` (plus a DNS/forward-proxy
  sidecar for the traffic that is allowed) or firewalled at the host so the
  credential proxy, deployer, and chat are the *only* reachable
  destinations. This is a hard requirement of the security model, not an
  optimization. (Enforced from milestone 2, when those sidecars exist; until
  then a host nftables/ufw rule on the agent subnet is the interim control.)

  **How the firewall is actually implemented**, in order of strength:

  1. **`internal: true` on the agent network** (M2 target). Docker attaches
     no NAT/masquerade to an internal bridge — agent containers simply have
     no route out. Cross-zone services (credential proxy, deployer webhook,
     Mattermost, and a DNS/forward-proxy for any allowed plain fetches) are
     **dual-homed**: attached to both the internal agent network and an
     egress-capable network. They become the only doors, by topology rather
     than by rule.
  2. **Host `DOCKER-USER` chain rules** (interim, M1). Docker's own iptables
     rules bypass ufw's INPUT chain, so ordinary `ufw deny` does **not**
     govern container egress — rules must go in the `DOCKER-USER` chain
     (or its nftables equivalent), which Docker guarantees to consult:
     drop traffic *from* the `dream-agents` subnet except to the proxy's
     address and the explicit allowlist (GitHub, Anthropic). A ~20-line
     idempotent script owns this chain; it ships with the M2 deployer kit.
  3. What does **not** work: `HTTPS_PROXY` alone (advisory), ufw alone
     (bypassed by Docker's NAT), or per-container `cap_drop` (limits
     privilege, not routing).

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
**rebuilt weekly**. All state lives in volumes, so rebuilds are painless —
that *is* the persistent-auth story. But note (review finding #15): a weekly
*rebuild* only patches a *running* agent when its container is recreated —
**patches land at the next `dream refresh`**, not automatically. Pull auth
for GHCR is its own gotcha: fine-grained PATs and App installation tokens are
both rejected by GHCR; either publish the images **public** (simplest, and
they carry no secrets) or give the host a classic PAT with `read:packages`.

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

Two delivery mechanisms for the team's instruction tier, both baked into the
image; **B is the recommended default**:

**Option B — provision-time install (recommended).** Set
`TEAM_INSTRUCTIONS_REPO` (+ optional pinned `TEAM_INSTRUCTIONS_REF`) and the
entrypoint clones that repo at container start and installs its `CLAUDE.md`,
`skills/`, and `hooks/` into Claude Code's **standard user-level load paths**
(`~/.claude/CLAUDE.md`, `~/.claude/skills/`, `~/.claude/hooks/`). Properties:

- **No `--add-dir`, no env-var machinery** — bare `claude` just works via
  paths Claude Code always loads. The env-var ambiguity (settings-json `env`
  timing) disappears entirely.
- **Snapshot-at-start**: a running session's instructions are immutable — a
  freshly merged change (legitimate *or* poisoned) affects no live session;
  it lands at the next container start / `dream refresh`. This adds a natural
  containment window on top of the coach's merge delay.
- The instructions repo is the protected tier: **agents hold a read-only
  PAT** for it; skill changes arrive as coach-merged PRs, code (hooks)
  changes as human-merged PRs — one repo can carry both, or split
  skills/system as in §5.
- The agent *can* edit its own installed copy in `~/.claude` — that's the
  sanctioned "improve your own skill mid-session" loop (§5), scoped to
  itself, and reset to the reviewed state on next provision.

**Option A — live mounts (`--add-dir`).** The launch wrapper also passes
`--add-dir` for the read-only mounted tiers (`/team-system`, `/team-skills`)
when present, with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` exported
by the image (docs-verified: both are required for CLAUDE.md loading from
added dirs). Use when you want live-reload of skills without restarts.
**There is no bare-launch path** either way. The container *is* the launch
alias.

> **⚠️ Never `--add-dir /team` (review finding #2).** `--add-dir` loads
> `CLAUDE.md`, skills, and rules *as instructions*. The teams repo is
> read-write for every agent, so if it were `--add-dir`'d a compromised
> agent could write `/team/CLAUDE.md` and inject every teammate — including
> the coach — bypassing the whole skills-review gate. Instead, the
> collaboration surface gets **file access only** via
> `permissions.additionalDirectories: ["/team"]` in settings.json (which the
> earlier docs check confirmed grants access but *never* loads config). The
> entrypoint seeds exactly this when no operator settings.json is present.
> Instructions come only from the read-only tiers an agent cannot publish to
> unreviewed.

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
  - ⚠️ **The coach is itself an injection target** (review finding #7): it
    reads untrusted PR content while holding a merge-capable credential, and
    "reviews as data" is an aspiration with no hard enforcement. Two
    mitigations make the residual risk small: (a) put the coach's merge
    credential behind agent-vault so it's abuse-scoped and audited, and
    (b) a **human-visible merge delay** — the coach *approves*, the merge is
    announced to team chat and takes effect after N hours unless a human
    vetoes. Revert undoes the file, but not actions agents took while a
    poisoned skill was live, so the delay (not just revertability) is what
    actually contains a fooled coach.
- **Skills are prose; hooks/tools/settings are code.** Code executes with
  the agent's (or deployer's) privileges, so the executable tier stays
  human-merge-only.
- The **deployer executes only from the system repo's main** at a pinned
  ref — a rogue scripts-team agent can propose a malicious deploy script but
  never get it executed without a human merge in between.
- **Write path to a read-only tier** (review finding #13): `/team-system`
  and `/team-skills` are mounted read-only precisely so an agent can't edit
  them in place. Scripts-team / skill authors therefore work on a **separate
  clone in `/workspace`** using a distinct write-scoped PAT, push a branch,
  and open a PR — the read-only mount is for *loading* the current guardrails
  as instructions, never for editing them.
- **Attribution is evidence, not authentication** (review finding #14): git
  author/committer fields are self-declared, and on a single GitHub account
  (lowest paid tier) every agent's PAT authenticates as the same user — so
  teams-repo history localizes *what* changed and is one-command revertable,
  but must not be trusted to prove *which agent* did it. For real per-agent
  authentication, give agents distinct machine accounts or commit-signing
  keys (a later enhancement; Buzz's per-agent Nostr identities, §9, point the
  same way).
- Merge-friendly conventions in the teams repo: per-agent/per-team files,
  append-oriented logs, `git pull --rebase` folded into the resume-context /
  handover rituals, and a `CONVENTIONS.md` stating the two rules: *you own
  files bearing your name; shared files are append-only or generated.*
  (Session logs: per-agent files + generated combined view — see the
  dream-teams `team-log` PR.)
- **`team-log` activation** is layered, manual-first: (1) the
  `update-session-log` / `new-identity` skills run it explicitly after
  writing (works today, filesystem or git mode); (2) *zero-setup local
  automation* — the DreamContainer image sets
  `git config --global core.hooksPath /etc/dream/git-hooks` with a
  post-commit hook that runs `team-log` whenever `session-logs/**` changed,
  so no per-clone hook install is ever needed; (3) *git-mode end state* — a
  tiny GitHub Action on the teams repo, triggered by pushes touching
  `session-logs/**`, regenerates and commits `all-teams-session-log.md`
  centrally. (3) is the cleanest: the stitched view becomes a CI-built
  artifact **no agent ever writes**, so it can't conflict and can't lie
  about its sources. (Server-side git hooks aren't available on github.com —
  the Action is the server-side hook.)
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
  **systemd-creds**-encrypted blob (AES-256-GCM; zero passphrases, survives
  unattended reboots). **Disk-theft resistance depends on a TPM** (review
  finding #3): with `--with-key=tpm2`/`host+tpm2` the blob is bound to
  hardware and a stolen disk image cannot decrypt it; *without* a (v)TPM the
  host key lives at `/var/lib/systemd/credential.secret` on the same disk,
  so it protects against file-level leaks but **not** a full disk-image
  theft. Run `systemd-creds has-tpm2` first; many budget VPSes have none.
- The daemon holds only a renewable token in memory after first auth; **the
  machine identity never enters any agent container.** (Note: under
  `LoadCredentialEncrypted=` the decrypted secret is a read-only ramfs file
  that never touches disk, so `remove_client_secret_on_read` is redundant
  there — see finding #10; use it only if the secret is delivered by some
  other path the agent can actually unlink.)
- Renders each project's secrets into a per-project **tmpfs** file, mounted
  read-only into that project's container as a *file* (`/run/secrets/…`),
  not env vars — env vars leak via `/proc/self/environ`, `docker inspect`,
  and crash dumps.

**Bootstrap delivery** (new project, laptop → VPS): get the machine-identity
client secret onto the VPS once, without it landing in shell history, chat,
or a synced password manager. ⚠️ **Not via `curl` of a share link**
(finding #9): Infisical share links serve the web app and decrypt
client-side (key material rides in the URL fragment, never reaching the
server), so `curl` returns HTML, not the secret — and would burn the single
view. Two paths that actually work: (a) paste over an SSH session straight
into `systemd-creds encrypt --name=… - /path/to.cred` reading stdin; or
(b) fetch via the authenticated Infisical CLI/API on the VPS. The share link
remains fine for *human* eyes-on delivery, just not for piping.

## 7. Credential proxy (agent-vault)

For the highest-value credentials (GitHub, Anthropic), agents hold only
**placeholder strings**; [Infisical agent-vault](https://github.com/Infisical/agent-vault)
(single Go binary, MITM forward proxy) injects real values at the network
boundary. It **prevents credential *exfiltration*, not credential *abuse***
(review finding #5): a compromised agent still can't steal the token to use
off-box, but it *can* wield it through the proxy for as long as it holds a
session — push poisoned commits, delete branches, burn Anthropic quota. So
this pairs with tight PAT scopes, proxy-side audit logs, and rate limits; it
is one defense, not the whole story. It also depends absolutely on the L3
egress block (§2) — without it, placeholders don't matter because the agent
just connects out directly.

- **Git-over-HTTPS: verified working** (2026-08-02, empirically, v0.39.x
  source build). Mechanism: a service rule `auth: {type: basic, username:
  GH_USER, password: GH_PAT}` — the proxy strips whatever auth the client
  sent and composes the whole `Authorization: Basic …` header from the
  vault. (Placeholder *substitution* would not work for git — the dummy is
  invisible inside base64 — so use the `basic` auth rule, not substitutions.)
  Git needs no credentials configured at all.
- **Per-agent credential mapping: verified working** (2026-08-03,
  empirically — closes review finding #4). The unit of credential scoping is
  the **vault**: service rules and credentials are per-vault, and session
  tokens are vault-scoped. So the pattern is **one vault per agent** (or per
  project): each vault carries its own `GH_PAT` credential and its own
  service rule for the same upstream host. Test: two vaults, two session
  tokens, identical `git ls-remote` against the same host through one
  agent-vault instance → the upstream received *different* credentials per
  token. `dream new` therefore provisions a vault + session token per agent,
  and the §5 per-agent write tiers survive transit through the proxy intact.
  (This is agent-vault's own vault config — the optional Infisical backing
  store syncs the credential *values*; the per-vault mapping lives in
  agent-vault either way.)
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
- **Anthropic auth is the exception to "placeholders only"** (review
  finding #6): the persistent `~/.claude` volume that gives us rebuild-proof
  auth also means Claude Code's OAuth/session tokens live *inside* the
  semi-trusted container, where the L3 egress block (§2) is what stops them
  leaving — the proxy can't broker what's already resident. If that residual
  risk matters for a given agent, use **API-key auth injected by the vault**
  instead of the persistent OAuth volume (no in-container token, at the cost
  of the convenient login flow). Pick per agent; don't pretend the OAuth
  volume is placeholder-only.
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
   out the project, **policy-checks the compose file with an *allowlist*
   schema** (review finding #8: a blocklist is bypassable — e.g. a named
   volume with `driver_opts: {type: none, o: bind, device: /var/run/…}` is a
   host bind mount that a "no privileged / no host bind" blocklist misses;
   `devices:`, `sysctls`, `extends`, build-context escapes are similar gaps).
   Only a known-safe set of compose keys is permitted; anything unrecognized
   is rejected. The deployer then layers on a resource-limit override file
   the project cannot opt out of and runs
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

## 11. Operations (review finding #12)

The privileged zone has single points of failure that need an explicit story,
not silence:

- **Broker (`infisical agent`) and credential proxy are SPOFs.** When the
  proxy is down, all agent git/API traffic stops; when the broker dies, the
  tmpfs-rendered secrets vanish on restart. Both run under **systemd with
  `Restart=on-failure`** (broker) / a **compose `restart: unless-stopped`
  + healthcheck** (proxy), and agents fail *closed* (no traffic) rather than
  open. Secrets re-render on broker restart, so an agent that started mid-
  outage picks them up on its next container start or a re-run of the render.
- **Healthchecks** on broker, proxy, deployer, Postgres, Mattermost — a dead
  dependency should surface, not silently degrade.
- **Backups**, with a concrete target list: the `claude-config` and
  `workspace` volumes per project, the shared Postgres, Mattermost's data,
  agent-vault's SQLite/Postgres store, and the host's `systemd-creds`
  material + `/etc/dreamcontainer` config. (The `backup-check` skill in
  DreamTeams already models "verify real backups vs live data.")
- **Log rotation** for the proxy's request log and per-project agent logs
  (`docker` json-file driver with `max-size`/`max-file`, set in the compose
  template's `logging:` block — a good M2 addition).
- **Patching reaches containers only on recreate.** The weekly GHCR rebuild
  is inert until `dream refresh <project>` pulls and recreates — schedule a
  refresh cadence (a host cron running `dream refresh` across projects) so
  "rebuilt weekly" actually means "patched weekly."
- **Monitoring/alerting**: the DreamTeams ops skills (`health-check`,
  `monitoring-check`, Grafana/Loki/Prometheus) are the intended surface; wire
  the broker/proxy/deployer health into them in M2.

## 12. Milestones

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

## 13. Decision log (terse)

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
| 17 | `--add-dir` ONLY read-only tiers; `/team` = additionalDirectories | file-access-only mount can't inject instructions (finding #2) |
| 18 | Agent network `internal: true` + egress firewall | HTTPS_PROXY is advisory; L3 block is what makes §7 true (finding #1) |
| 19 | Instructions installed at provision from protected repo (option B, default) | standard `~/.claude` load paths; no env-var machinery; snapshot-at-start containment |
| 20 | `DOCKER-USER` chain for interim egress rules | ufw is bypassed by Docker's NAT; DOCKER-USER is the chain Docker honours |
| 21 | Stitched session log becomes a CI artifact in git mode | no agent ever writes the combined view; hooks path baked in image for local mode |
| 22 | One agent-vault vault per agent | vault-scoped tokens select per-vault creds for the same host — verified 2026-08-03; closes finding #4 |

## 14. Adversarial review ledger (2026-08-02)

A Fable agent reviewed this doc adversarially. Verdict: sound design, but the
security story rested on unstated assumptions. Status of each finding:

| # | Sev | Finding | Status |
|---|---|---|---|
| 1 | HIGH | `HTTPS_PROXY` advisory → agent bypasses egress/exfil controls | **Fixed**: §2 hard requirement + compose `internal:true` note + interim host firewall |
| 2 | HIGH | `/team` rw + `--add-dir` = review-bypassing injection channel | **Fixed in code + doc**: wrapper `--add-dir`s read-only tiers only; `/team` via `additionalDirectories` (file access only); entrypoint seeds it |
| 3 | HIGH | systemd-creds "machine-bound" only with TPM | **Fixed**: §6 caveat + `has-tpm2` check |
| 4 | HIGH | agent-vault host-rule → one PAT for all agents, collapses tiers | **Resolved by test 2026-08-03**: one vault per agent; vault-scoped session tokens select per-vault credentials for the same host (verified with two vaults / two tokens / one instance) |
| 5 | HIGH | "nothing to exfiltrate" defends theft not abuse | **Fixed**: §7 reworded (exfiltration ≠ abuse) + scopes/logs/rate-limits |
| 6 | MED | persistent `~/.claude` = Anthropic tokens in-container | **Fixed**: §7 honest note + API-key-via-vault option |
| 7 | MED | coach reads untrusted input while holding merge cred | **Fixed**: §5 vault-scoped cred + human-visible merge delay |
| 8 | MED | compose blocklist bypassable | **Fixed**: §8 switched to allowlist schema |
| 9 | MED | share-link `curl` bootstrap won't work | **Fixed**: §6 replaced with SSH-stdin / authenticated CLI |
| 10 | MED | `remove_client_secret_on_read` clashes with ramfs | **Fixed**: §6 note (redundant under `LoadCredentialEncrypted=`) |
| 11 | MED | 4 GB RAM claim doesn't add up | **Fixed**: §1 honest sizing (4 GB ≈ 2 agents, chat off-box) |
| 12 | MED | no ops story (SPOF, backup, rotation, patch delivery) | **Fixed**: new §11 Operations |
| 13 | MED | `/team-system` ro but §5 says scripts-team writes it | **Fixed**: §5 explicit separate-clone write path |
| 14 | LOW | git attribution forgeable; one account = one identity | **Fixed**: §5 "evidence not authentication" note |
| 15 | LOW | GHCR rejects fine-grained PATs; "weekly patch" overclaim | **Fixed**: §4 public-image / classic-PAT + "patched at refresh" |

All 15 findings are now addressed; finding #4 — the last open blocker — was
resolved empirically on 2026-08-03 (per-vault credential selection through
one agent-vault instance, distinct credentials per session token verified
against a mock upstream). M2 may lean on the proxy for per-agent write-tier
enforcement, using one vault per agent.
