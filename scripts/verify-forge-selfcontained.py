#!/usr/bin/env python3
# Proves forge.md is self-contained: with ONLY forge.md available, extract every
# embedded file, fill placeholders, install, and run the proofs. This is the
# dogfood, runnable in CI — it catches manifest-format regressions and any
# embedded script that no longer works.
import os, re, shutil, stat, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FORGE = os.path.join(ROOT, "forge.md")
SUBST = {"{{PROJECT_NAME}}": "demo-app",
         "{{ONE_LINE_PURPOSE}}": "A demo application.",
         "{{OWNER_EMAIL}}": "owner@example.com"}
EXPECTED = 14

def fail(msg):
    print("SELF-CONTAINED CHECK FAILED:", msg); sys.exit(1)

out = tempfile.mkdtemp(prefix="forge-selfcontained-")
lines = open(FORGE).read().splitlines(keepends=True)
files, i, n = [], 0, len(lines)
while i < n:
    m = re.match(r"^### FILE: (.+?)  \(([^)]*)\)\s*$", lines[i])
    if not m:
        i += 1; continue
    path, kind = m.group(1).strip(), m.group(2)
    if not lines[i + 1].startswith("````"):
        fail(f"no fence after {path}")
    k, body = i + 2, []
    while k < n and lines[k].rstrip("\n") != "````":
        body.append(lines[k]); k += 1
    text = "".join(body)
    if "fill" in kind:
        for a, b in SUBST.items():
            text = text.replace(a, b)
    full = os.path.join(out, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    open(full, "w").write(text)
    files.append(path)
    i = k + 1

if len(files) != EXPECTED:
    fail(f"expected {EXPECTED} embedded files, extracted {len(files)}: {files}")

for p in files:
    if p.endswith((".sh", ".mjs", "pre-commit", "pre-push")):
        fp = os.path.join(out, p); os.chmod(fp, os.stat(fp).st_mode | 0o755)

def run(cmd, **kw):
    return subprocess.run(cmd, cwd=out, capture_output=True, text=True, **kw)

# syntax-check every extracted script
for p in files:
    if p.endswith((".sh",)) or p.endswith(("pre-commit", "pre-push")):
        if run(["bash", "-n", p]).returncode != 0:
            fail(f"bash -n {p}")
    if p.endswith(".mjs") and run(["node", "--check", p]).returncode != 0:
        fail(f"node --check {p}")

# install + run the enforcement proof
run(["git", "init", "-b", "main", "-q"]); run(["git", "config", "user.email", "d@e.x"]); run(["git", "config", "user.name", "d"])
open(os.path.join(out, ".seed"), "w").write("x\n")
run(["git", "add", "-A"]); run(["git", "commit", "-qm", "seed"])
for h in ("pre-commit", "pre-push"):
    shutil.copy(os.path.join(out, "governance/hooks", h), os.path.join(out, ".git/hooks", h))
    os.chmod(os.path.join(out, ".git/hooks", h), 0o755)

sv = run(["bash", "scripts/self-verify.sh"])
if sv.returncode != 0 or "PASS" not in sv.stdout:
    fail("self-verify did not pass:\n" + sv.stdout + sv.stderr)

open(os.path.join(out, ".seed"), "a").write("y\n"); run(["git", "add", "-A"])
if run(["git", "commit", "-m", "direct on main"]).returncode == 0:
    fail("pre-commit allowed a direct commit on main")
run(["git", "switch", "-qc", "feat/x"])
if run(["git", "commit", "-qm", "on feature"]).returncode != 0:
    fail("pre-commit blocked a legitimate feature-branch commit")

shutil.rmtree(out, ignore_errors=True)
print(f"forge.md self-contained OK — {len(files)} files extracted from forge.md alone, "
      "syntax-checked, self-verify passed, git hard tier blocks main / allows feature.")
