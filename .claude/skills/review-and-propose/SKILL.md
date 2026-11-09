---
name: review-and-propose
description: Standard format for reporting review findings and proposing fixes, ending with an explicit approval request. Use whenever an agent finishes an investigation, before any file is modified.
---

# Review and propose

Use this exact structure. Group by topic (Terraform, CI/CD, Application & Dockerfile, Security, Deployment).

**Where the report goes:** always in the chat, complete. Never write the report to a file. When a subagent produces the report, the main session shows it to the user in full, with every table, and does not shorten it into a summary.

**Keep it compact:** one line per table cell; evidence as a short quote or a command and its key output line, never full logs; no prose that repeats the tables.

## 1. Summary
Two or three sentences: what was reviewed, how (commands, tools, local reproduction), and the overall verdict.

## 2. Findings
One table per topic:

| ID | Severity | File:line | What is wrong (evidence) | Why it fails / impact | Proposed fix |
|---|---|---|---|---|---|

- IDs are prefixed by topic: `TF-1`, `CI-1`, `APP-1`, `SEC-1`, `DEP-1`.
- Severity: Critical (blocks deploy/pipeline), High, Medium, Low, Improvement.
- Evidence is real: a quoted line, a command and its output, a log excerpt. No speculation.

## 3. Proposed plan
A numbered list in execution order. For each item: the finding IDs it resolves, the files that change, the branch it belongs to (`bugfix/<topic>` for defects, `feature/<topic>` for new capability), and how it will be verified.

## 4. Risks and costs
Anything destructive, billable or hard to reverse.

## 5. Approval
End with exactly:

> **Do you approve this plan?** You can approve all items, a subset (e.g. "approve 1, 3"), or ask for changes. Nothing will be modified until you approve.
