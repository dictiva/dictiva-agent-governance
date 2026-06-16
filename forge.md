# forge.md — set up agent governance for this repo

> **What this is.** A single, self-contained file that teaches any AI coding agent to give *this
> repository* a small, durable governance setup: named agents, written rules about what each may and may
> not do, and — where the harness supports it — hooks that physically block the dangerous commands.
> Everything it writes is plain Markdown + shell/Node, embedded in this file (Appendix C), so it needs no
> other file on disk and no network. An optional last step connects Dictiva for a verifiable layer; skip
> it and everything still works.
>
> **How to run.** Open this repo in any AI coding agent (Claude Code, Cursor, Codex, Copilot, Gemini, or a
> plain chat LLM with file access) and say:
> *"Read forge.md and set up agent governance for this repo."*

---

## Instructions to the AI agent reading this file

You are running an interactive, idempotent setup. Be brief. Default to action with safe defaults; ask the
human only what you genuinely cannot infer. **The exact file contents you must write are in Appendix C** —
do not invent them. Follow the steps in order.

### Step 0 — Detect context (read-only, no questions yet)

Report in **one line** each: the **stack** (from `package.json` / `go.mod` / `Cargo.toml` / `pyproject.toml`);
the **default branch**; whether **governance already exists** (`AGENTS.md`, `.claude/agents/`, `governance/` →
if so this run is an audit/patch, not a fresh install); and **your own harness capabilities** — can you write
files (required), run shell (needed to chmod + self-verify), and are you **Claude Code** (the only harness
that enforces `PreToolUse` hooks + per-agent `tools:` allowlists today)? State the honest capability line,
e.g. *"I can write the Markdown + git hooks; live PreToolUse blocking is Claude-Code-only, so on this harness
I'll wire the git hooks, which work anywhere with git."*

### Step 1 — Ask ONE question (the default path)

> **Q. What email should own the agents in this repo?**  `[default: git config user.email]`

That is the only required question. For everything else use these **safe defaults**, and tell the human (one
line each) they can change any of it by saying *"customize"* (→ Appendix A):

- **Roles:** two — `lead` (coordinator: plans, reviews, merges) and `builder` (executor: implements, opens
  PRs, **may not** merge to the default branch).
- **Hard-blocked actions:** force-push, `reset --hard`, and direct push/commit to the default branch.
- **Audit trail:** on, warn-only (never fails CI).
- **Dictiva:** skipped (mention it's available later via Appendix B).

### Step 2 — Echo the plan (the single approval gate)

List every file you will create or patch (mark existing files "patch, won't overwrite prose"), one line of
purpose each — they are the files in Appendix C. Ask *"Create these? (yes / edit)."* Wait for confirmation.

### Step 3 — Materialize from Appendix C (idempotent)

Write every file listed in **Appendix C** to the path in its `### FILE:` heading, with the exact contents
shown:

- Files marked **verbatim** (all the scripts, hooks, and `settings.json`) must be copied **byte-for-byte**.
  They are security-critical and tested — do not paraphrase, reformat, or "improve" them.
- Files marked **fill placeholders** are templates: replace `{{PROJECT_NAME}}`, `{{ONE_LINE_PURPOSE}}`, and
  `{{OWNER_EMAIL}}` with the Step 0/1 answers.
- For existing files, patch only the regions delimited by `<!-- forge:start id=… -->` / `<!-- forge:end -->`;
  leave hand-written prose untouched.

Then: `chmod +x` every `.sh` file, the two git hooks, and `lint-attests.mjs`; install
`governance/hooks/pre-commit` and `pre-push` into `.git/hooks/`; and — only if you are **Claude Code** — the
`.claude/settings.json` in Appendix C wires the hooks for you. On other harnesses, tell the human to run:
`cp governance/hooks/pre-commit governance/hooks/pre-push .git/hooks/ && chmod +x .git/hooks/pre-commit .git/hooks/pre-push`.

> One honest note to pass on: the `#### May` / `#### May not` blocks in `AGENTS.md` are the machine-readable
> mirror for tooling and the optional Dictiva import. The **prose** `May` / `May not` is what every
> AGENTS.md-reading tool actually reads; the `tools:` allowlist is enforced only by Claude Code (and partly
> Codex). The real portable floor is the prose rule; the real cross-harness teeth are the git hooks.

### Step 4 — Self-verify enforcement (prove it, before Dictiva)

If you can run a shell, run `bash scripts/self-verify.sh` and show the human the guard denying the dangerous
commands and the audit lint running. If you cannot run a shell (plain chat LLM), print the command and label
it *"run this to watch the block fire — I can't execute it in this harness."*

### Step 5 — Done. Offer two paths (don't push either).

- **Stay local** — `git add` on a feature branch and open a PR. The harness is fully live, zero external
  dependency. A complete, valid endpoint.
- **Connect Dictiva (optional)** — see Appendix B. Dictiva reads these same files and adds verified `did:web`
  identity, signed attestations, a dashboard, and the one thing the local hooks can't do: bind a `May not`
  clause to a server-side refusal. Connect or eject any time without touching these files.

---

## Appendix A — Advanced interview (only if the human says "customize")

Ask one at a time, each with a bracketed default: **(1) roles** `[lead + builder]`; **(2) per role, May /
Must-never** in plain language — and from each *Must-never*, auto-propose a matching `guard-patterns.json`
entry (e.g. "deploy to prod" → a prod-deploy deny pattern), the human confirms; **(3) per role, autonomy**
`[act on low-risk, ask first on risky]`; **(4) which prohibitions get a hard hook vs prose-only**
`[force-push, reset --hard, direct push/commit to default]`; **(5) audit trailers** `[Governed-By:, warn-only]`;
**(6) Dictiva** `[later]`. After writing, warn about any high-risk `May not` with no matching hard pattern
(soft-only), so the gap is never silent.

## Appendix B — Optional Dictiva connect (and eject)

Connecting is additive and severable. Dictiva's CLI import reads your `.claude/agents/*.md` + a
`docs/agents/registered-agents.md` roster table (it does **not** parse the `AGENTS.md` `####` blocks — those
feed Dictiva's GitHub-App webhook scanner). Flow: `configure` (writes `.dictiva/auth.json`, mode 0600,
gitignored) → `scan` (offline) → `dry-run` (shows what it would create) → `apply` (creates DRAFT identities +
charters; never auto-activates). **Eject:** `rm -f .dictiva/auth.json && rm -rf governance/connect/` — your
`AGENTS.md`, `.claude/agents/*.md`, hooks, and lint are untouched and keep working. You lose only the verified
DIDs, signed credentials, dashboard, and server-side refusal binding — none of which ever wrote into your repo.

---

## Appendix C — file contents

Write each file below into the path in its `### FILE:` heading. **verbatim** = copy exactly (security-critical);
**fill placeholders** = substitute the interview answers. Code fences use four backticks so inner triple-backtick
blocks are preserved.

<!-- forge:manifest — generated by scripts/build-forge.py; edit the source files in hooks/ scripts/ templates/, not the blocks below -->

### FILE: AGENTS.md  (fill placeholders)
````markdown
# {{PROJECT_NAME}} — agent guide

{{ONE_LINE_PURPOSE}}

This file is the canonical, cross-harness guide for AI agents working in this repo. It is read natively by
27+ tools (Codex, Cursor, Copilot, Gemini, goose, …). The prose `May` / `May not` below is what every tool
reads; the machine-readable mirror is for local drift-checking and the optional Dictiva import.

## Agents

<!-- forge:start id=agent-lead -->
### lead — coordinator
**Owner:** {{OWNER_EMAIL}} · **Risk:** medium

**May:** plan work, review changes, and merge approved pull requests.
**May not:** force-push, `reset --hard`, or deploy to production without explicit human approval.
**Escalates:** anything in "May not" → ask the human first.

<!-- machine-readable mirror (tooling / optional Dictiva import) -->
#### May
- plan_work
- review_changes
- merge_approved_pr
#### May not
- force_push
- reset_hard
- deploy_to_prod_without_approval
#### Data access
- source_code
- pull_request_metadata
#### External systems
- github
<!-- forge:end -->

<!-- forge:start id=agent-builder -->
### builder — executor
**Owner:** {{OWNER_EMAIL}} · **Risk:** medium

**May:** write code, run tests, and open pull requests.
**May not:** merge to the default branch, force-push, or change dependencies without the lead's approval.
**Escalates:** schema changes, new dependencies → ask the lead.

<!-- machine-readable mirror (tooling / optional Dictiva import) -->
#### May
- write_code
- run_tests
- open_pull_request
#### May not
- merge_to_default_branch
- force_push
- change_dependencies_without_approval
#### Data access
- source_code
#### External systems
- github
<!-- forge:end -->
````

### FILE: CLAUDE.md  (verbatim)
````text
@AGENTS.md
````

### FILE: .claude/agents/lead.md  (verbatim)
````markdown
---
name: lead
description: Coordinator for this repo — plans work, reviews changes, merges approved PRs. Delegate planning and review to this agent.
tools: Read, Grep, Glob, Bash, Edit
# model: optional — pin a model if your harness supports it
---

# lead — coordinator

You are the **lead**: you own the flow of work in this repo. You plan, review, and merge — you do not do
the bulk implementation yourself; you delegate that to specialists and check their output.

## Identity
- **Role:** orchestrator / coordinator
- **Autonomy:** act on low-risk steps; ask the human first on anything listed under "You MUST NOT".

## You MUST
- Keep `AGENTS.md` and the agent files in sync when a charter changes.
- Require a green build before merging.

## You MUST NOT
- Force-push, `reset --hard`, or deploy to production without explicit human approval.

## You ARE the only agent that may
- Merge an approved pull request to the default branch.

> The `tools:` allowlist above is enforced by Claude Code (and partially Codex). On other harnesses this
> file is documentation — the `AGENTS.md` rule and the git hooks are the real enforcement.
````

### FILE: .claude/agents/builder.md  (verbatim)
````markdown
---
name: builder
description: Executor for this repo — implements features and fixes for a single task, opens a PR, never merges.
tools: Read, Grep, Glob, Bash, Edit, Write
# model: optional
---

# builder — executor

You are a **builder**: you implement one task at a time and open a pull request. You report the PR and
stop — you never merge it yourself.

## Identity
- **Role:** executor
- **Autonomy:** implement independently; escalate the items under "You MUST NOT".

## You MUST
- Verify the build passes before opening a PR.
- Work on a feature branch, never the default branch.

## You MUST NOT
- Merge to the default branch, force-push, or change dependencies without the lead's approval.

## You ARE the only agent that may
- (nothing exclusive — builders are interchangeable; that is by design)

> The `tools:` allowlist is honored only by Claude Code / Codex. Elsewhere, the `AGENTS.md` rule and the
> git hooks are what actually bind you.
````

### FILE: .claude/settings.json  (verbatim — Claude Code only)
````json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/governance/hooks/preflight.sh", "timeout": 10 }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/governance/hooks/guard.sh", "timeout": 5 }
        ]
      }
    ]
  }
}
````

### FILE: docs/agents/registered-agents.md  (fill placeholders)
````markdown
# Registered agents

The roster of agents that operate on this repository. This table is plain documentation on its own; it is
also one of the two things Dictiva's CLI import reads (the other is `.claude/agents/*.md`). Keep it
accurate if you plan to connect Dictiva.

| Slug | Role | Owner | Risk | Status |
|------|------|-------|------|--------|
| agent-lead | coordinator (plans, reviews, merges) | {{OWNER_EMAIL}} | medium | active |
| agent-builder | executor (implements, opens PRs) | {{OWNER_EMAIL}} | medium | active |

<!-- Add one row per agent. Slug convention: agent-<role>. -->
<!-- Optional verifiable identity (self-hosted, no Dictiva needed): -->
<!--   did:web:<your-domain>:agents:agent-<role>  (a domain + a static did.json is all it takes) -->
````

### FILE: governance/hooks/guard.sh  (verbatim)
````bash
#!/usr/bin/env bash
# charter-forge :: guard.sh
#
# A Claude Code PreToolUse deny-hook for the Bash tool. It blocks the shell
# commands your charter says an agent "may not" run — regardless of skill,
# instruction, or context drift. Friction is the feature.
#
# Deny patterns are loaded from guard-patterns.json (next to this script, or
# $CHARTER_FORGE_PATTERNS), which forge.md generates FROM your AGENTS.md
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
PATTERNS_FILE="${CHARTER_FORGE_PATTERNS:-$SCRIPT_DIR/guard-patterns.json}"

if ! command -v python3 >/dev/null 2>&1; then
  # No parser -> fail closed.
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"charter-forge guard.sh cannot parse tool input (python3 not found) — failing closed. Install python3, or run the command yourself in a terminal."}}'
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
        "permissionDecisionReason": "charter-forge: unparseable tool input — failing closed."}}, separators=(",", ":")))
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
````

### FILE: governance/hooks/guard-patterns.json  (verbatim)
````json
{
  "_comment": "Generated FROM your AGENTS.md charter 'May not' lines by forge.md, so the written rule and the physical block share one source. Edit the charter, re-run forge.md, and this regenerates. Hand-editing is fine too.",
  "deny": [
    {
      "id": "force-push",
      "match": "git\\s+push\\b.*(--force\\b|-f\\b|--force-with-lease|\\s\\+)",
      "reason": "force-push is blocked by charter (May not: force_push)"
    },
    {
      "id": "reset-hard",
      "match": "git\\s+reset\\b.*--hard",
      "reason": "reset --hard is blocked by charter (May not: discard_history)"
    },
    {
      "id": "push-default",
      "match": "git\\s+push\\b.*\\b(main|master)\\b",
      "reason": "direct push to the default branch is blocked by charter (May not: push_to_default)"
    }
  ]
}
````

### FILE: governance/hooks/pre-commit  (verbatim)
````bash
#!/usr/bin/env bash
# charter-forge :: git pre-commit hook (cross-harness hard tier — part 1)
#
# Refuses a commit made DIRECTLY on the default branch. This is the honest,
# universal git-native guardrail: it works in any repo with git, regardless of
# which AI agent (or human) is driving. Pair it with pre-push for push/force
# protection. Install: cp hooks/pre-commit .git/hooks/ && chmod +x .git/hooks/pre-commit
#
# Escape valve: COMMIT ON DEFAULT BRANCH ON PURPOSE with `CF_ALLOW=1 git commit ...`.

# Deliberately NOT 'set -e': the branch-detection pipeline below legitimately
# fails when a repo has no origin/HEAD, and a hook must never crash into a block.
set -u

[ "${CF_ALLOW:-0}" = "1" ] && exit 0

default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
[ -z "$default_branch" ] && default_branch="main"

# symbolic-ref (not rev-parse) resolves the branch name even on an unborn branch
# (zero commits), so 'no direct commits on main' holds for the very first commit too.
current="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo '')"

if [ "$current" = "$default_branch" ]; then
  echo "charter-forge: refusing a direct commit on '$default_branch' (the default branch is protected)." >&2
  echo "  Make a feature branch:  git switch -c my-change" >&2
  echo "  Override on purpose:    CF_ALLOW=1 git commit ..." >&2
  exit 1
fi
exit 0
````

### FILE: governance/hooks/pre-push  (verbatim)
````bash
#!/usr/bin/env bash
# charter-forge :: git pre-push hook (cross-harness hard tier — part 2)
#
# Blocks two charter prohibitions at the one git event that can see them:
#   1. a direct push to the default branch, and
#   2. a non-fast-forward (force) push to any branch.
# Pure git; works in any harness with git. Install:
#   cp hooks/pre-push .git/hooks/ && chmod +x .git/hooks/pre-push
#
# git feeds pushed refs on stdin as:  <local ref> <local sha> <remote ref> <remote sha>
# Escape valve: CF_ALLOW=1 git push ...

# Not 'set -e': branch detection and merge-base checks can fail benignly, and a
# push hook must fail safe (allow) on its own internal errors, not crash-block.
set -u
[ "${CF_ALLOW:-0}" = "1" ] && exit 0

default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
[ -z "$default_branch" ] && default_branch="main"
z40="0000000000000000000000000000000000000000"
status=0

while read -r local_ref local_sha remote_ref remote_sha; do
  [ -z "${remote_ref:-}" ] && continue

  # 1. direct push to the default branch
  if [ "$remote_ref" = "refs/heads/$default_branch" ]; then
    echo "charter-forge: refusing a direct push to '$default_branch' (protected by charter)." >&2
    echo "  Open a PR from a feature branch instead, or override with CF_ALLOW=1." >&2
    status=1
  fi

  # 2. force / non-fast-forward push (remote has commits the local ref doesn't contain)
  if [ "$remote_sha" != "$z40" ] && [ "$local_sha" != "$z40" ]; then
    if ! git merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null; then
      echo "charter-forge: refusing a non-fast-forward (force) push to '$remote_ref' (protected by charter)." >&2
      echo "  Override on purpose with CF_ALLOW=1." >&2
      status=1
    fi
  fi
done

exit "$status"
````

### FILE: governance/hooks/preflight.sh  (verbatim)
````bash
#!/usr/bin/env bash
# charter-forge :: preflight.sh (Claude Code SessionStart hook)
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

msg="charter-forge preflight — owed: "
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
````

### FILE: governance/README.md  (fill placeholders)
````markdown
# Agent governance for {{PROJECT_NAME}}

This repo has a charter-forge governance setup. Agents are named in `AGENTS.md`, scoped in
`.claude/agents/`, and the dangerous commands are physically blocked by the hooks here.

## What's enforced, and where

| Tier | Mechanism | Works on |
|---|---|---|
| **Soft** (portable floor) | the `May not` rules in `AGENTS.md` | all 27+ AGENTS.md-reading tools |
| **Medium** | the `tools:` allowlist in `.claude/agents/*.md` | Claude Code; partial Codex |
| **Hard (git)** | `.git/hooks/pre-commit` + `pre-push` (no direct/force push or commit on the default branch) | any repo with git |
| **Hard (live)** | `governance/hooks/guard.sh` via Claude Code `PreToolUse` | Claude Code only |

The deny patterns in `hooks/guard-patterns.json` are derived from the charter's `May not` lines, so the
written rule and the physical block stay in sync. Edit the charter, re-run forge.md, and they regenerate.

## Prove it

```bash
bash scripts/self-verify.sh
```

## Re-run / change

Tell any AI agent "read forge.md and run it" to add a role, tighten a guard, or connect Dictiva. To
override a block on purpose in git: `CF_ALLOW=1 git commit ...`.
````

### FILE: scripts/lint-attests.mjs  (verbatim)
````javascript
#!/usr/bin/env node
// charter-forge :: lint-attests.mjs
//
// Validates governance commit trailers in recent history. Pure Node + git,
// zero network, zero server. WARN-MODE BY DEFAULT (always exits 0) so it is
// safe to add to CI without breaking existing PRs; pass --fail to make a
// malformed trailer fail the build once your team has adopted the convention.
//
// Default vendor-neutral grammar:
//     Governed-By: <RULE-ID>
// If you connect Dictiva, it also accepts the richer attestation grammar:
//     Attests: <RULE-ID> tier=T<N> evidence=<kind>=<ref>[,<kind>=<ref>...]
//
// Usage:  node scripts/lint-attests.mjs [--range <git-range>] [--fail]
//   --range   git log range to scan (default: last 50 commits)
//   --fail    exit 1 on any malformed trailer (default: warn only, exit 0)

import { execSync } from "node:child_process";

const args = process.argv.slice(2);
const FAIL = args.includes("--fail");
const rangeIdx = args.indexOf("--range");
const RANGE = rangeIdx !== -1 ? args[rangeIdx + 1] : "-50";

const GOVERNED_BY = /^Governed-By:\s*([A-Z][A-Z0-9-]*(?:-\d+)?)\s*$/;
const ATTESTS = /^Attests:\s*([A-Z][A-Z0-9-]*(?:-\d+)?)\s+tier=T([1-6])\s+evidence=(\S+)\s*$/;

function git(cmd) {
  try {
    return execSync(`git ${cmd}`, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
  } catch {
    return "";
  }
}

// Resolve the commit list. Tolerate an empty / brand-new repo gracefully.
const log = git(`log ${RANGE} --format=%H`).trim();
if (!log) {
  console.log("charter-forge lint-attests: no commits to scan — ok.");
  process.exit(0);
}
const commits = log.split("\n").filter(Boolean);

let trailers = 0;
const problems = [];

for (const sha of commits) {
  const body = git(`show -s --format=%B ${sha}`);
  for (const rawLine of body.split("\n")) {
    const line = rawLine.trim();
    if (!/^(Governed-By|Attests):/.test(line)) continue;
    trailers++;
    if (GOVERNED_BY.test(line) || ATTESTS.test(line)) continue;
    problems.push({ sha: sha.slice(0, 8), line });
  }
}

console.log(
  `charter-forge lint-attests: scanned ${commits.length} commit(s), ` +
    `found ${trailers} governance trailer(s), ${problems.length} malformed.`
);

for (const p of problems) {
  console.log(`  ${FAIL ? "ERROR" : "warn"} ${p.sha}: malformed trailer -> "${p.line}"`);
}

if (problems.length && FAIL) {
  console.error("charter-forge lint-attests: failing (--fail set).");
  process.exit(1);
}
process.exit(0);
````

### FILE: scripts/self-verify.sh  (verbatim)
````bash
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
# Hooks live at governance/hooks/ (installed by forge.md) or hooks/ (this kit's dev layout).
if   [ -f "$ROOT/governance/hooks/guard.sh" ]; then HOOKS="$ROOT/governance/hooks"
elif [ -f "$ROOT/hooks/guard.sh" ];            then HOOKS="$ROOT/hooks"
else echo "self-verify: cannot find guard.sh under governance/hooks/ or hooks/" >&2; exit 2; fi
GUARD="$HOOKS/guard.sh"
if [ -f "$HOOKS/guard-patterns.json" ]; then export CHARTER_FORGE_PATTERNS="$HOOKS/guard-patterns.json"
else export CHARTER_FORGE_PATTERNS="$HOOKS/guard-patterns.example.json"; fi
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
````

