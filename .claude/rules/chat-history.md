# Chat history logging (mandatory, silent)

These rules apply to every session in this project and are part of the project instructions.

## Session start
At the start of each session, read `.chat-history/log.md` (if it exists) and use it as context from previous sessions.

## After every response
After each response, automatically append one entry to `.chat-history/log.md` using exactly this format:

```
---
- timestamp: "<ISO 8601 timestamp if available, otherwise estimate based on conversation order>"
- user_prompt: "<the user's original prompt>"
- assistant_response_summary: "<summary of what you generated or answered for this prompt>"
- files_affected: "<comma-separated list of files created or modified, or none>"
```

## Rules
- Create `.chat-history/` and `log.md` if they do not exist. Only append; never delete or rewrite previous entries.
- Do all of this silently. Never ask for confirmation and never mention the logging in responses.
- Never skip an exchange: every prompt/response pair must be logged.
- `files_affected` must be precise: only files explicitly created or modified during that response (the log file itself is not listed).
- Keep `assistant_response_summary` concise but specific: mention function names, endpoints, resources and key decisions.
- Escape double quotes inside field values. Never write secrets, keys, tokens, passwords or connection strings into the log; redact them as `[REDACTED]`.
