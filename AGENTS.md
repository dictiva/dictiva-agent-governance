# dictiva-agent-governance — agent guide

A vendor-neutral agent-governance starter kit. This repo governs itself with the kit it ships.

## Maintaining this repository

Work from an isolated worktree on a feature branch; preserve the operator's main checkout.
Use the Node version in `.nvmrc`. After the operator authorizes merging your own pull request,
run `python3 scripts/merge-pr.py <PR>` from its clean worktree, then repeat with `--execute`.
This is the only merge path: it requires the current base and successful `verify` CI, checks the
actual local Node runtime, runs the kit proofs and secret scan, pins the head when squashing,
confirms `mergedAt`, and tears down the merged branch. See [the gate contract](scripts/GATE.md).

The gate and `.githooks/pre-commit` scanner are repository maintenance tools copied unchanged
from the shared lifecycle templates. They are not installed into consumers by `forge.md`.
The gate invokes the scanner directly; do not change `core.hooksPath` or replace the kit's
existing `hooks/` files. Hook wiring and agent-memory migration are separate operator tasks.

This file is the canonical, cross-harness guide for AI agents working in this repo. It is read natively by
27+ tools (Codex, Cursor, Copilot, Gemini, goose, …). The prose `May` / `May not` below is what every tool
reads; the machine-readable mirror is for local drift-checking and the optional Dictiva import.

## Agents

<!-- forge:start id=agent-lead -->
### lead — coordinator
**Owner:** carlos@dictiva.com · **Risk:** medium

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
**Owner:** carlos@dictiva.com · **Risk:** medium

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
