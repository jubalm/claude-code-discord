---
description: Remove Discord integration from this project
allowed-tools: Bash(rm:*), Bash(python3:*), Bash(cat:*), Bash(echo:*)
---

! if [ ! -f ".claude/discord-state.json" ]; then
    echo "ℹ️  No Discord integration found in this project"
    echo ""
    echo "Current project: $(basename $(pwd))"
    echo "Status: Not configured"
    echo ""
    echo "To set up Discord integration:"
    echo "• /user:discord:setup WEBHOOK_URL - Configure Discord integration"
    exit 0
  fi

! # Show current configuration
! echo "🗑️  Discord Integration Removal for $(basename $(pwd))"
! echo "=================================================="
! echo ""

! # Get current state
! ACTIVE=$(python3 "$HOME/.claude/commands/discord/read-state.py" .claude/discord-state.json active false)
! PROJECT_NAME=$(python3 "$HOME/.claude/commands/discord/read-state.py" .claude/discord-state.json project_name unknown)
! WEBHOOK_URL=$(python3 "$HOME/.claude/commands/discord/read-state.py" .claude/discord-state.json webhook_url)

! echo "📊 Current Configuration:"
! echo "  Project: $PROJECT_NAME"
! echo "  Status: $([ "$ACTIVE" = "true" ] && echo "🟢 Active" || echo "🔴 Disabled")"
! echo "  Webhook: $(echo "$WEBHOOK_URL" | sed 's/\(.*webhooks\/[0-9]*\).*/\1.../' 2>/dev/null || echo 'Not configured')"
! echo "  Hooks: $([ -f ".claude/settings.json" ] && echo "✅ Configured" || echo "❌ Not configured")"
! echo ""

! # Warning and confirmation
! echo "⚠️  WARNING: This will remove Discord integration from this project:"
! echo "  • Delete .claude/discord-state.json"
! echo "  • Remove Discord hooks from .claude/settings.json"
! echo "  • Preserve other hooks and settings"
! echo ""
! echo "Global Discord components (in ~/.claude/) will NOT be affected."
! echo ""

! # Simple confirmation (no interactive read in Claude Code)
! echo "🔄 Proceeding with removal..."
! echo ""

! # Create backup of settings.json
! if [ -f ".claude/settings.json" ]; then
    echo "📁 Creating backup of settings.json..."
    cp .claude/settings.json .claude/settings.json.backup-$(date +%Y%m%d-%H%M%S)
    echo "✅ Backup created"
  fi

! # Remove discord-state.json
! if [ -f ".claude/discord-state.json" ]; then
    rm -f .claude/discord-state.json
    echo "✅ Removed discord-state.json"
  fi

! # Remove Discord hooks from settings.json while preserving other hooks
! if [ -f ".claude/settings.json" ]; then
    echo "🔧 Removing Discord hooks from settings.json..."
    
    # Use Python to remove only Discord hooks
    python3 -c "
import json
import sys

try:
    with open('.claude/settings.json', 'r') as f:
        settings = json.load(f)
    
    if 'hooks' in settings:
        # Remove Discord hooks while preserving others
        hooks = settings['hooks']
        
        # Remove Stop hooks that point to Discord
        if 'Stop' in hooks:
            hooks['Stop'] = [h for h in hooks['Stop'] if not any('discord' in hook.get('command', '') for hook in h.get('hooks', []))]
            if not hooks['Stop']:
                del hooks['Stop']
        
        # Remove Notification hooks that point to Discord  
        if 'Notification' in hooks:
            hooks['Notification'] = [h for h in hooks['Notification'] if not any('discord' in hook.get('command', '') for hook in h.get('hooks', []))]
            if not hooks['Notification']:
                del hooks['Notification']
        
        # Remove PostToolUse hooks that point to Discord
        if 'PostToolUse' in hooks:
            hooks['PostToolUse'] = [h for h in hooks['PostToolUse'] if not any('discord' in hook.get('command', '') for hook in h.get('hooks', []))]
            if not hooks['PostToolUse']:
                del hooks['PostToolUse']
    
    # Write back the cleaned settings
    with open('.claude/settings.json', 'w') as f:
        json.dump(settings, f, indent=2)
    
    print('✅ Discord hooks removed from settings.json')

except Exception as e:
    print(f'❌ Error updating settings.json: {e}')
    sys.exit(1)
"
    
  else
    echo "ℹ️  No settings.json file found"
  fi

! echo ""
! echo "=================================================="
! echo "✅ Discord integration removal completed!"
! echo "=================================================="
! echo ""
! echo "📊 What was removed:"
! echo "  • .claude/discord-state.json (Discord configuration)"
! echo "  • Discord hooks from .claude/settings.json"
! echo ""
! echo "📁 What was preserved:"
! echo "  • Other hooks in .claude/settings.json"
! echo "  • Global Discord components in ~/.claude/"
! echo "  • Backup of settings.json created"
! echo ""
! echo "🔄 To re-enable Discord integration:"
! echo "  • /user:discord:setup WEBHOOK_URL - Reconfigure"
! echo ""
! echo "🗑️  To completely remove global Discord components:"
! echo "  • Run ./uninstall.sh from the claude-discord-integration directory"