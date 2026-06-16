# Contributing to charter-forge

Thanks for helping. The kit is small on purpose; the bar is **honesty and verifiability** — every claim about
enforcement should be runnable.

## Run the checks locally

These are exactly what CI runs (`.github/workflows/verify.yml`):

```bash
python3 scripts/check-forge-embeds.py        # forge.md manifest matches the kit files (no drift)
bash    scripts/self-verify.sh               # the guard denies the dangerous commands
python3 scripts/verify-forge-selfcontained.py  # forge.md installs clean from itself alone
```

All three must pass. They need `bash`, `python3`, `git`, and Node 18+.

## The one rule that trips people up: forge.md is generated

`forge.md` embeds the verbatim bytes of every script, hook, and template (its Appendix C manifest) so it is
self-contained. **Do not hand-edit the blocks below the `<!-- forge:manifest -->` sentinel.** Instead:

1. Edit the real source in `hooks/`, `scripts/`, or `templates/`.
2. Regenerate: `python3 scripts/build-forge.py`
3. The drift check will now pass.

If you change a hook's behavior, also update `scripts/self-verify.sh` (and its assertions) so the proof still
covers it.

## This repo governs itself

charter-forge runs the kit it ships: see its own [`AGENTS.md`](AGENTS.md) and [`.claude/agents/`](.claude/agents).
Enforcement on this public repo is CI (`self-verify`); maintainers who want local hooks can run `forge.md`
against their clone. Work happens on feature branches with PRs — never direct to `main`.

## Norms

- Small, single-purpose PRs. Conventional Commit titles (`fix:`, `feat:`, `docs:`).
- New claims need a test. If you add an enforcement pattern, add a `self-verify` assertion for it.
- MIT licensed — by contributing you agree your work is licensed the same.
