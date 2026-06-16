#!/usr/bin/env python3
# Regenerate forge.md's Appendix C manifest from the canonical kit files.
# Run this after editing anything in hooks/ scripts/ templates/ so the
# self-contained forge.md stays in sync. CI (check-forge-embeds.py) fails the
# build if you forget. The prose above the <!-- forge:manifest --> sentinel is
# hand-edited and preserved; everything below it is generated.
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FORGE = os.path.join(ROOT, "forge.md")
SENTINEL = "<!-- forge:manifest"

# (target path, source in kit, fence language, manifest annotation)
MANIFEST = [
    ("AGENTS.md", "templates/AGENTS.md.tmpl", "markdown", "fill placeholders"),
    ("CLAUDE.md", "@LIT:@AGENTS.md", "text", "verbatim"),
    (".claude/agents/lead.md", "templates/agent.orchestrator.md.tmpl", "markdown", "verbatim"),
    (".claude/agents/builder.md", "templates/agent.specialist.md.tmpl", "markdown", "verbatim"),
    (".claude/settings.json", "templates/claude-settings.json", "json", "verbatim — Claude Code only"),
    ("docs/agents/registered-agents.md", "templates/registered-agents.md.tmpl", "markdown", "fill placeholders"),
    ("governance/hooks/guard.sh", "hooks/guard.sh", "bash", "verbatim"),
    ("governance/hooks/guard-patterns.json", "hooks/guard-patterns.example.json", "json", "verbatim"),
    ("governance/hooks/pre-commit", "hooks/pre-commit", "bash", "verbatim"),
    ("governance/hooks/pre-push", "hooks/pre-push", "bash", "verbatim"),
    ("governance/hooks/preflight.sh", "hooks/preflight.sh", "bash", "verbatim"),
    ("governance/README.md", "templates/governance-README.md.tmpl", "markdown", "fill placeholders"),
    ("scripts/lint-attests.mjs", "scripts/lint-attests.mjs", "javascript", "verbatim"),
    ("scripts/self-verify.sh", "scripts/self-verify.sh", "bash", "verbatim"),
]

text = open(FORGE).read()
idx = text.find(SENTINEL)
if idx < 0:
    raise SystemExit("build-forge: sentinel not found in forge.md")
eol = text.find("\n", idx)
head = text[: eol + 1] + "\n"  # keep through the sentinel line + one blank line

blocks = []
for path, src, lang, kind in MANIFEST:
    content = "@AGENTS.md\n" if src == "@LIT:@AGENTS.md" else open(os.path.join(ROOT, src)).read()
    blocks.append(f"### FILE: {path}  ({kind})\n````{lang}\n{content}````\n\n")

open(FORGE, "w").write(head + "".join(blocks))
print(f"forge.md regenerated — {len(MANIFEST)} embedded files.")
