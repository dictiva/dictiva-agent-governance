# charter-forge

**Give any repo a small, durable agent-governance setup in about a minute — named agents, written
rules about what each may and may not do, and a hook that physically blocks the dangerous commands.**

It's plain Markdown + a few shell/Node scripts. Nothing here depends on a vendor. You can connect
[Dictiva](#connecting-dictiva-optional) for verifiable identity and signed attestations, or never do —
the governance is yours either way.

> Why this exists: a generic AI coding agent can't be held accountable, because it has no declared
> identity, no scoped charter, and no record. Give it a name, a `may` / `may not`, and enforcement that
> bites, and "the AI did it" becomes a claim you can point at. That's all this kit is.

## Quickstart (60 seconds)

Open your repo in any AI coding agent (Claude Code, Cursor, Codex, Copilot, Gemini, or a plain chat LLM
with file access) and say:

> **"Read forge.md and set up agent governance for this repo."**

It asks **one** question (who owns the agents), infers safe defaults, writes the files, and — if it can
run a shell — proves the block fires in front of you. Say *"customize"* for the full interview.

Prefer to look before you run? Everything it writes is in [`templates/`](templates/), and you can run the
proof yourself right now:

```bash
bash scripts/self-verify.sh      # feeds sample commands to the guard, asserts deny/allow
```

## What you actually get — by harness (the honest matrix)

Enforcement comes in tiers of increasing strength. **Not all tiers work everywhere** — and pretending
they do is how governance becomes theater. Here is exactly what binds where:

| Tier | Mechanism | Blocks | Works on |
|---|---|---|---|
| **Soft** — the real portable floor | a written rule in `AGENTS.md` | nothing physically; the agent reads and is expected to comply | **all 27+ AGENTS.md-reading tools** (Codex, Cursor, Copilot, Gemini, goose, Aider, Zed, …) |
| **Medium** | a `tools:` allowlist in `.claude/agents/<role>.md` | the agent simply isn't given the capability | Claude Code; partially Codex |
| **Hard (git)** | `pre-commit` + `pre-push` hooks | direct commit/push to the default branch; force-pushes | **any repo with git** — covers git operations only |
| **Hard (live)** | `guard.sh` as a Claude Code `PreToolUse` hook | any shell command your charter forbids, at call time | **Claude Code only** |

**The durable core is Soft + Hard(git).** Drop every AI vendor and those two still work — the rule is in
a file every tool reads, and the block is enforced by git itself. "Friction is the feature" only holds
because the friction lives in git, not in one model's good behavior.

## The one idea that makes it real, not cosmetic

The hard block reads [`hooks/guard-patterns.json`](hooks/guard-patterns.example.json), which `forge.md`
generates **from** your `AGENTS.md` charter's `May not` lines. So the written prohibition and the physical
block share **one source** — edit the charter, regenerate, and the guard tracks it. A `May not` clause
with no matching hard pattern is flagged (soft-only) every session, so the gap is never silent.

## Files

```
forge.md                      the self-executing installer — paste-and-run in any AI agent
hooks/
  guard.sh                    Claude Code PreToolUse deny-hook (fail-closed; reads guard-patterns.json)
  guard-patterns.example.json deny patterns, generated from your charter's "May not"
  pre-commit                  git hook: no direct commits on the default branch
  pre-push                    git hook: no direct/force pushes to the default branch
  preflight.sh                Claude Code SessionStart audit (silent on a clean tree)
scripts/
  lint-attests.mjs            warn-mode commit-trailer audit (Governed-By: / Attests:)
  self-verify.sh              harness-independent proof the guard fires
templates/                    AGENTS.md + agent definition + roster templates forge.md fills in
docs/index.md                 one-screen explainer
connect/README.md             the optional Dictiva seam + the eject contract
```

## Connecting Dictiva (optional)

Connecting is **additive and severable** — see [`connect/README.md`](connect/README.md). Dictiva reads the
same files this kit writes and adds verified `did:web` identity, **signed** attestations, a cross-repo
dashboard, and the one thing the local hooks can't do: bind a `May not` clause to a **server-side refusal**.
To eject: delete `.dictiva/auth.json` and `governance/connect/`. Your charters, allowlists, hooks, and
lint are untouched and keep working. No lock-in — that's the point.

## License

MIT — see [`LICENSE`](LICENSE). Use it, fork it, ship it inside your own product.
