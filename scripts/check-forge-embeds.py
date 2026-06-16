#!/usr/bin/env python3
# CI guard: every file embedded in forge.md (Appendix C) must match its canonical
# source in the kit, and all expected files must be present. Prevents the
# self-contained forge.md from silently drifting away from hooks/scripts/templates.
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FORGE = os.path.join(ROOT, "forge.md")

# embedded path -> canonical source in the kit ("@LIT:..." means a literal value)
SRC = {
    "AGENTS.md": "templates/AGENTS.md.tmpl",
    "CLAUDE.md": "@LIT:@AGENTS.md\n",
    ".claude/agents/lead.md": "templates/agent.orchestrator.md.tmpl",
    ".claude/agents/builder.md": "templates/agent.specialist.md.tmpl",
    ".claude/settings.json": "templates/claude-settings.json",
    "docs/agents/registered-agents.md": "templates/registered-agents.md.tmpl",
    "governance/hooks/guard.sh": "hooks/guard.sh",
    "governance/hooks/guard-patterns.json": "hooks/guard-patterns.example.json",
    "governance/hooks/pre-commit": "hooks/pre-commit",
    "governance/hooks/pre-push": "hooks/pre-push",
    "governance/hooks/preflight.sh": "hooks/preflight.sh",
    "governance/README.md": "templates/governance-README.md.tmpl",
    "scripts/lint-attests.mjs": "scripts/lint-attests.mjs",
    "scripts/self-verify.sh": "scripts/self-verify.sh",
}

lines = open(FORGE).read().splitlines(keepends=True)
emb, i, n = {}, 0, len(lines)
while i < n:
    m = re.match(r"^### FILE: (.+?)  \(", lines[i])
    if m:
        path = m.group(1).strip()
        if not lines[i + 1].startswith("````"):
            print(f"malformed manifest: no fence after {path}"); sys.exit(1)
        k, c = i + 2, []
        while k < n and lines[k].rstrip("\n") != "````":
            c.append(lines[k]); k += 1
        emb[path] = "".join(c)
        i = k + 1; continue
    i += 1

errs = []
for path, src in SRC.items():
    if path not in emb:
        errs.append(f"MISSING from forge.md manifest: {path}"); continue
    want = src[5:] if src.startswith("@LIT:") else open(os.path.join(ROOT, src)).read()
    if emb[path] != want:
        errs.append(f"DRIFT: forge.md embed of '{path}' != {src} (re-run the manifest generator)")
for path in set(emb) - set(SRC):
    errs.append(f"UNEXPECTED embedded file: {path}")

if errs:
    print("forge.md self-containment check FAILED:")
    for e in errs:
        print("  -", e)
    sys.exit(1)
print(f"forge.md self-containment OK — {len(emb)} embedded files match their canonical sources.")
