# Contributing to dictiva-agent-governance

Thanks for helping. The kit is small on purpose; the bar is **honesty and verifiability** — every claim about
enforcement should be runnable.

## Run the checks locally

Use the Node version in `.nvmrc` for development and CI (currently 24.22.1, the
[October 2026 security release](https://nodejs.org/en/blog/release/v24.22.1)). With NVM installed,
run `nvm install` once, then `nvm use` in this checkout. The kit has no npm dependencies to install.

CI (`.github/workflows/verify.yml`) asserts that the actual Node version matches `.nvmrc`, then runs:

```bash
node --check scripts/lint-attests.mjs          # audit script parses under the selected runtime
node scripts/lint-attests.mjs                 # run the audit directly (existing warning policy)
python3 scripts/check-forge-embeds.py        # forge.md manifest matches the kit files (no drift)
bash    scripts/self-verify.sh               # the guard denies the dangerous commands
python3 scripts/verify-forge-selfcontained.py  # forge.md installs clean from itself alone
```

All checks must pass. They need `bash`, `python3`, `git`, and the pinned Node release.
The explicit Node checks ensure a skipped or failed audit inside `self-verify.sh` cannot count as
successful Node qualification. CI uses GitHub-hosted runners; the JavaScript Actions' internal Node
runtime is managed by GitHub separately from the `.nvmrc` runtime used for the kit's scripts.

## The one rule that trips people up: forge.md is generated

`forge.md` embeds the verbatim bytes of every script, hook, and template (its Appendix C manifest) so it is
self-contained. **Do not hand-edit the blocks below the `<!-- forge:manifest -->` sentinel.** Instead:

1. Edit the real source in `hooks/`, `scripts/`, or `templates/`.
2. Regenerate: `python3 scripts/build-forge.py`
3. The drift check will now pass.

If you change a hook's behavior, also update `scripts/self-verify.sh` (and its assertions) so the proof still
covers it.

## This repo governs itself

dictiva-agent-governance runs the kit it ships: see its own [`AGENTS.md`](AGENTS.md) and [`.claude/agents/`](.claude/agents).
Enforcement on this public repo is CI (`self-verify`); maintainers who want local hooks can run `forge.md`
against their clone. Work happens on feature branches with PRs — never direct to `main`.

Maintainers merge an approved PR from its clean worktree using `python3 scripts/merge-pr.py <PR>`
for the dry run, then `python3 scripts/merge-pr.py <PR> --execute`. Select `.nvmrc` with `nvm use`
first. The gate requires the `verify` CI check and reruns the checks above, plus a secret scan;
its full contract is in [`scripts/GATE.md`](scripts/GATE.md). This repository-only maintenance
tooling does not change the files distributed through `forge.md`.

## Norms

- Small, single-purpose PRs. Conventional Commit titles (`fix:`, `feat:`, `docs:`).
- New claims need a test. If you add an enforcement pattern, add a `self-verify` assertion for it.
- MIT licensed — by contributing you agree your work is licensed the same.
