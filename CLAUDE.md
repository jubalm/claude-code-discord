# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Claude Code Discord Notification** (version 0.3.0) - a **local-first** Discord notification system for Claude Code sessions. Stay informed about your coding sessions with real-time Discord notifications - know what Claude is working on even when you're away from your computer.

**Local-First Architecture**: By default, Discord integration installs directly to your current project (`.claude/` directory), making setup simple and self-contained. Advanced users can optionally install globally for multi-project workflows.

The system uses Python scripts, shell hooks, and custom slash commands to send real-time notifications when Claude completes tasks, needs input, or makes progress on projects.

## Installation and Setup Commands

### 🚀 Quick Start (Local Installation - Recommended)
```bash
# Navigate to your project directory
cd my-awesome-project

# One-command install (local to current project)
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/install.sh | bash

# Setup Discord integration
/user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL

# Start receiving notifications
/user:discord:start
```

### 🌐 Advanced Setup (Global Installation)
```bash
# Install globally for multi-project use
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/install.sh | bash -s -- --global

# Then in each project:
cd project1
/user:discord:setup YOUR_WEBHOOK_URL
/user:discord:start

cd project2
/user:discord:setup YOUR_WEBHOOK_URL
/user:discord:start
```

### 🗑️ Uninstall Options
```bash
# Remove from current project (default)
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/uninstall.sh | bash

# Remove global installation
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/uninstall.sh | bash -s -- --global

# Remove via slash command (project only)
/user:discord:remove
```

### 📋 All Available Commands
```bash
# Setup and management
/user:discord:setup WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID]  # Configure integration
/user:discord:start [THREAD_ID]                          # Enable notifications
/user:discord:stop                                       # Disable notifications
/user:discord:status                                     # Check current state
/user:discord:remove                                     # Remove integration
```

## Architecture

### 🏠 Local-First Design (Default)
**Installation Location**: `.claude/` in current project directory
- **Hook Scripts**: `.claude/hooks/` (stop-discord.py, posttooluse-discord.py, notification-discord.py)
- **Slash Commands**: `.claude/commands/discord/` (setup.md, start.md, stop.md, status.md, remove.md)
- **Python Utilities**: `.claude/commands/discord/` (merge-settings.py, update-state.py, read-state.py)
- **Project State**: `.claude/discord-state.json` (webhook URL, auth token, thread ID, active state)
- **Hooks Configuration**: `.claude/settings.json` (project-specific hooks)

### 🌐 Global Installation (Advanced)
**Installation Location**: `~/.claude/` for multi-project use
- **Hook Scripts**: `~/.claude/hooks/` (shared across all projects)
- **Slash Commands**: `~/.claude/commands/discord/` (available in all projects)
- **Per-Project State**: Each project still has its own `.claude/discord-state.json`
- **Per-Project Settings**: Each project has its own `.claude/settings.json`

### 🔧 Intelligent Path Detection
The system automatically detects installation type:
1. **Local Priority**: If `.claude/hooks/stop-discord.py` exists, uses local installation
2. **Global Fallback**: If local not found, uses global installation (`~/.claude/`)
3. **Mixed Support**: Both installations can coexist, local takes priority

### Key Design Principles
- **Project Isolation**: Only projects with `.claude/discord-state.json` receive notifications
- **Self-Contained**: Local installations include everything needed for Discord integration
- **Safe Cleanup**: Uninstall operations preserve non-Discord hooks and settings
- **Backward Compatible**: Existing global installations continue working

## Discord Notification Types

| Type | Color | Hook Event | Description |
|------|-------|------------|-------------|
| 🔔 Input Needed | Blue | Notification | Claude awaits user input |
| ⚡ Work in Progress | Gold | PostToolUse | After tool usage (Write, Edit, Bash, etc.) |
| ✅ Session Complete | Green | Stop | Claude finishes responding |

## Hook Script Logic

Each Python hook script follows this pattern:
1. Check if `.claude/discord-state.json` exists (exit silently if not)
2. Parse Discord configuration from the state file
3. Verify `"active": true` (exit if false)
4. Extract session/tool information from hook input (JSON via stdin)
5. Send formatted Discord webhook notification
6. Log results to `~/.claude/discord-notifications.log`

## File Structure Analysis

### Core Hook Scripts
- `hooks/stop-discord.py`: Handler for Stop events (session completion)
- `hooks/posttooluse-discord.py`: Handler for tool completion events  
- `hooks/notification-discord.py`: Handler for input-needed events

### Slash Commands (Custom Claude Code Commands) - Python-Enhanced Architecture
**Markdown Files (Simplified):**
- `commands/discord/setup.md`: Calls Python setup handler with path detection
- `commands/discord/start.md`: Calls Python start handler 
- `commands/discord/stop.md`: Calls Python stop handler
- `commands/discord/status.md`: Calls Python status handler
- `commands/discord/remove.md`: Calls Python remove handler

**Python Command Handlers (New Unified Architecture):**
- `commands/discord/discord_utils.py`: Shared utilities class with common functions
- `commands/discord/setup_handler.py`: Unified setup command handler with enhanced validation
- `commands/discord/start_handler.py`: Unified start command handler with thread support
- `commands/discord/status_handler.py`: Unified status command handler with detailed output
- `commands/discord/stop_handler.py`: Unified stop command handler
- `commands/discord/remove_handler.py`: Unified remove command handler with safe cleanup

**Legacy Python Utilities (Deprecated):**
- `commands/discord/merge-settings.py`: Replaced by discord_utils.py
- `commands/discord/update-state.py`: Replaced by discord_utils.py
- `commands/discord/read-state.py`: Replaced by discord_utils.py

### Installation Scripts
- `install.sh`: Local-first installer with GitHub downloads, supports `--global` flag
- `uninstall.sh`: Local-first uninstaller with safe cleanup, supports `--global` flag

## Dependencies

Required tools:
- `python3` for all hook scripts and Python command handlers
- `curl` or `wget` for HTTP requests and GitHub downloads
- `bash` for installation and uninstall scripts

Optional tools (legacy support):
- `jq` (no longer required, replaced with Python JSON processing)

## Python Enhancement Details

### Unified Command Architecture
The slash commands have been enhanced with a unified Python architecture:

1. **Simplified Markdown Files**: Each `.md` file now contains minimal bash code that detects installation type (local vs global) and calls the appropriate Python handler.

2. **Shared Utilities Module**: `discord_utils.py` provides common functionality:
   - JSON state management
   - Webhook URL validation
   - Path detection (local-first, global-fallback)
   - Consistent output formatting
   - Error handling

3. **Unified Command Handlers**: Each command has a dedicated Python handler:
   - Enhanced argument parsing and validation
   - Consistent error messages and user feedback
   - Improved webhook URL validation
   - Better state management

### Key Improvements
- **Code Reuse**: Common functions consolidated in `discord_utils.py`
- **Error Handling**: Comprehensive validation and user-friendly error messages
- **Consistency**: Uniform output formatting across all commands
- **Maintainability**: Python code is easier to maintain than complex bash scripts
- **Extensibility**: Easy to add new features or modify existing ones

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
**Local Installation Example:**
```json
{
  "hooks": {
    "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": ".claude/hooks/stop-discord.py"}]}],
    "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": ".claude/hooks/notification-discord.py"}]}],
    "PostToolUse": [{"matcher": "", "hooks": [{"type": "command", "command": ".claude/hooks/posttooluse-discord.py"}]}]
  }
}
```

**Global Installation Example:**
```json
{
  "hooks": {
    "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/stop-discord.py"}]}],
    "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/notification-discord.py"}]}],
    "PostToolUse": [{"matcher": "", "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/posttooluse-discord.py"}]}]
  }
}
```

*Note: Path detection is automatic - the system chooses local or global paths based on installation type.*

## Development and Testing

### Testing Hook Scripts
```bash
# Test local hook manually
echo '{"session_id": "test", "hook_type": "Stop"}' | python3 .claude/hooks/stop-discord.py

# Test global hook manually
echo '{"session_id": "test", "hook_type": "Stop"}' | python3 ~/.claude/hooks/stop-discord.py

# Check logs
tail -f ~/.claude/discord-notifications.log

# Verify script permissions (local)
ls -la .claude/hooks/*discord*.py

# Verify script permissions (global)
ls -la ~/.claude/hooks/*discord*.py
```

### Testing Slash Commands
```bash
# Test in a project directory
/user:discord:status
/user:discord:setup test_webhook_url
/user:discord:start

# Check installation type
/user:discord:status  # Shows "Local" or "Global" installation
```

### Testing Installation Types
```bash
# Test local installation
curl -fsSL .../install.sh | bash
/user:discord:status  # Should show "Local (project-specific)"

# Test global installation
curl -fsSL .../install.sh | bash -s -- --global
/user:discord:status  # Should show "Global (multi-project)"

# Test uninstall
curl -fsSL .../uninstall.sh | bash  # Local uninstall
curl -fsSL .../uninstall.sh | bash -s -- --global  # Global uninstall
```

### Comprehensive Testing Instructions

For thorough testing of the Discord notification system:

1. **Test Local Installation (Default)**:
   ```bash
   cd /path/to/test-project
   curl -fsSL .../install.sh | bash
   /user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
   /user:discord:start
   /user:discord:status  # Should show "Local (project-specific)"
   ```

2. **Test Global Installation**:
   ```bash
   curl -fsSL .../install.sh | bash -s -- --global
   cd project1
   /user:discord:setup YOUR_WEBHOOK_URL
   /user:discord:start
   /user:discord:status  # Should show "Global (multi-project)"
   ```

3. **Test Mixed Scenarios**:
   ```bash
   # Install both local and global
   curl -fsSL .../install.sh | bash -s -- --global
   curl -fsSL .../install.sh | bash
   /user:discord:status  # Should show "Local" (local takes priority)
   ```

4. **Test Notification Types**:
   - Make file edits → PostToolUse notifications
   - Complete session → Stop notification  
   - Need user input → Notification

5. **Test Uninstall Options**:
   ```bash
   # Local uninstall (default)
   curl -fsSL .../uninstall.sh | bash
   
   # Global uninstall
   curl -fsSL .../uninstall.sh | bash -s -- --global
   
   # Error handling (no .claude directory)
   cd random-directory
   curl -fsSL .../uninstall.sh | bash  # Should show helpful error
   ```

6. **Test Configuration Safety**:
   - Existing `.claude/settings.json` preservation
   - Backup creation during setup/removal
   - Settings merge functionality

### Common Issues
- **No notifications**: Check if `.claude/discord-state.json` exists and `"active": true`
- **Permission errors**: Ensure hook scripts are executable (`chmod +x`)
- **JSON parsing errors**: Verify config files are valid JSON (Python handles parsing)
- **Command not found**: Verify commands exist in `.claude/commands/discord/` or `~/.claude/commands/discord/`
- **Path detection issues**: Check installation type with `/user:discord:status`
- **Mixed installations**: Local takes priority - remove local if you want global behavior

## Team Collaboration

The system supports team collaboration with both local and global installations:

### Recommended Approach (Local Installation)
- **Commit**: `.claude/settings.json` to share hook configuration with team
- **Gitignore**: `.claude/discord-state.json` for personal webhook URLs
- **Team Setup**: Each member runs `/user:discord:setup` with their webhook
- **Consistent**: All team members get the same local installation

### Alternative Approach (Global Installation)
- **Team Leader**: Sets up global installation for consistency
- **Individual Setup**: Each member configures per-project webhooks
- **Flexibility**: Different projects can use different global configurations

### .gitignore Recommendations
```
# Discord integration (personal webhook URLs)
.claude/discord-state.json
.claude/settings.json.backup*

# Keep these for team sharing
# .claude/settings.json (hook configuration)
# .claude/hooks/ (if using local installation)
# .claude/commands/ (if using local installation)
```

## Claude Code Documentation References

For authoritative information about Claude Code features used in this project:
- **Slash Commands**: https://docs.anthropic.com/en/docs/claude-code/slash-commands
- **Hooks**: https://docs.anthropic.com/en/docs/claude-code/hooks

These references provide the official documentation for the Claude Code features that this notification system extends.

## Testing

The Python-enhanced slash commands have been comprehensively tested and are production-ready. All 21 test cases passed successfully, including:

- Setup command with various arguments and edge cases
- Status command before/after setup and start/stop
- Start/stop command functionality
- Remove command and cleanup verification  
- Error handling (malformed JSON, invalid URLs, permissions)
- Path detection (local vs global installation)
- Markdown to Python handler integration

For development testing, use the commands in a test project directory:
```bash
# Test setup and configuration
/user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
/user:discord:status
/user:discord:start
/user:discord:stop
/user:discord:remove
```