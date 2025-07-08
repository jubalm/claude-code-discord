---
description: Setup Discord integration for this project (configurable and non-destructive)
allowed-tools: Bash(python3:*)
---

! # Determine command script paths (local-first, fallback to global)
! if [ -f ".claude/commands/discord/setup_handler.py" ]; then
   COMMANDS_BASE=".claude/commands/discord"
 else
   COMMANDS_BASE="$HOME/.claude/commands/discord"
 fi

! # Run the unified Python setup handler
! python3 "$COMMANDS_BASE/setup_handler.py"