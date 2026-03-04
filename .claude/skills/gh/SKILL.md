---
name: gh
description: Commit all changes locally and push to GitHub. Use when the user wants to save their work, commit and push, or ship code to GitHub.
disable-model-invocation: true
---

# Commit and Push to GitHub

Commit all current changes and push to the remote GitHub repository.

## Steps

1. Run `git status` to see all changed and untracked files. Never use the `-uall` flag.
2. Run `git diff` to review staged and unstaged changes.
3. Run `git log --oneline -5` to see recent commit message style.
4. Stage all relevant files (prefer explicit file names over `git add -A`). Do NOT stage files that likely contain secrets (`.env`, credentials, etc.).
5. Write a concise commit message that explains **intent** (the "why"), not mechanics. Follow the repository's existing commit message style. End with:
   ```
   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   ```
6. Run `git push` to push the commit to GitHub. If the current branch has no upstream, use `git push -u origin <branch>`.
7. Confirm success by showing the final `git status` and the pushed commit hash.

## Important

- If there are no changes to commit, say so and stop — do not create empty commits.
- Never force push.
- Never skip hooks (`--no-verify`).
- Always use a HEREDOC for the commit message to preserve formatting.
- If a pre-commit hook fails, fix the issue and create a NEW commit (do not amend).
