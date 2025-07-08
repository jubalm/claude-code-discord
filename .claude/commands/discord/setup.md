---
description: Setup Discord integration for this project (configurable and non-destructive)
allowed-tools: Bash(python3:*), Bash(echo:*), Bash(mkdir:*), Bash(cat:*), Bash(read:*)
---

! mkdir -p .claude

! echo "🔧 Discord Integration Setup for $(basename $(pwd))"
! echo "========================================"
! echo ""

! # Get webhook URL
! if [ -n "$ARGUMENTS" ]; then
    WEBHOOK_URL=$(echo "$ARGUMENTS" | awk '{print $1}')
    echo "Using provided webhook URL"
  else
    echo "Please provide your Discord webhook URL as an argument:"
    echo "Example: /user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"
    echo ""
    echo "Or run: /user:discord:setup YOUR_WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID]"
    exit 1
  fi

! # Parse additional arguments
! AUTH_TOKEN=$(echo "$ARGUMENTS" | awk '{print $2}')
! THREAD_ID=$(echo "$ARGUMENTS" | awk '{print $3}')

! # Validate webhook URL
! if [[ ! "$WEBHOOK_URL" =~ ^https://discord\.com/api/webhooks/ ]]; then
    echo "❌ Invalid webhook URL. Must start with: https://discord.com/api/webhooks/"
    exit 1
  fi

! # Create/update discord-state.json
! if [ -n "$AUTH_TOKEN" ] && [ -n "$THREAD_ID" ]; then
    cat > .claude/discord-state.json << EOF
{
  "active": false,
  "webhook_url": "$WEBHOOK_URL",
  "project_name": "$(basename $(pwd))",
  "auth_token": "$AUTH_TOKEN",
  "thread_id": "$THREAD_ID"
}
EOF
  elif [ -n "$AUTH_TOKEN" ]; then
    cat > .claude/discord-state.json << EOF
{
  "active": false,
  "webhook_url": "$WEBHOOK_URL",
  "project_name": "$(basename $(pwd))",
  "auth_token": "$AUTH_TOKEN"
}
EOF
  elif [ -n "$THREAD_ID" ]; then
    cat > .claude/discord-state.json << EOF
{
  "active": false,
  "webhook_url": "$WEBHOOK_URL",
  "project_name": "$(basename $(pwd))",
  "thread_id": "$THREAD_ID"
}
EOF
  else
    cat > .claude/discord-state.json << EOF
{
  "active": false,
  "webhook_url": "$WEBHOOK_URL",
  "project_name": "$(basename $(pwd))"
}
EOF
  fi

! # Determine command script paths (local-first, fallback to global)
! if [ -f ".claude/commands/discord/merge-settings.py" ]; then
    COMMANDS_BASE=".claude/commands/discord"
    HOOKS_BASE=".claude/hooks"
  else
    COMMANDS_BASE="$HOME/.claude/commands/discord"
    HOOKS_BASE="$HOME/.claude/hooks"
  fi

! # Setup hooks configuration (preserve existing settings)
! if [ -f ".claude/settings.json" ]; then
    echo "Existing .claude/settings.json found - merging Discord hooks..."
    
    # Create backup
    cp .claude/settings.json .claude/settings.json.backup
    
    # Merge Discord hooks with existing configuration
    python3 "$COMMANDS_BASE/merge-settings.py" .claude/settings.json
    
    echo "✅ Discord hooks merged with existing configuration"
    echo "📁 Backup saved as .claude/settings.json.backup"
  else
    echo "Creating new .claude/settings.json..."
    
    cat > .claude/settings.json << EOF
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOKS_BASE/stop-discord.py"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOKS_BASE/notification-discord.py"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOKS_BASE/posttooluse-discord.py"
          }
        ]
      }
    ]
  }
}
EOF
    
    echo "✅ New .claude/settings.json created"
  fi

! echo ""
! echo "✅ Discord integration setup complete!"
! echo ""
! echo "📊 Configuration Summary:"
! echo "  Project: $(basename $(pwd))"
! echo "  Webhook: $(echo "$WEBHOOK_URL" | sed 's/\(.*webhooks\/[0-9]*\).*/\1.../')"
! [ -n "$AUTH_TOKEN" ] && echo "  Auth: ✅ Configured" || echo "  Auth: ❌ Not configured"
! [ -n "$THREAD_ID" ] && echo "  Thread: $THREAD_ID" || echo "  Thread: Channel mode"
! echo "  Status: 🔴 Disabled (run /user:discord:start to enable)"
! echo ""
! echo "🎯 Next Steps:"
! if [ -f ".claude/hooks/stop-discord.py" ]; then
    echo "  1. /user:discord:start - Enable Discord notifications"
    echo "  2. Start working - notifications will be sent automatically!"
    echo ""
    echo "💡 Commands Available:"
    echo "  /user:discord:start [THREAD_ID] - Enable notifications"
    echo "  /user:discord:stop - Disable notifications"
    echo "  /user:discord:status - Show current status"
    echo "  /user:discord:remove - Remove integration"
    echo ""
    echo "📍 Installation: Local (project-specific)"
  else
    echo "  1. /user:discord:start - Enable Discord notifications"
    echo "  2. Start working - notifications will be sent automatically!"
    echo ""
    echo "💡 Commands Available:"
    echo "  /user:discord:start [THREAD_ID] - Enable notifications"
    echo "  /user:discord:stop - Disable notifications"
    echo "  /user:discord:status - Show current status"
    echo "  /user:discord:remove - Remove project integration"
    echo ""
    echo "📍 Installation: Global (multi-project)"
  fi