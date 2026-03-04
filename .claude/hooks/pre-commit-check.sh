#!/bin/bash

# Pre-commit hook for Claude Code
# Intercepts `git commit` commands and ensures README.md is staged.
# If not, blocks the commit and instructs Claude to update README + write a better message.

# Read tool input JSON from stdin
INPUT=$(cat)

# Extract the bash command being run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only intercept git commit commands (not git add, git status, etc.)
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Check if README.md is in the staged files
if git diff --cached --name-only | grep -q '^README.md$'; then
  # README.md is staged — allow the commit
  exit 0
fi

# README.md is NOT staged — block the commit
echo "COMMIT BLOCKED: README.md is not staged.

Before committing, you MUST:
1. Run \`git diff --cached\` to review all staged changes
2. Update README.md to reflect any significant changes to functionality, configuration, usage, or architecture
3. Write a commit message that summarizes WHAT changed across all files and WHY (not just file names)
4. Stage README.md with \`git add README.md\`
5. Retry the commit with the improved message

Do this automatically without asking the user. If the changes are trivial and README truly doesn't need updating, add a blank line or whitespace change to README.md to acknowledge you reviewed it." >&2

exit 2
