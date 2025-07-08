---
description: Stop Discord notifications for this project
allowed-tools: Bash(python3:*)
---

! # Determine command script paths (local-first, fallback to global)
! if [ -f ".claude/commands/discord/stop_handler.py" ]; then
   COMMANDS_BASE=".claude/commands/discord"
 else
   COMMANDS_BASE="$HOME/.claude/commands/discord"
 fi

! # Run the unified Python stop handler
! python3 "$COMMANDS_BASE/stop_handler.py"