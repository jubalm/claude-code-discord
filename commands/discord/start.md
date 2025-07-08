---
description: Start Discord notifications for this project (channel or thread)
allowed-tools: Bash(python3:*)
---

! # Determine command script paths (local-first, fallback to global)
! if [ -f ".claude/commands/discord/start_handler.py" ]; then
   COMMANDS_BASE=".claude/commands/discord"
 else
   COMMANDS_BASE="$HOME/.claude/commands/discord"
 fi

! # Run the unified Python start handler
! python3 "$COMMANDS_BASE/start_handler.py"