# Connecting Dictiva (optional) — and how to eject

The local kit is complete on its own. This step is for teams that want their governance to be
**verifiable** — signed, identity-anchored, and auditable across repos. It is additive and fully
severable.

## What it adds that the local kit cannot do

- **Verified identity** — your agents become resolvable `did:web` identities, not just slugs in a file.
- **Signed attestations** — governance commit trailers are upgraded to signed W3C Verifiable Credentials,
  so a claim like "this change complied with rule X" is cryptographically checkable, not just grep-able.
- **A cross-repo dashboard** — every agent, charter, and attestation across all your repos in one place.
- **Charter → refusal binding** — the differentiator: Dictiva can bind a `May not` clause to a
  **server-side refusal**, so a prohibition is enforced even outside the one harness that loads `guard.sh`.
  The local hooks can't reach this; it's the concrete thing you pay for.

## Run it — one command

[`connect/dictiva-connect.sh`](dictiva-connect.sh) drives the `scan → dry-run → apply` flow:

```bash
export DICTIVA_BASE_URL=https://<your-dictiva-host>  DICTIVA_API_KEY=<tenant key, agents:write>
export DICTIVA_FORMALIZE_CLI=/path/to/formalize-agents.mjs   # from the dictiva-formalize-agents skill
connect/dictiva-connect.sh dry-run    # preview — writes nothing
connect/dictiva-connect.sh apply      # creates DRAFT identities + charters to curate
```

**Why the wrapper delegates instead of bundling the importer.** This public, vendor-neutral repo does
**not** vendor a copy of Dictiva's `formalize-agents.mjs`. A pinned snapshot drifts from the server schema
(the import endpoint returns HTTP 426 on a version bump), and bundling internal tooling would couple a
standards-based kit to one vendor's release cadence. The wrapper points at the adapter you already have
(via `DICTIVA_FORMALIZE_CLI`) so the payload always matches the live API, and prints the exact next step if
it isn't present. The kit ships no import client of its own.

## How it reads your repo (stated accurately)

There are **two** ingestion paths, and they read different things — don't conflate them:

1. **The CLI import skill** (`dictiva-formalize-agents`) discovers agents from your `.claude/agents/*.md`
   files and a `docs/agents/registered-agents.md` roster table, and **infers** `May` / `May not` from your
   wording. → So keep those two artifacts accurate; they are what the CLI reads.
2. **The GitHub-App webhook scanner** parses the structured `#### May` / `#### May not` blocks inside
   `AGENTS.md`. → This is the path that consumes the machine-readable mirror `forge.md` writes.

`forge.md` emits both shapes, so either path works. (Earlier drafts of this kit claimed the CLI parses the
`AGENTS.md` blocks — it does not. The CLI reads `.claude/agents/` + the roster table. Stated here so nobody
ships the wrong claim.)

## The flow

```
configure   # writes .dictiva/auth.json (mode 0600, gitignored) — a TENANT-scoped API key
scan        # offline preview of what would be imported (no key needed)
dry-run     # POST .../api/agents/import?dryRun=true — shows create/update/noop + any gaps, writes nothing
apply       # creates DRAFT identities + charters for you to curate; never auto-activates enforcement
```

`scan` is offline. `dry-run`/`apply` need a tenant API key with `agents:write` (a platform key is rejected).

## Eject — the no-lock-in contract

Removing Dictiva is a two-line operation:

```bash
rm -f .dictiva/auth.json
rm -rf governance/connect/
```

**What stays (byte-for-byte unchanged):** `AGENTS.md` charters, `.claude/agents/*.md` allowlists, the git
hooks, `guard.sh`, the audit lint. Your governance keeps working in every harness.

**What you lose:** verified DIDs, signed VC attestations, the dashboard, and the server-side
charter→refusal binding. Those live entirely on Dictiva's side and never wrote anything into your repo.

> Want a defunct-schema-proof audit trail? Default your commit trailers to the vendor-neutral
> `Governed-By: <RULE-ID>` form (what `scripts/lint-attests.mjs` validates with no server). The richer
> `Attests: ... tier=T<N> ...` grammar is a Dictiva enrichment — only adopt it into permanent git history
> once you've connected, so your history never references a vocabulary you don't own.
