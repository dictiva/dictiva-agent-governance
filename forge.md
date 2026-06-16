# forge.md — set up agent governance for this repo

> **What this is.** A single, self-contained file that teaches any AI coding agent to give
> *this repository* a small, durable governance setup: named agents, written rules about what
> each one may and may not do, and — where the harness supports it — a hook that physically
> blocks the dangerous commands. It writes plain Markdown + shell. Nothing here depends on any
> vendor. An optional last step connects Dictiva for verifiable identity and signed attestations;
> skip it and everything still works.
>
> **How to run.** Open this repo in any AI coding agent (Claude Code, Cursor, Codex, Copilot,
> Gemini, or a plain chat LLM with file access) and say:
> *"Read forge.md and set up agent governance for this repo."*

---

## Instructions to the AI agent reading this file

You are running an interactive, idempotent setup. Be brief. Default to action with safe defaults;
ask the human only what you genuinely cannot infer. Never overwrite hand-written prose. Follow the
steps in order.

### Step 0 — Detect context (read-only, no questions yet)

Silently determine and then report in **one line** each:

1. **Stack** — from `package.json` / `go.mod` / `Cargo.toml` / `pyproject.toml` / etc.
2. **Default branch** — `git symbolic-ref --short refs/remotes/origin/HEAD` or `git branch --show-current`.
3. **Existing governance** — is there an `AGENTS.md`, `.claude/agents/`, `.cursor/rules/`, `governance/`? (If yes, this run is an **audit/patch**, not a fresh install.)
4. **Your own harness capabilities** — answer honestly to yourself:
   - Can you **write** files? (needed — minimum requirement)
   - Can you **run shell** commands? (needed to chmod + self-verify hooks)
   - Are you **Claude Code** specifically? (only Claude Code enforces `PreToolUse` hooks + per-agent `tools:` allowlists today)

Then state the **honest capability line** for this harness, e.g.:
*"This harness can write the Markdown + git hooks. Live PreToolUse blocking works only in Claude Code; here I'll wire the git pre-commit hook instead, which works anywhere with git."*

### Step 1 — Ask ONE question (the default path)

> **Q. What email should own the agents in this repo?**  `[default: git config user.email]`

That is the only required question. For everything else, use these **safe defaults** and tell the
human you're using them (one line each), and that they can change any of it by saying *"customize."*

- **Roles:** two — a coordinator (`lead`) and a worker (`builder`). The `lead` may plan, review, and
  merge; the `builder` may write code and open PRs but **may not** merge to the default branch.
- **Hard-blocked actions (baseline):** `git push --force`, `git reset --hard`, and direct push to the
  default branch.
- **Audit trail:** on, in **warn-only** mode (never fails CI).
- **Dictiva:** skipped. (Mention: *"You can connect Dictiva later for verifiable identity + signed
  attestations — it's optional and additive."*)

If the human says **"customize,"** run the optional advanced interview in
[Appendix A](#appendix-a--advanced-interview-only-if-asked). Otherwise continue.

### Step 2 — Echo the plan (the single approval gate)

List every file you will **create** or **patch** (mark existing files "patch, won't overwrite prose"),
one line of purpose each. Then ask: *"Create these? (yes / edit)."* Wait for confirmation. This is the
only approval gate in the default path.

### Step 3 — Materialize (idempotent — create-if-absent, patch-marked-blocks-only)

Write the following. For `AGENTS.md` and any file you've written before, only insert or update the
regions you own, delimited by `<!-- forge:start id=... -->` / `<!-- forge:end -->`; leave everything
else untouched.

1. **`AGENTS.md`** (repo root) — the canonical, cross-harness governance file. For each role write a
   short **human-readable prose charter** *and* a structured block:

   ```markdown
   <!-- forge:start id=agent-lead -->
   ## Agent: lead
   **Owner:** <owner-email> · **Risk:** medium

   **May:** plan work, review changes, merge approved PRs.
   **May not:** force-push, reset --hard, or deploy to production without human approval.

   <!-- machine-readable mirror (used by tooling / optional Dictiva import) -->
   #### May
   - plan_work
   - review_changes
   - merge_approved_pr
   #### May not
   - force_push
   - deploy_to_prod_without_approval
   <!-- forge:end -->
   ```

   **Be honest in a one-line comment here:** the *prose* `May / May not` is what all AGENTS.md-reading
   tools (Codex, Cursor, Copilot, Gemini, goose, …) actually read; the `####` machine-readable mirror is
   for local drift-checking and the optional Dictiva import. Do not imply every harness parses the
   structure.

2. **`CLAUDE.md`** (repo root) — if absent, one line: `@AGENTS.md` (so Claude Code reads the canonical file).

3. **`.claude/agents/<role>.md`** (one per role) — real frontmatter + prose:

   ```markdown
   ---
   name: lead
   description: Coordinator — plans, reviews, merges. Delegate planning/review here.
   tools: Read, Grep, Glob, Bash, Edit          # the allowlist = the "medium" tier
   ---
   ## Identity
   - **Role:** coordinator   - **Autonomy:** acts on low-risk; asks first on anything in "May not".
   ## You MUST NOT
   - Force-push, reset --hard, or deploy to prod without explicit human approval.
   ## You ARE the only agent that may
   - Merge an approved PR to the default branch.
   ```

   Tell the human plainly: the `tools:` allowlist is enforced **only** by Claude Code (and partially
   Codex). On other harnesses these files are inert documentation — the AGENTS.md rule is the real floor.

4. **`governance/guard-patterns.json`** — generated **from** the charter `May not` lines, so the
   documented prohibition and the physical block share **one source of truth**:

   ```json
   { "deny": [
     { "id": "force-push",  "match": "git push.*(--force|-f|--force-with-lease|\\+)", "reason": "force-push is blocked by charter" },
     { "id": "reset-hard",  "match": "git reset.*--hard", "reason": "reset --hard is blocked by charter" },
     { "id": "push-default","match": "git push.*\\b(main|master)\\b", "reason": "direct push to default branch is blocked by charter" }
   ] }
   ```

5. **`governance/hooks/guard.sh`** — a `PreToolUse` deny hook (Bash 3.2) that reads stdin JSON, loads
   `guard-patterns.json`, and emits `{hookSpecificOutput:{permissionDecision:"deny",...}}` on a match,
   exiting 0. **Fail closed:** if `jq` is missing, fall back to `python3` (always present on macOS) to
   parse stdin; if neither is available, **deny by default** rather than allowing everything.

6. **`governance/hooks/pre-commit`** — a pure `git + grep` twin (no `jq`, no Claude envelope) that blocks
   the same patterns at commit time. **This is the cross-harness hard tier** — it works in any repo with
   git, regardless of AI vendor.

7. **`.claude/settings.json`** — **only if this harness is Claude Code:** wire `SessionStart → preflight.sh`
   and `PreToolUse(Bash) → guard.sh`. **Otherwise**, print the two commands the human runs themselves to
   install the git pre-commit hook (`cp governance/hooks/pre-commit .git/hooks/ && chmod +x .git/hooks/pre-commit`),
   labeled clearly: *"I can't wire a live tool-call hook in this harness — install the git hook instead."*

8. **`governance/hooks/preflight.sh`** — optional SessionStart audit (silent on a clean tree; lists
   uncommitted files / non-default branch). Claude Code only; harmless elsewhere.

9. **`governance/README.md`** — must contain the **honest harness × tier matrix** verbatim:

   | Enforcement tier | Mechanism | Works on |
   |---|---|---|
   | **Soft** (the real portable floor) | A written rule in `AGENTS.md` | All 27+ AGENTS.md-reading tools |
   | **Medium** | `tools:` allowlist in `.claude/agents/*.md` | Claude Code; partial Codex |
   | **Hard (git)** | `pre-commit` / `pre-push` hook | Any repo with git — covers **git ops only** |
   | **Hard (live)** | `PreToolUse` `guard.sh` | **Claude Code only** — covers any shell command |

   …plus one line: *"Dropping every AI vendor leaves Soft + Hard(git) fully working. That is the durable core."*

10. **`scripts/lint-attests.mjs`** (only if audit on) — pure Node + git, **warn-only by default**
    (`exit 0`), with a documented `--fail` flip for CI. Validates that commit trailers of the form
    `Governed-By: <RULE-ID>` (or `Attests: <RULE-ID> ...` if Dictiva is connected) are well-formed.
    Default to the vendor-neutral `Governed-By:` trailer — do **not** bake Dictiva's `tier=T<N>`
    vocabulary into permanent git history unless the human connects Dictiva.

### Step 4 — Self-verify enforcement (prove it works, before Dictiva is ever mentioned)

- **If you can run shell:** stage a sample `git push --force` against the hook and show the human the
  **deny actually firing**. Run the audit lint against `HEAD`. No network, no API key.
- **If you cannot run shell** (plain chat LLM): print the exact copy-paste block for the human to run,
  labeled *"I can't execute these here — run them to see the block fire."*

### Step 5 — Done. Offer two paths (don't push either).

- **Stay local** — `git add` the new files and commit. The harness is fully live with zero external
  dependency. **This is a complete, valid endpoint.**
- **Connect Dictiva (optional)** — see [Appendix B](#appendix-b--optional-dictiva-connect). One sentence:
  *"Dictiva reads these same files and adds verifiable DID identity, signed attestations, and a
  cross-repo dashboard — and it can bind a `May not` clause to a server-side refusal, which the local
  hooks can't. You can connect or eject at any time without touching these files."*

---

## Appendix A — Advanced interview (only if asked)

Ask these **one at a time, each with a bracketed default**, only when the human said "customize":

1. **Roles** — "Which roles? [lead + builder]." One `.claude/agents/<role>.md` + one AGENTS.md block each.
2. **Per role: May / Must-never** — "What may `<role>` do, and what must it **never** do without you?"
   Use plain language. From each *Must-never* answer, **auto-propose** a matching `guard-patterns.json`
   entry (e.g. "deploy to prod" → a prod-deploy deny pattern) — the human confirms, they don't hand-write regex.
3. **Per role: autonomy** — "Can `<role>` act on its own, or ask first on risky things? [ask first]."
4. **Hard-block selection** — "Which prohibitions get a physical hook vs. stay written-only?
   [force-push, reset --hard, direct push to default]."
5. **Audit** — "Vendor-neutral `Governed-By:` commit trailers, warn-only in CI? [yes]."
6. **Dictiva** — "Connect Dictiva now / later / never? [later]."

> **Drift guard (run every materialize):** after writing, scan each role's `May not` for any **high-risk**
> clause (deploy / delete / secret / prod / credential) that has **no** matching `guard-patterns.json`
> entry, and print: *"N high-risk prohibitions are written-only (no hard block) — confirm that's intended."*
> This keeps the documented charter and the physical guard honest with each other.

---

## Appendix B — Optional Dictiva connect (and how to eject)

**Connecting is additive and severable.** It reads the files above and writes only to Dictiva's own
side; it never modifies your repo.

- **What it touches in your repo:** exactly one gitignored secret (`.dictiva/auth.json`, mode 0600) and
  one optional directory (`governance/connect/`). Nothing else.
- **How it discovers your agents (be accurate):** Dictiva's import skill reads your `.claude/agents/*.md`
  files and a `docs/agents/registered-agents.md` table, and **infers** May/May-not from your wording — it
  does **not** parse the `####` blocks via the CLI. (The structured `####` blocks are consumed by Dictiva's
  GitHub-App webhook scanner, a separate path.) So: keep your `.claude/agents/*.md` and a roster table
  accurate — those are what the connect step reads.
- **The flow:** `configure` → `scan` (offline preview) → `dry-run` (shows what it would create, asks y/n)
  → `apply`. It creates **draft** identities + charters for you to curate; it never auto-activates anything.
- **What you gain that the local kit cannot do:** verified `did:web` identity, **signed** W3C Verifiable
  Credential attestations, a cross-repo dashboard, and — the real differentiator — binding a charter's
  `May not` clause to a **server-side refusal**, so a prohibition is enforced even outside the one harness
  that loads `guard.sh`.
- **Eject (no lock-in):** delete `.dictiva/auth.json` and `governance/connect/`. Your `AGENTS.md`,
  `.claude/agents/*.md`, hooks, and lint are byte-for-byte unchanged and keep working. You lose only the
  verifiable layer, never the governance.

---

*forge.md is itself plain Markdown — version it, read it, re-run it. It is the durable best practice;
Dictiva is the optional verifiable layer on top.*
