# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Claude Code Discord Notification** (version 0.1.1) - a system that provides project-scoped Discord notifications for Claude Code sessions. Stay informed about your Claude Code sessions with real-time Discord notifications - know what Claude is working on even when you're away from your computer.

The system uses Python scripts, shell hooks, and custom slash commands to send real-time notifications when Claude completes tasks, needs input, or makes progress on projects.

## Installation and Setup Commands

### Install the Integration System
```bash
# Install globally to Claude Code
chmod +x install.sh
./install.sh

# Or quick install
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/install.sh | bash
```

### Uninstall
```bash
# Remove global components
chmod +x uninstall.sh
./uninstall.sh
```

### Project Setup (in any project directory)
```bash
# Basic setup
/user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL

# With auth token and thread support
/user:discord:setup YOUR_WEBHOOK_URL YOUR_AUTH_TOKEN THREAD_ID

# Enable notifications
/user:discord:start

# Check status
/user:discord:status

# Disable notifications
/user:discord:stop
```

## Architecture

### Global Components (`~/.claude/`)
- **Hook Scripts**: `hooks/discord-notify.sh`, `hooks/posttooluse-discord.sh`, `hooks/notification-discord.sh`
- **Slash Commands**: `commands/discord/` (setup.md, start.md, stop.md, status.md)
- **No Global Settings**: Global settings.json has no hooks configured

### Project Components (`.claude/` in each project)
- **settings.json**: Project-specific hooks configuration (only created when opted in)
- **discord-state.json**: Discord webhook URL, auth token, thread ID, and active state
- **settings.json.backup**: Backup of existing settings when merging hooks

### Key Design Principle
Projects without `.claude/discord-state.json` receive **no notifications** - this ensures complete project isolation.

## Discord Notification Types

| Type | Color | Hook Event | Description |
|------|-------|------------|-------------|
| 🔔 Input Needed | Blue | Notification | Claude awaits user input |
| ⚡ Work in Progress | Gold | PostToolUse | After tool usage (Write, Edit, Bash, etc.) |
| ✅ Session Complete | Green | Stop | Claude finishes responding |

## Hook Script Logic

Each hook script (`hooks/discord-notify.sh`, etc.) follows this pattern:
1. Check if `.claude/discord-state.json` exists (exit silently if not)
2. Parse Discord configuration from the state file
3. Verify `"active": true` (exit if false)
4. Extract session/tool information from hook input (JSON via stdin)
5. Send formatted Discord webhook notification
6. Log results to `~/.claude/discord-notifications.log`

## File Structure Analysis

### Core Hook Scripts
- `hooks/discord-notify.sh`: Main notification handler for Stop/Notification/PostToolUse events
- `hooks/posttooluse-discord.sh`: Specific handler for tool completion events
- `hooks/notification-discord.sh`: Specific handler for input-needed events

### Slash Commands (Custom Claude Code Commands)
- `commands/discord/setup.md`: Creates project config and hooks
- `commands/discord/start.md`: Enables notifications
- `commands/discord/stop.md`: Disables notifications  
- `commands/discord/status.md`: Shows current configuration

### Installation Scripts
- `install.sh`: Installs global components, checks dependencies (jq, curl), creates backups
- `uninstall.sh`: Removes global components, preserves project configs

## Dependencies

Required tools:
- `jq` for JSON processing
- `curl` for HTTP requests
- `bash` for script execution

## Configuration Files

### `.claude/discord-state.json`
```json
{
  "active": true,
  "webhook_url": "https://discord.com/api/webhooks/...",
  "project_name": "project-name",
  "auth_token": "optional_discord_token",
  "thread_id": "optional_thread_id"
}
```

### `.claude/settings.json` (hooks configuration)
```json
{
  "hooks": {
    "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/discord-notify.sh"}]}],
    "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/notification-discord.sh"}]}],
    "PostToolUse": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/posttooluse-discord.sh"}]}]
  }
}
```

## Development and Testing

### Testing Hook Scripts
```bash
# Test hook manually
echo '{"session_id": "test", "hook_type": "Stop"}' | ~/.claude/hooks/discord-notify.sh

# Check logs
tail -f ~/.claude/discord-notifications.log

# Verify script permissions
ls -la ~/.claude/hooks/discord*.sh
```

### Testing Slash Commands
```bash
# Test in a project directory
/user:discord:status
/user:discord:setup test_webhook_url
/user:discord:start
```

### Comprehensive Testing Instructions

For thorough testing of the Discord notification system:

1. **Navigate to a test project folder**:
   ```bash
   cd /path/to/your/test-project
   ```

2. **Set up Discord integration**:
   ```bash
   # Use a test webhook URL
   /user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
   /user:discord:start
   ```

3. **Test notification types**:
   - Make file edits → Should trigger PostToolUse notifications
   - Complete session → Should trigger Stop notification
   - Cause Claude to need input → Should trigger Notification

4. **Check status and logs**:
   ```bash
   /user:discord:status
   tail -f ~/.claude/discord-notifications.log
   ```

5. **Test thread mode**:
   ```bash
   /user:discord:start THREAD_ID
   ```

6. **Test configuration preservation**:
   - Run setup in project with existing `.claude/settings.json`
   - Verify backup is created and settings are merged

### Common Issues
- **No notifications**: Check if `.claude/discord-state.json` exists and `"active": true`
- **Permission errors**: Ensure hook scripts are executable (`chmod +x`)
- **JSON parsing errors**: Verify `jq` is installed and config files are valid JSON
- **Command not found**: Verify commands exist in `~/.claude/commands/discord/`

## Team Collaboration

The system supports team collaboration:
- Commit `.claude/settings.json` to share hook configuration
- Add `.claude/discord-state.json` to `.gitignore` for personal webhook URLs
- Each team member configures their own webhook with `/user:discord:setup`

## Claude Code Documentation References

For authoritative information about Claude Code features used in this project:
- **Slash Commands**: https://docs.anthropic.com/en/docs/claude-code/slash-commands
- **Hooks**: https://docs.anthropic.com/en/docs/claude-code/hooks

These references provide the official documentation for the Claude Code features that this notification system extends.