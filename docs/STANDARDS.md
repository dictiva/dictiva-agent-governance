# Standards dictiva-agent-governance builds on

dictiva-agent-governance is intentionally a thin layer over open standards, so the governance you author outlives any
single vendor — including Dictiva. Nothing here is a proprietary format you'd be trapped in.

| Standard | Steward / status | Role in the kit |
|---|---|---|
| **AGENTS.md** | Agentic AI Foundation (Linux Foundation), 2025 | The canonical governance file. Plain Markdown, no required schema, read natively by 27+ agent tools (Codex, Cursor, Copilot, Gemini, goose, Aider, Zed, …). This is the durable artifact. |
| **Claude Code subagents / hooks** | Anthropic convention | The "medium" (tool allowlist) and "live hard" (`PreToolUse` guard) enforcement tiers. Harness-specific; the kit treats them as a bonus, not the floor. |
| **git hooks** | git (universal) | The cross-harness "hard" tier — `pre-commit` / `pre-push` enforced by git itself, independent of any AI vendor. |
| **Conventional Commits / git trailers** | community spec | The audit trail — vendor-neutral `Governed-By: <RULE-ID>` trailers, grep-able forever. |
| **W3C Verifiable Credentials 2.0** | W3C Recommendation (May 2025) | The envelope for *signed* attestations — the optional Dictiva layer, not the local kit. |
| **W3C DID / `did:web`** | DID Core (Candidate Rec); `did:web` usable today | Portable agent identity — a domain + a static `did.json`, self-hostable with no blockchain and no Dictiva. |
| **in-toto** | CNCF graduated (2025) | The attestation/provenance format the signed tier can emit; also what SLSA uses. |
| **OSCAL** | NIST; FedRAMP-mandated by 2026 | Forward path for machine-readable compliance-evidence export. |

## The durability contract

- **Soft tier** (an `AGENTS.md` rule) and **hard-git tier** (the hooks) work with **zero** dependencies and
  survive dropping every AI vendor. That is the floor and the teeth.
- **Dictiva** only ever *reads* these files and adds a verifiable layer on its own side (signed VCs, resolved
  DIDs, a dashboard, and charter→runtime-refusal binding). Removing it leaves every file here untouched —
  see [`connect/README.md`](../connect/README.md) for the eject contract.

## Toward AAIF

dictiva-agent-governance aims to be a small, honest **reference implementation of repo-level agent governance on top of
`AGENTS.md`** — the identity/charter/enforcement pattern expressed in the most portable form available.
Issues and PRs that strengthen the standards mapping (or surface where a tier silently degrades on a given
harness) are especially welcome.
