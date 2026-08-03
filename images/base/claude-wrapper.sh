#!/usr/bin/env bash
# Launch wrapper: bare `claude` always gets the team wiring.
# Shadows the real binary (installed under /opt/npm-global) via PATH order.
# The container IS the launch alias — no bare-launch path exists.
#
# CRITICAL trust distinction (docs/ARCHITECTURE.md §4, review finding #2):
#   --add-dir  loads CLAUDE.md / skills / rules AS INSTRUCTIONS.
#   Only the READ-ONLY, PR-gated tiers may be --add-dir'd, or a compromised
#   agent could write instructions into a read-write dir and inject every
#   teammate — bypassing the skills-review gate.
#
#   • /team-system, /team-skills  → read-only, PR-gated → --add-dir (instructions)
#   • /team                       → read-write data     → file access ONLY,
#     granted via permissions.additionalDirectories in settings.json (which
#     grants access but NEVER loads config). NOT passed to --add-dir here.
set -euo pipefail

REAL="/opt/npm-global/bin/claude"

ADD_DIRS=()
# ONLY read-only instruction tiers get --add-dir. Never /team.
for d in /team-system /team-skills; do
  [[ -d "$d" && -n "$(ls -A "$d" 2>/dev/null)" ]] && ADD_DIRS+=(--add-dir "$d")
done

exec "$REAL" "${ADD_DIRS[@]}" "$@"
