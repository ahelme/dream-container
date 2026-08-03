#!/usr/bin/env bash
# Launch wrapper: bare `claude` always gets the team wiring.
# Shadows the real binary (installed under /opt/npm-global) via PATH order.
# The container IS the launch alias — no bare-launch path exists.
set -euo pipefail

REAL="/opt/npm-global/bin/claude"

ADD_DIRS=()
# Only wire directories that are actually mounted and non-empty, so the same
# image works for solo projects (no team) and team projects alike.
[[ -d /team && -n "$(ls -A /team 2>/dev/null)" ]] && ADD_DIRS+=(--add-dir /team)
[[ -d /team-system && -n "$(ls -A /team-system 2>/dev/null)" ]] && ADD_DIRS+=(--add-dir /team-system)

exec "$REAL" "${ADD_DIRS[@]}" "$@"
