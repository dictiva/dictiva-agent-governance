# Agent governance, in one screen

You let an AI agent work in your repo. **charter-forge** gives that agent three things a generic
assistant doesn't have: a **name**, a **charter** (what it may and may not do), and **enforcement** that
physically blocks the dangerous commands. That's the whole idea — identity, rules, and teeth.

## See it work

```bash
bash scripts/self-verify.sh
```
```
  ok    [deny ] git push --force origin main
  ok    [deny ] git reset --hard HEAD~3
  ok    [deny ] git push origin main
  ok    [allow] git push origin feature/my-change
  ok    [allow] git status
PASS — enforcement fires as specified.
```

No account, no network, no API key. The block is real on day one.

## Adopt it

Open your repo in any AI coding agent and say **"read forge.md and set up agent governance for this
repo."** One question, safe defaults, done. Say *"customize"* for roles, per-role rules, and more.

## How strong is the block, really?

Honest answer, because honesty is the product:

- A **written rule** in `AGENTS.md` works in every AI coding tool that reads it (27+ today) — but it asks,
  it doesn't force.
- A **git hook** (`pre-commit` / `pre-push`) physically blocks direct/force pushes to your main branch in
  **any** repo with git — vendor-independent, survives dropping every AI tool.
- A **live tool-call hook** (`guard.sh`) blocks any forbidden shell command the moment an agent tries it —
  but only inside Claude Code today.

The first two are the durable core. Build on them; treat the third as a bonus where you have it.

<details>
<summary>The deeper layer (identity standards, attestations, Dictiva)</summary>

The charter is written as a `May` / `May not` block in `AGENTS.md` — now a Linux Foundation / Agentic AI
Foundation open standard. Agent identity can be a self-hosted `did:web` (a W3C standard: just a domain + a
static JSON file). Audit evidence rides on plain git commit trailers (`Governed-By: <RULE-ID>`).

**Dictiva** is the optional layer that turns those portable artifacts into *verifiable* ones: it reads your
files, issues signed W3C Verifiable Credential attestations against resolvable DIDs, gives you a cross-repo
dashboard, and binds a `May not` clause to a real server-side refusal. Connect it when you want proof you
can show an auditor; eject it any time and keep everything local. See `connect/README.md`.

</details>
