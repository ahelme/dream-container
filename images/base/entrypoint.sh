#!/usr/bin/env bash
# DreamContainer entrypoint: wire optional integrations, then run CMD.
# Everything here is best-effort and silent when unconfigured — the same
# image serves a bare solo container and a fully-wired team member.
set -euo pipefail

# --- Credential proxy CA trust (agent-vault / Infisical Agent Proxy) --------
# When the compose file mounts a proxy CA at /run/dream/proxy-ca.crt and sets
# HTTPS_PROXY, teach git/node/curl to trust the MITM cert.
if [[ -f /run/dream/proxy-ca.crt ]]; then
  export GIT_SSL_CAINFO=/run/dream/proxy-ca.crt
  export NODE_EXTRA_CA_CERTS=/run/dream/proxy-ca.crt
  export CURL_CA_BUNDLE=/run/dream/proxy-ca.crt
fi

# --- Broker-rendered secrets (host-side infisical agent) --------------------
# /run/secrets/project.env is a read-only tmpfs-backed file rendered by the
# host broker. Exported at shell start (not baked into container env) so
# `docker inspect` never sees values. See docs/ARCHITECTURE.md §6.
if [[ -f /run/secrets/project.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source /run/secrets/project.env
  set +a
fi

# --- Instructions install at provision time (ARCHITECTURE §4, option A) ------
# Pull the team's instruction tier (CLAUDE.md + skills) from a protected,
# read-only-to-agents repo at a pinned ref, and install it into Claude Code's
# STANDARD user-level load paths. No --add-dir, no env-var dependency, and
# the running container holds a snapshot — a mid-session merge (good or
# poisoned) never changes a live session; updates land at the next container
# start / `dream refresh`.
if [[ -n "${TEAM_INSTRUCTIONS_REPO:-}" ]]; then
  ref="${TEAM_INSTRUCTIONS_REF:-main}"
  src="/home/agent/.dream-instructions"
  clone_url="$TEAM_INSTRUCTIONS_REPO"
  # Read-only PAT auth for private GitHub instruction repos (never logged).
  if [[ -n "${GH_TOKEN:-}" && "$clone_url" == https://github.com/* ]]; then
    clone_url="https://x-access-token:${GH_TOKEN}@github.com/${clone_url#https://github.com/}"
  fi
  rm -rf "$src"
  if git clone --quiet --depth 1 --branch "$ref" "$clone_url" "$src" 2>/dev/null; then
    mkdir -p "$CLAUDE_CONFIG_DIR"
    [[ -f "$src/CLAUDE.md" ]] && cp "$src/CLAUDE.md" "$CLAUDE_CONFIG_DIR/CLAUDE.md"
    if [[ -d "$src/skills" ]]; then
      rm -rf "$CLAUDE_CONFIG_DIR/skills"
      cp -r "$src/skills" "$CLAUDE_CONFIG_DIR/skills"
    fi
    [[ -d "$src/hooks" ]] && { rm -rf "$CLAUDE_CONFIG_DIR/hooks"; cp -r "$src/hooks" "$CLAUDE_CONFIG_DIR/hooks"; }
    echo "dream: installed team instructions from ${TEAM_INSTRUCTIONS_REPO}@${ref}" >&2
  else
    echo "dream: WARNING — could not fetch team instructions (${TEAM_INSTRUCTIONS_REPO}@${ref}); running without" >&2
  fi
fi

# --- /team file access WITHOUT instruction loading (ARCHITECTURE §4/§5) ------
# The read-write teams surface is reachable for file ops but must NEVER load
# CLAUDE.md/skills as instructions (that's the read-only PR-gated tier's job).
# permissions.additionalDirectories grants access only — never config — which
# is exactly the guarantee we want here. Seed it if the operator hasn't set
# their own settings.json (their file, mounted from the system repo, wins).
SETTINGS="$CLAUDE_CONFIG_DIR/settings.json"
if [[ -d /team && -n "$(ls -A /team 2>/dev/null)" && ! -f "$SETTINGS" ]]; then
  mkdir -p "$CLAUDE_CONFIG_DIR"
  cat > "$SETTINGS" <<'JSON'
{
  "permissions": {
    "additionalDirectories": ["/team"]
  }
}
JSON
fi

# --- Git identity (from .env, optional) -------------------------------------
if [[ -n "${GIT_USER_NAME:-}" ]]; then
  git config --global user.name  "$GIT_USER_NAME"  || true
fi
if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
  git config --global user.email "$GIT_USER_EMAIL" || true
fi

exec "$@"
