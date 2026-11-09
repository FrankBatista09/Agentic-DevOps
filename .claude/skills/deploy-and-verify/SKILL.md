---
name: deploy-and-verify
description: Deploy an environment (devel or stage) through the CD pipeline following the branching strategy, watch the run, and verify the result end to end with the azure-deployment-verifier agent. Use when the user asks to deploy, promote or check an environment.
---

# Deploy and verify

## Deployment model
- Deployments happen through the CD pipeline, triggered by changes reaching the environment branch (`devel` or `stage`) via an approved and merged PR.
- Local `terraform apply` is not the normal path. Only run it if the user explicitly approves that exact command.

## Before deploying
1. Make sure the user has seen the plan for the target environment: the plan job on the PR, or the `terraform-plan-local` skill if no plan was reviewed yet.
2. Confirm the GitHub environment and its variables exist: `gh api repos/{owner}/{repo}/environments` and `gh variable list --env <env>` (names only, values are not printed).

## Deploying
1. For `devel`: the user merges the approved feature/bugfix PR into `devel`.
2. For `stage`: hand over the promotion PR command (`devel` -> `stage`) from the `git-branching-workflow` skill; the user merges it.
3. Find the run: `gh run list --workflow <cd workflow> --branch <env> --limit 1`.
4. The GitHub environments require the user's approval. When the run shows a deployment waiting for review, tell the user to approve it in Actions (Review deployments -> environment -> Approve and deploy). Never approve a deployment on the user's behalf.
5. Watch the run in the background (`gh run watch <run-id> --exit-status` as a background command), so the conversation stays free while Azure provisions. Do not poll with sleep loops in the foreground. Report when it finishes.
6. If it fails, use the `ci-failure-triage` skill.

## Verifying
Invoke the `azure-deployment-verifier` agent for the environment and present its PASS/FAIL table, the public URL, and the evidence that the health check passes consistently.

## Cost reminder
Remind the user which resources bill hourly and how to tear the environment down when it is no longer needed (only with explicit approval).
