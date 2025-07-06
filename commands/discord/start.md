---
description: Start Discord notifications for this project (channel or thread)
allowed-tools: Bash(jq:*), Bash(echo:*), Bash(mkdir:*)
---

! mkdir -p .claude

! if [ ! -f ".claude/discord-state.json" ]; then
    echo "❌ Discord not configured for this project"
    echo "Run: /user:discord:setup YOUR_WEBHOOK_URL"
    exit 1
  fi

! if [ -n "$ARGUMENTS" ]; then
    # Update existing config with specific thread ID
    jq --arg thread_id "$ARGUMENTS" '.active = true | .thread_id = $thread_id' .claude/discord-state.json > .claude/discord-state-tmp.json && mv .claude/discord-state-tmp.json .claude/discord-state.json
    echo "✅ Discord notifications enabled for thread: $ARGUMENTS"
  else
    # Enable notifications with existing config
    jq '.active = true' .claude/discord-state.json > .claude/discord-state-tmp.json && mv .claude/discord-state-tmp.json .claude/discord-state.json
    THREAD_ID=$(jq -r '.thread_id // ""' .claude/discord-state.json)
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