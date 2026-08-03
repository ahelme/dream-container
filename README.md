<div align="center">
<img src="docs/static/img/dream_container_claude_cloud.png" alt="DreamContainer" width="400">
</div>

# 💭 DreamContainer

**A per-agent runtime for running many Claude Code agents on one VPS —
isolated, RAM-frugal, with persistent auth baked in.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> **v2 rewrite in progress.** This repo is being rebuilt from the ground up as
> a lean agent runtime. The old all-in-one devcontainer (app stack + browser +
> docker-in-docker in one image) lives in git history and in the sibling
> [dream-kit](https://github.com/ahelme/dream-kit) repo. See
> [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design and
> decision log.

---

## The problem it solves

Running a fleet of Claude Code agents on a single server, all under one Unix
user, means one compromised or prompt-injected agent can read every other
project's credentials and trample every other project's files. DreamContainer
gives each agent its **own container**: its own workspace, its own persistent
auth, its own tightly-scoped credentials, memory limits so one runaway agent
can't starve the others, and no path to the Docker daemon. Blast radius
shrinks from "the whole VPS" to "one project."

Two pain points from the old world, handled:

- **Persistent auth.** Claude Code config (`~/.claude`) and `gh` config live in
  named volumes — they survive rebuilds. No re-login after every image update.
  Token-first is the recommended path (a fine-grained PAT scoped to just this
  project's repos), with the login flow as fallback.
- **RAM.** Claude Code's Node process is the floor (~0.5–1.5 GB active); the
  runtime keeps everything *around* it lean — a slim default image (no browser
  unless you ask), one shared Postgres instead of one-per-project, memory
  limits on by default, and idle agents that swap out for almost nothing.

## What's here (milestone 1)

```
dream-container/
├── bin/dream                      ← the CLI: new / up / shell / claude / ls / refresh / rm
├── images/
│   ├── base/                      ← slim default image (Claude Code, gh, git, tmux…)
│   └── browser/                   ← opt-in Chromium + Playwright variant
├── templates/
│   ├── docker-compose.project.yml ← one agent container, limits on by default
│   └── project.env.example        ← every knob, sane defaults
├── docker-bake.hcl                ← multi-arch (amd64 + arm64) build
├── .github/workflows/             ← weekly GHCR image builds
└── docs/ARCHITECTURE.md           ← the design, trust model, decision log
```

## Quick start

```bash
# 0. one-time: put dream on your PATH
ln -s "$PWD/bin/dream" ~/.local/bin/dream
dream doctor                       # check host prerequisites

# 1. provision an agent for a project
dream new my-api --repo https://github.com/you/my-api.git
#   → edit ~/dream/my-api/.env and set GH_TOKEN (scoped to this project)

# 2. start it and hop in
dream up my-api
dream shell my-api
> claude                           # team-wired, persistent auth, ready

# browser automation project? add --browser (Chromium + 1g shm)
dream new my-scraper --repo … --browser
```

`dream ls` shows every agent and its state; `dream refresh <project>` pulls the
latest image and recreates the container **without touching your auth or
workspace volumes**; `dream rm <project>` stops it (add `--purge` to delete
volumes too).

## How it fits together

DreamContainer is the bottom layer of a three-layer system:

- **[DreamTeams](https://github.com/ahelme/dream-teams)** — the collaboration
  layer: skills, identities, rituals, team chat, and a coach agent, riding on
  git + a chat bus. A DreamContainer mounts the team repos at canonical paths
  (`/team`, `/team-system`) and the baked-in launch wrapper wires them into
  every `claude` session automatically — no aliases, no zshrc surgery.
- **DreamContainer** *(this repo)* — the isolated per-agent runtime.
- **Shared-infra zone** — one deployer (agents request deploys, never run
  Docker), a credential proxy, one Postgres, Mattermost, Caddy. Milestone 2.

Full detail, trust model, and the secrets design (Infisical Cloud + a
host-side broker so machine-identity credentials never enter an agent
container) are in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Status

Milestone 1 (the runtime) is landing now: images, compose template, the
`dream` CLI, multi-arch CI. Milestones 2 (deployer, credential proxy, coach
merge flow) and 3 (DreamKit reference consumer, GitHub App auth, second-server
split) are specced in the architecture doc.

## License

MIT — see [LICENSE](LICENSE).
