---
description: Remove Discord integration from this project
allowed-tools: Bash(python3:*)
---

! # Determine command script paths (local-first, fallback to global)
! if [ -f ".claude/commands/discord/remove_handler.py" ]; then
   COMMANDS_BASE=".claude/commands/discord"
 else
   COMMANDS_BASE="$HOME/.claude/commands/discord"
 fi

! # Run the unified Python remove handler
! python3 "$COMMANDS_BASE/remove_handler.py"