# Project instructions

## Language
All communication, code comments, commit messages, PR descriptions and agent reports are in **English**.

## Project layout
- `codebase/rdicidr-0.1.0/` — React application (rdiCidr), its Dockerfile, nginx config, GitHub Actions workflows and Terraform configuration (`terraform/`).
- `generateZip.sh` / `generateZip.bat` — packaging scripts for the final submission. Do not modify them.
- `.claude/agents/` — specialized subagents. `.claude/skills/` — reusable procedures.

## Team of agents
| Agent | Expertise | Default mode |
|---|---|---|
| `terraform-azure-expert` | Terraform on Azure (Container Apps, Application Gateway, ACR, networking, monitoring, state) | Review, implements only an approved plan |
| `cicd-pipeline-expert` | GitHub Actions CI/CD, Node.js toolchains, pipeline debugging | Review, implements only an approved plan |
| `app-container-expert` | React/Node application, tests, linting, Dockerfile, nginx | Review, implements only an approved plan |
| `azure-security-auditor` | Security across IaC, pipelines, containers and code; secret exposure | Read-only |
| `azure-deployment-verifier` | Post-deployment verification of Azure resources and application health | Read-only |

## Skills
| Skill | Use it to |
|---|---|
| `review-and-propose` | Produce findings and a fix proposal, then ask for approval |
| `git-branching-workflow` | Create the right branch and hand over copy-paste git/PR commands |
| `terraform-plan-local` | Run `terraform plan` locally against a given environment and show the full output |
| `ci-failure-triage` | Read failed GitHub Actions runs and map each failure to a root cause |
| `deploy-and-verify` | Deploy an environment through the CD pipeline and verify it end to end |

## Working agreement (mandatory)
1. **Review first.** Investigate with evidence (file:line, command output, logs). Never guess.
2. **Propose, then wait.** Present findings grouped by topic and a numbered fix plan using the `review-and-propose` skill, and end with an explicit approval question. Do **not** edit any file until the user approves. Reports are always shown in full in the chat (when a subagent reports back, relay its whole report, not a summary); never write them to files.
3. **Branch after approval.** Once approved, create the branch with the `git-branching-workflow` skill (`feature/*` for new capability, `bugfix/*` for defects), always from an up-to-date `devel`.
4. **Implement exactly what was approved.** If something new is discovered mid-way, stop and propose it separately.
5. **Verify.** Run the relevant local checks (lint, tests, build, `terraform fmt/validate/plan`, scanners) and show the results.
6. **Hand over.** Never run `git commit`, `git push`, `gh pr create` or `gh pr merge`. Print the exact commands for the user to copy and paste (see `git-branching-workflow`). Give the commands **one per fenced block**, in order, so the user pastes and runs them one at a time and stops at the first failure; never chain several git commands in one block. Every command starts by changing to the absolute repository path, so it runs in the right folder whichever terminal it is pasted into: `cd "<absolute repository path>"; <command>`. Never stage anything yourself (`git add`, `git mv`, `git rm`); the user's commands do all the staging.
7. **Narrate.** For every failure explain: what the output says, the root cause, and why the fix addresses it.

## Branching strategy
- New work only in `feature/*` or `bugfix/*` branches created from `devel`.
- Changes reach `devel` only through pull requests. No direct pushes to `devel` or `stage`.
- Only `devel` may be merged into `stage`.
- `main` is not a deployment target.

## Security and good practices
- Never print, write, commit or log secrets, keys, tokens, passwords, connection strings or Terraform state contents.
- Prefer OIDC federation and managed identities over stored credentials; apply least privilege for every role assignment.
- Azure identifiers (tenant, subscription, client IDs) are provided through environment/pipeline variables. Never hardcode them in files.
- Terraform: `plan` locally is allowed; `apply`/`destroy` only through the CD pipeline or with explicit user approval for that specific command.
- Pin tool and action versions; keep changes minimal, readable and consistent with the existing style.
