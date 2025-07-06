---
description: Stop Discord notifications for this project
allowed-tools: Bash(jq:*)
---

! if [ -f ".claude/discord-state.json" ]; then
    jq '.active = false' .claude/discord-state.json > .claude/discord-state-tmp.json && mv .claude/discord-state-tmp.json .claude/discord-state.json
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