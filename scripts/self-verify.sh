#!/usr/bin/env bash
# charter-forge :: self-verify.sh
#
# Proves the enforcement actually fires — WITHOUT Claude Code, without a network,
# without an API key. Runs in any shell. Feeds sample commands to guard.sh and
# asserts the deny/allow decision, then runs the audit lint. This is the
# "watch it block" proof you can run on day one and in CI.
#
# Exit 0 = every assertion held. Exit 1 = a guard decision was wrong.

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/hooks/guard.sh"
export CHARTER_FORGE_PATTERNS="$ROOT/hooks/guard-patterns.example.json"
fails=0

bash_json() { # $1 = command string -> a Claude Code PreToolUse Bash payload
  python3 - "$1" <<'PY'
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))
PY
}

assert() { # $1 expect(deny|allow)  $2 command
  local expect="$1" cmd="$2" out decision
  out="$(bash_json "$cmd" | bash "$GUARD")"
  if printf '%s' "$out" | grep -Eq '"permissionDecision":[[:space:]]*"deny"'; then decision="deny"; else decision="allow"; fi
  if [ "$decision" = "$expect" ]; then
    printf '  ok    [%-5s] %s\n' "$decision" "$cmd"
  else
    printf '  FAIL  expected %s, got %s: %s\n' "$expect" "$decision" "$cmd"
    fails=$((fails+1))
  fi
}

echo "charter-forge self-verify — guard.sh decisions:"
assert deny  "git push --force origin main"
assert deny  "git push -f origin feature/x"
assert deny  "git reset --hard HEAD~3"
assert deny  "git push origin main"
assert allow "git push origin feature/my-change"
assert allow "git status"
assert allow "ls -la && echo hello"

echo
echo "charter-forge self-verify — audit lint:"
if command -v node >/dev/null 2>&1; then
  node "$ROOT/scripts/lint-attests.mjs" | sed 's/^/  /'
else
  echo "  (node not found — skipping lint; install Node 18+ to run it)"
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "PASS — enforcement fires as specified. Friction is the feature."
  exit 0
else
  echo "FAIL — $fails guard decision(s) wrong."
  exit 1
fi
