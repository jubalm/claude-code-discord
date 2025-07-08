---
description: Stop Discord notifications for this project
allowed-tools: Bash(python3:*)
---

! if [ -f ".claude/discord-state.json" ]; then
    # Determine command script paths (local-first, fallback to global)
    if [ -f ".claude/commands/discord/update-state.py" ]; then
      COMMANDS_BASE=".claude/commands/discord"
    else
      COMMANDS_BASE="$HOME/.claude/commands/discord"
    fi
    
    python3 "$COMMANDS_BASE/update-state.py" .claude/discord-state.json stop
    echo "🔕 Discord notifications disabled for project: $(basename $(pwd))"
  else
    echo "ℹ️  No Discord configuration found for this project"
  fi

Discord notifications have been **disabled** for this project.

**To re-enable:**
- Use `/user:discord:start` to enable channel notifications
- Use `/user:discord:start THREAD_ID` to enable thread notifications

**Other commands:**
- `/user:discord:status` - Check current state
- `/user:discord:setup` - Reconfigure Discord integration