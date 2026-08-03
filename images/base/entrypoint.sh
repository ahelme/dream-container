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
