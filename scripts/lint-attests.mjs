#!/usr/bin/env node
// charter-forge :: lint-attests.mjs
//
// Validates governance commit trailers in recent history. Pure Node + git,
// zero network, zero server. WARN-MODE BY DEFAULT (always exits 0) so it is
// safe to add to CI without breaking existing PRs; pass --fail to make a
// malformed trailer fail the build once your team has adopted the convention.
//
// Default vendor-neutral grammar:
//     Governed-By: <RULE-ID>
// If you connect Dictiva, it also accepts the richer attestation grammar:
//     Attests: <RULE-ID> tier=T<N> evidence=<kind>=<ref>[,<kind>=<ref>...]
//
// Usage:  node scripts/lint-attests.mjs [--range <git-range>] [--fail]
//   --range   git log range to scan (default: last 50 commits)
//   --fail    exit 1 on any malformed trailer (default: warn only, exit 0)

import { execSync } from "node:child_process";

const args = process.argv.slice(2);
const FAIL = args.includes("--fail");
const rangeIdx = args.indexOf("--range");
const RANGE = rangeIdx !== -1 ? args[rangeIdx + 1] : "-50";

const GOVERNED_BY = /^Governed-By:\s*([A-Z][A-Z0-9-]*(?:-\d+)?)\s*$/;
const ATTESTS = /^Attests:\s*([A-Z][A-Z0-9-]*(?:-\d+)?)\s+tier=T([1-6])\s+evidence=(\S+)\s*$/;

function git(cmd) {
  try {
    return execSync(`git ${cmd}`, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
  } catch {
    return "";
  }
}

// Resolve the commit list. Tolerate an empty / brand-new repo gracefully.
const log = git(`log ${RANGE} --format=%H`).trim();
if (!log) {
  console.log("charter-forge lint-attests: no commits to scan — ok.");
  process.exit(0);
}
const commits = log.split("\n").filter(Boolean);

let trailers = 0;
const problems = [];

for (const sha of commits) {
  const body = git(`show -s --format=%B ${sha}`);
  for (const rawLine of body.split("\n")) {
    const line = rawLine.trim();
    if (!/^(Governed-By|Attests):/.test(line)) continue;
    trailers++;
    if (GOVERNED_BY.test(line) || ATTESTS.test(line)) continue;
    problems.push({ sha: sha.slice(0, 8), line });
  }
}

console.log(
  `charter-forge lint-attests: scanned ${commits.length} commit(s), ` +
    `found ${trailers} governance trailer(s), ${problems.length} malformed.`
);

for (const p of problems) {
  console.log(`  ${FAIL ? "ERROR" : "warn"} ${p.sha}: malformed trailer -> "${p.line}"`);
}

if (problems.length && FAIL) {
  console.error("charter-forge lint-attests: failing (--fail set).");
  process.exit(1);
}
process.exit(0);
