---
description: Show Discord integration status for this project
allowed-tools: Bash(python3:*), Bash(cat:*)
---

! if [ -f ".claude/discord-state.json" ]; then
    echo "📊 Discord Status for $(basename $(pwd))"
    echo "=================================="
    
    # Determine command script paths (local-first, fallback to global)
    if [ -f ".claude/commands/discord/read-state.py" ]; then
      COMMANDS_BASE=".claude/commands/discord"
    else
      COMMANDS_BASE="$HOME/.claude/commands/discord"
    fi
    
    ACTIVE=$(python3 "$COMMANDS_BASE/read-state.py" .claude/discord-state.json active false)
    PROJECT_NAME=$(python3 "$COMMANDS_BASE/read-state.py" .claude/discord-state.json project_name unknown)
    THREAD_ID=$(python3 "$COMMANDS_BASE/read-state.py" .claude/discord-state.json thread_id)
    HAS_AUTH=$(python3 "$COMMANDS_BASE/read-state.py" .claude/discord-state.json auth_token)
    
    echo "Project: $PROJECT_NAME"
    echo "Status: $([ "$ACTIVE" = "true" ] && echo "🟢 Active" || echo "🔴 Disabled")"
    
    if [ -n "$THREAD_ID" ] && [ "$THREAD_ID" != "" ]; then
      echo "Target: 🧵 Thread ($THREAD_ID)"
    else
      echo "Target: 📢 Channel"
    fi
    
    if [ -n "$HAS_AUTH" ] && [ "$HAS_AUTH" != "" ]; then
      echo "Auth: 🔐 Configured"
    else
      echo "Auth: ❌ Not configured"
    fi
    
    echo ""
    echo "Hooks configured: $([ -f ".claude/settings.json" ] && echo "✅ Yes" || echo "❌ No")"
    echo "Installation: $([ -f ".claude/hooks/stop-discord.py" ] && echo "📍 Local (project-specific)" || echo "🌐 Global (multi-project)")"
    
  else
    echo "ℹ️  No Discord integration configured for $(basename $(pwd))"
    echo ""
    echo "To get started:"
    echo "• /user:discord:setup YOUR_WEBHOOK_URL - Setup Discord integration"
  fi

**Available Commands:**
- `/user:discord:setup WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID]` - Setup Discord integration
- `/user:discord:start [THREAD_ID]` - Enable notifications
- `/user:discord:stop` - Disable notifications