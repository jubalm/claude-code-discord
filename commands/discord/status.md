---
description: Show Discord integration status for this project
allowed-tools: Bash(python3:*)
---

! # Determine command script paths (local-first, fallback to global)
! if [ -f ".claude/commands/discord/status_handler.py" ]; then
   COMMANDS_BASE=".claude/commands/discord"
 else
   COMMANDS_BASE="$HOME/.claude/commands/discord"
 fi

! # Run the unified Python status handler
! python3 "$COMMANDS_BASE/status_handler.py"