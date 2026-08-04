# 💭 DreamContainer base — the per-agent runtime
#
# Slim by design: Claude Code + git tooling and nothing else. No browser,
# no browser libs, no docker, no BuildKit — see docs/ARCHITECTURE.md §4.
# Browser automation lives in images/browser (opt-in per project).
#
# Multi-arch: linux/amd64 + linux/arm64 (see .github/workflows/build-images.yml)

FROM node:22-bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

# Core tooling. --no-install-recommends keeps the RAM/disk budget honest.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      gnupg \
      jq \
      less \
      openssh-client \
      procps \
      ripgrep \
      fzf \
      tmux \
      unzip \
      zsh \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (kept as the fallback auth path — primary is GH_TOKEN / broker)
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Infisical CLI (small Go binary; the in-container secrets front door)
RUN curl -1sLf 'https://artifacts-cli.infisical.com/setup.deb.sh' | bash \
    && apt-get update && apt-get install -y --no-install-recommends infisical \
    && rm -rf /var/lib/apt/lists/*

# Non-root agent user. uid 1000 matches the default first user on most hosts,
# which keeps bind-mount ownership sane.
RUN userdel -r node 2>/dev/null || true \
    && useradd -m -u 1000 -s /usr/bin/zsh agent

# Claude Code — global install into a prefix that is NOT /usr/local, so the
# /usr/local/bin/claude launch wrapper below shadows the real binary and
# bare `claude` always gets the team wiring. No bare-launch path exists.
ENV NPM_CONFIG_PREFIX=/opt/npm-global
RUN mkdir -p /opt/npm-global \
    && npm install -g @anthropic-ai/claude-code@latest \
    && chown -R agent:agent /opt/npm-global

# Launch semantics, baked in (docs/ARCHITECTURE.md §4):
# - CLAUDE.md loading from --add-dir requires this env var (verified against
#   current Claude Code docs; permissions.additionalDirectories grants file
#   access only and never loads config)
# - the wrapper always passes the team mounts when they exist
ENV CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 \
    CLAUDE_CONFIG_DIR=/home/agent/.claude \
    PATH=$PATH:/opt/npm-global/bin
COPY claude-wrapper.sh /usr/local/bin/claude
COPY entrypoint.sh /usr/local/bin/dream-entrypoint
# System-wide git hooks path: chains any per-repo hook, then auto-restitches
# the team session log after commits touching session-logs/** (zero per-clone
# setup; repos setting their own core.hooksPath are unaffected).
COPY git-hooks/ /etc/dream/git-hooks/
RUN git config --system core.hooksPath /etc/dream/git-hooks \
    && chmod -R 755 /etc/dream/git-hooks \
    && chmod 755 /usr/local/bin/claude /usr/local/bin/dream-entrypoint \
    && mkdir -p /workspace /team /team-system /run/secrets \
    && chown agent:agent /workspace /team /team-system \
    && mkdir -p /home/agent/.claude /home/agent/.config/gh \
    && chown -R agent:agent /home/agent

USER agent
WORKDIR /workspace

# Persisted across rebuilds via named volumes (compose template):
#   /home/agent/.claude      Claude Code auth + config  ← persistent auth
#   /home/agent/.config/gh   gh auth fallback path
#   /workspace               project clone
VOLUME ["/home/agent/.claude", "/workspace"]

ENTRYPOINT ["/usr/local/bin/dream-entrypoint"]
CMD ["sleep", "infinity"]
