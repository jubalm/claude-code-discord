---
description: Start Discord notifications for this project (channel or thread)
allowed-tools: Bash(python3:*), Bash(echo:*), Bash(mkdir:*)
---

! mkdir -p .claude

! if [ ! -f ".claude/discord-state.json" ]; then
    echo "❌ Discord not configured for this project"
    echo "Run: /user:discord:setup YOUR_WEBHOOK_URL"
    exit 1
  fi

! # Determine command script paths (local-first, fallback to global)
! if [ -f ".claude/commands/discord/update-state.py" ]; then
    COMMANDS_BASE=".claude/commands/discord"
  else
    COMMANDS_BASE="$HOME/.claude/commands/discord"
  fi

! if [ -n "$ARGUMENTS" ]; then
    # Update existing config with specific thread ID
    python3 "$COMMANDS_BASE/update-state.py" .claude/discord-state.json start "$ARGUMENTS"
    echo "✅ Discord notifications enabled for thread: $ARGUMENTS"
  else
    # Enable notifications with existing config
    python3 "$COMMANDS_BASE/update-state.py" .claude/discord-state.json start
    THREAD_ID=$(python3 "$COMMANDS_BASE/update-state.py" .claude/discord-state.json get_thread_id)
    if [ -n "$THREAD_ID" ] && [ "$THREAD_ID" != "" ]; then
      echo "✅ Discord notifications enabled for thread: $THREAD_ID"
    else
      echo "✅ Discord notifications enabled for channel"
    fi
  fi

Discord notifications are now active for project: **$(basename $(pwd))**

**Usage:**
- `/user:discord:start` - Post to main channel
- `/user:discord:start THREAD_ID` - Post to specific thread
- `/user:discord:stop` - Disable notifications
- `/user:discord:status` - Check current state

**Other commands:**
- `/user:discord:stop` - Disable notifications
- `/user:discord:status` - Check current state
- `/user:discord:setup` - Reconfigure Discord integration
- `/user:discord:remove` - Remove integration

**Installation type:** $([ -f ".claude/hooks/stop-discord.py" ] && echo "📍 Local (project-specific)" || echo "🌐 Global (multi-project)")