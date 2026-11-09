---
name: git-branching-workflow
description: Branching strategy for this repository and the hand-off procedure. Use after the user approves a plan (to create the right branch) and after the changes are implemented and verified (to print copy-paste commit, push and PR commands). Also use for promoting devel to stage.
---

# Git branching workflow

## Rules
- Commands for the user go **one per fenced block**, in order, each written as `cd "<absolute path to repository root>"; <command>`, so the user runs them one at a time and stops at the first failure. Never put several commands in one block.
- Branches: `feature/<short-kebab-topic>` for new capability, `bugfix/<short-kebab-topic>` for defects.
- Always branch from an up-to-date `devel`.
- `devel` receives changes only through PRs from `feature/*` or `bugfix/*`.
- `stage` receives changes only through a PR from `devel`.
- Never push directly to `devel` or `stage`. Never force-push shared branches.
- The agent never runs `git commit`, `git push`, `gh pr create` or `gh pr merge`. The user runs them.
- The agent never stages anything (`git add`, `git mv`, `git rm`). To move or delete a file, use plain file operations, so every change stays unstaged and is staged only by the user's `git add`.

## Step 1 - Create the branch (after approval)
Check the working tree with `git status`.

The chat history log is expected to be dirty: `.chat-history/log.md` is appended after every response, and the logging setup itself adds `.chat-history/` and a section to `CLAUDE.md`. These changes are not "previous work": carry them into the new branch without asking.

1. Create the branch, letting git carry the uncommitted changes:
   ```bash
   git switch devel
   git pull --ff-only origin devel
   git switch -c <feature|bugfix>/<topic>
   ```
2. Only if `git switch` or `git pull` refuses because of those local changes, wrap the same commands with `git stash push --include-untracked -- .chat-history CLAUDE.md` before and `git stash pop` after.
3. If any other file is modified, stop and ask the user how to proceed.

## Step 2 - Hand-off (after implementation and verification)
Show `git status` and a short diff summary, then print the commands **one per fenced block**, in this order, each starting with `cd` to the absolute repository path. Use a Conventional Commits message that explains the why:

```bash
cd "<absolute path to repository root>"; git add -A -- <paths>
```
```bash
cd "<absolute path to repository root>"; git status
```
(The user checks that every intended file is staged before committing.)
```bash
cd "<absolute path to repository root>"; git commit -m "<type>(<scope>): <summary>" -m "<what was wrong, root cause, how it is fixed>"
```
```bash
cd "<absolute path to repository root>"; git push -u origin <branch>
```
```bash
cd "<absolute path to repository root>"; gh pr create --base devel --head <branch> --title "<type>(<scope>): <summary>" --body "<findings fixed, root causes, verification performed>"
```
The blocks above are templates. Every command you print must be complete and ready to run: the real absolute repository path, the real file list, the real branch name, and a real commit message, PR title and PR body written for this change. Never leave a `<placeholder>` in a command.

If the branch already has an open PR (`gh pr view <branch>` succeeds), skip the `gh pr create` block: the push updates that PR and re-runs its checks.

Always include `.chat-history/log.md` (and, the first time, `CLAUDE.md` with the logging section) in the `git add` list so the interaction log travels with every change. Build the `git add` list from `git status --porcelain` and use `git add -A -- <paths>`, so new, modified, moved and deleted files are all staged (for a moved file, list both the old and the new path). A path that is not in the index or the working tree makes the whole `git add` fail and leaves the commit incomplete, so never list one. Prefer explicit paths over `git add .` so nothing unintended is committed. Never include secrets, `.terraform/`, state or plan files.

## Promotion to stage
After `devel` is verified:
```bash
cd "<absolute path to repository root>"; gh pr create --base stage --head devel --title "release: promote devel to stage" --body "<changes being promoted and devel verification evidence>"
```

## After the user pushes
Offer to watch the checks with `gh pr checks <number> --watch` and to triage failures with the `ci-failure-triage` skill.
