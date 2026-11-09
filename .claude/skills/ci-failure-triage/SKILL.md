---
name: ci-failure-triage
description: Investigate failed GitHub Actions runs - list runs, read failed job logs, identify the failing step and its root cause, reproduce locally, and narrate the failure. Use whenever a pipeline run fails or the user asks why a check is red.
---

# CI failure triage

## Steps
1. Find the run:
   - `gh pr checks <pr-number>` or `gh run list --branch <branch> --limit 5`
2. Read only what failed:
   - `gh run view <run-id> --log-failed`
   - For the job graph: `gh run view <run-id> --json jobs --jq '.jobs[] | {name, conclusion}'`
3. For each failed job, record: job, step, exit code, the 3-10 most relevant log lines.
4. Classify the root cause: trigger/config, runtime or tool version, dependency, caching, environment variable, code (lint/format/test), build, infrastructure/permissions.
5. Reproduce locally with the same runtime in Docker and the exact command from the workflow to confirm the root cause.
6. Note which downstream jobs were skipped because of this failure.

## Narration (always)
For each failure write three short lines:
- **What the output says:** quote the key line.
- **Root cause:** the actual reason, with evidence.
- **Fix:** what will change and why it resolves the cause.

Then hand over to the `review-and-propose` format and wait for approval before changing anything.
