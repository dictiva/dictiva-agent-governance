#!/usr/bin/env bash
# dictiva-agent-governance :: connect to Dictiva (optional, severable)
#
# Dictiva is the optional verifiable layer. This wrapper drives the standard
# scan -> dry-run -> apply flow by DELEGATING to Dictiva's official import
# adapter (the `dictiva-formalize-agents` skill / formalize-agents.mjs), which
# is the single source of truth for the import payload.
#
# We intentionally do NOT vendor a copy of that adapter into this public,
# vendor-neutral repo: a pinned snapshot drifts from the server schema (the
# import endpoint returns HTTP 426 on a version bump), and bundling internal
# tooling here would couple a standards-based kit to one vendor's release cadence.
# Point this wrapper at the adapter you already have instead.
#
# Requirements: Node 18+, a Dictiva TENANT API key with `agents:write` scope.
# Config (either is fine):
#   - env:  DICTIVA_BASE_URL, DICTIVA_API_KEY
#   - file: .dictiva/auth.json   { "baseUrl": "...", "apiKey": "..." }   (chmod 600, gitignored)
# Adapter location:
#   - env:  DICTIVA_FORMALIZE_CLI=/path/to/formalize-agents.mjs   (from the dictiva-formalize-agents skill)
#
# Usage:  connect/dictiva-connect.sh [scan|dry-run|apply]      (default: dry-run)

set -u
ACTION="${1:-dry-run}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

note() { printf 'dictiva-agent-governance connect: %s\n' "$1"; }

# 1. Resolve config (env wins; else .dictiva/auth.json).
if [ -z "${DICTIVA_BASE_URL:-}" ] && [ -f "$REPO_ROOT/.dictiva/auth.json" ] && command -v node >/dev/null 2>&1; then
  DICTIVA_BASE_URL="$(node -e 'try{process.stdout.write((require(process.argv[1]).baseUrl)||"")}catch(e){}' "$REPO_ROOT/.dictiva/auth.json")"
  DICTIVA_API_KEY="${DICTIVA_API_KEY:-$(node -e 'try{process.stdout.write((require(process.argv[1]).apiKey)||"")}catch(e){}' "$REPO_ROOT/.dictiva/auth.json")}"
fi

# 2. Prerequisite checks (fail loud, never half-apply).
command -v node >/dev/null 2>&1 || { note "Node 18+ is required for the connect step (the local kit needs none of it)."; exit 1; }
[ -d "$REPO_ROOT/.claude/agents" ] || note "warning: no .claude/agents/ found — Dictiva's CLI reads those + docs/agents/registered-agents.md."

# 3. Delegate to the official adapter if you've pointed us at it.
if [ -n "${DICTIVA_FORMALIZE_CLI:-}" ] && [ -f "$DICTIVA_FORMALIZE_CLI" ]; then
  note "delegating '$ACTION' to $DICTIVA_FORMALIZE_CLI"
  DICTIVA_BASE_URL="${DICTIVA_BASE_URL:-}" DICTIVA_API_KEY="${DICTIVA_API_KEY:-}" \
    exec node "$DICTIVA_FORMALIZE_CLI" "$ACTION"
fi

# 4. No adapter on hand — print the exact, honest next step rather than guess the payload.
cat <<EOF
dictiva-agent-governance connect: no adapter found.

This wrapper delegates to Dictiva's official import adapter rather than reimplementing the import payload
(which would drift from the server schema). To connect:

  1. Get the adapter from the 'dictiva-formalize-agents' skill (it ships formalize-agents.mjs).
  2. export DICTIVA_FORMALIZE_CLI=/path/to/formalize-agents.mjs
  3. export DICTIVA_BASE_URL=https://<your-dictiva-host>   DICTIVA_API_KEY=<tenant key, agents:write>
  4. connect/dictiva-connect.sh dry-run     # preview — writes nothing
     connect/dictiva-connect.sh apply       # creates DRAFT identities + charters for you to curate

The flow only ever READS this repo's files. Eject anytime: rm -f .dictiva/auth.json && rm -rf connect/ —
your AGENTS.md, .claude/agents, hooks, and lint are untouched. See connect/README.md.
EOF
exit 0
