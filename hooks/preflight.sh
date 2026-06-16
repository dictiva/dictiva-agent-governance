#!/usr/bin/env bash
# dictiva-agent-governance :: preflight.sh (Claude Code SessionStart hook)
#
# Silent on a clean state. When the workspace is "owed" something, it emits a
# short punch list as additionalContext so the agent (and you) start the session
# aware of it. Exits 0 unconditionally — it never blocks a session.
# Harmless on non-Claude harnesses (just an unused script).

set +e
owed=()

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
[ -z "$default_branch" ] && default_branch="main"

dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
[ "${dirty:-0}" -gt 0 ] && owed+=("$dirty uncommitted file(s)")
[ -n "$branch" ] && [ "$branch" != "$default_branch" ] && owed+=("on branch '$branch' (default is '$default_branch')")

if [ "${#owed[@]}" -eq 0 ]; then
  exit 0
fi

msg="dictiva-agent-governance preflight — owed: "
for i in "${owed[@]}"; do msg="$msg- $i  "; done

if command -v python3 >/dev/null 2>&1; then
  python3 - "$msg" <<'PY'
import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}}))
PY
else
  printf '%s\n' "$msg" >&2
fi
exit 0
