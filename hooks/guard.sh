#!/usr/bin/env bash
# dictiva-agent-governance :: guard.sh
#
# A Claude Code PreToolUse deny-hook for the Bash tool. It blocks the shell
# commands your charter says an agent "may not" run — regardless of skill,
# instruction, or context drift. Friction is the feature.
#
# Deny patterns are loaded from guard-patterns.json (next to this script, or
# $DICTIVA_AGENT_GOVERNANCE_PATTERNS), which forge.md generates FROM your AGENTS.md
# charter so the written rule and the physical block share one source.
#
# FAIL CLOSED: a deny-hook that cannot parse its input must not allow blindly.
# If no parser is available, it denies and tells you why.
#
# Scope honesty: this hook fires ONLY inside Claude Code (the one harness that
# loads PreToolUse hooks today). On other harnesses use the git pre-push /
# pre-commit hooks for the cross-harness hard tier. See README.md.
#
# Contract: read JSON on stdin, emit a permissionDecision envelope on deny,
# exit 0 always (never block the harness on an internal error).

set +e
INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_FILE="${DICTIVA_AGENT_GOVERNANCE_PATTERNS:-$SCRIPT_DIR/guard-patterns.json}"

if ! command -v python3 >/dev/null 2>&1; then
  # No parser -> fail closed.
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"dictiva-agent-governance guard.sh cannot parse tool input (python3 not found) — failing closed. Install python3, or run the command yourself in a terminal."}}'
  exit 0
fi

OUT=$(CF_PATTERNS_FILE="$PATTERNS_FILE" python3 - "$INPUT" <<'PY'
import json, os, re, sys

try:
    data = json.loads(sys.argv[1])
except Exception:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "dictiva-agent-governance: unparseable tool input — failing closed."}}, separators=(",", ":")))
    sys.exit(0)

# Only guard the Bash tool; everything else is allowed to pass through.
if data.get("tool_name") != "Bash":
    print("ALLOW"); sys.exit(0)

cmd = ((data.get("tool_input") or {}).get("command") or "")

# Baseline protections, used if the patterns file is missing or unreadable.
# A bad/absent patterns file must NEVER silently disable protection.
baseline = [
    {"id": "force-push",  "match": r"git\s+push\b.*(--force\b|-f\b|--force-with-lease|\s\+)", "reason": "force-push is blocked by charter"},
    {"id": "reset-hard",  "match": r"git\s+reset\b.*--hard",                                   "reason": "reset --hard is blocked by charter"},
    {"id": "push-default","match": r"git\s+push\b.*\b(main|master)\b",                          "reason": "direct push to the default branch is blocked by charter"},
]
patterns = baseline
pf = os.environ.get("CF_PATTERNS_FILE", "")
try:
    if pf and os.path.exists(pf):
        loaded = (json.load(open(pf)) or {}).get("deny", [])
        if loaded:
            patterns = loaded
except Exception:
    patterns = baseline

for p in patterns:
    try:
        if re.search(p.get("match", ""), cmd):
            print(json.dumps({"hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": p.get("reason", "blocked by charter")}}, separators=(",", ":")))
            sys.exit(0)
    except re.error:
        continue

print("ALLOW")
PY
)

# Pass a deny envelope through; stay silent (allow) otherwise.
case "$OUT" in
  \{*) printf '%s\n' "$OUT" ;;
esac
exit 0
