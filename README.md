# Claude Code Discord Notification

**Local-first Discord notifications for Claude Code sessions - stay informed about your coding progress**

Get real-time Discord notifications when Claude completes tasks, needs input, or makes progress on your projects. **Simple local installation** by default, with optional global setup for advanced multi-project workflows.

## ✨ Features

- 🏠 **Local-first architecture** - Self-contained installation per project
- 🌐 **Global option available** - Multi-project setup for advanced users
- 🎯 **Project-scoped notifications** - Each project controls its own Discord integration
- 🔔 **Smart notification types** - Input needed, work in progress, session complete
- 🧵 **Thread support** - Organize notifications by session with Discord threads
- ⚡ **Easy control** - Simple slash commands for setup and management
- 🛡️ **Non-destructive setup** - Preserves existing Claude Code configuration
- 🔧 **Configurable webhooks** - No hardcoded URLs, bring your own webhook

## 🚀 Quick Install

### 🏠 Local Installation (Recommended)
Perfect for single projects - everything installs to your current project:

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/install.sh | bash
```

### 🌐 Global Installation (Advanced)
For managing multiple projects with shared Discord integration:

```bash
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/install.sh | bash -s -- --global
```

### 🔧 Manual Installation
```bash
git clone https://github.com/jubalm/claude-code-discord.git
cd claude-discord-integration
chmod +x install.sh
./install.sh              # Local installation
./install.sh --global     # Global installation
```

## 📋 Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (global installation only)
- Python 3 (universally available)
- `curl` or `wget` for installation
- Discord webhook URL

## 🎯 Quick Start

### 1. Get Your Discord Webhook URL

1. Go to your Discord server settings
2. Navigate to **Integrations** → **Webhooks**
3. Click **New Webhook** or use an existing one
4. Copy the webhook URL

### 2. Setup and Enable

After installation, configure Discord integration:

```bash
# Setup Discord integration
/user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL

# Enable notifications
/user:discord:start

# Check installation type
/user:discord:status
```

### 3. Stay Informed

You'll automatically receive Discord notifications when:
- 🔔 **Claude needs input** (blue notifications)
- ⚡ **Claude makes progress** (gold notifications after tool usage)
- ✅ **Claude completes session** (green notifications)

## 📱 Notification Types

| Type | Color | Trigger | Description |
|------|-------|---------|-------------|
| 🔔 Input Needed | Blue | Claude awaits user input | Session paused, needs attention |
| ⚡ Work in Progress | Gold | After tool usage | File edits, commands, progress updates |
| ✅ Session Complete | Green | Claude finishes responding | Task completed successfully |

## 🎮 Available Commands

| Command | Description |
|---------|-------------|
| `/user:discord:setup WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID]` | Setup Discord integration for project |
| `/user:discord:start [THREAD_ID]` | Enable Discord notifications |
| `/user:discord:stop` | Disable Discord notifications |
| `/user:discord:status` | Show current integration status |

## 🛠️ Advanced Usage

### Multiple Projects

**Local Installation**: Each project is completely independent:
```bash
# Project A - local installation
cd /path/to/project-a
curl -fsSL .../install.sh | bash
/user:discord:setup https://discord.com/api/webhooks/DEV_WEBHOOK

# Project B - separate local installation
cd /path/to/project-b  
curl -fsSL .../install.sh | bash
/user:discord:setup https://discord.com/api/webhooks/TEST_WEBHOOK TOKEN THREAD_ID
```

**Global Installation**: Shared setup across projects:
```bash
# One-time global install
curl -fsSL .../install.sh | bash -s -- --global

# Then configure each project
cd project-a && /user:discord:setup DEV_WEBHOOK
cd project-b && /user:discord:setup TEST_WEBHOOK TOKEN THREAD_ID
```

### Discord Threads

For better organization, you can use Discord threads:

```bash
# Create a thread in Discord, copy its ID
/user:discord:start 1234567890123456789

# Or setup with thread from the beginning
/user:discord:setup YOUR_WEBHOOK_URL YOUR_AUTH_TOKEN 1234567890123456789
```

### Team Collaboration

**Local Installation (Recommended)**:
```bash
# Commit Discord integration for team sharing
git add .claude/hooks/ .claude/commands/ .claude/settings.json
git commit -m "Add Discord notifications for team"

# .gitignore - exclude personal webhooks
echo ".claude/discord-state.json" >> .gitignore
echo ".claude/settings.json.backup*" >> .gitignore

# Team members just need to configure their webhook
/user:discord:setup https://discord.com/api/webhooks/THEIR_WEBHOOK
/user:discord:start
```

**Global Installation**:
```bash
# Team lead sets up global installation
curl -fsSL .../install.sh | bash -s -- --global

# Commit project hooks only
git add .claude/settings.json
git commit -m "Add Discord hooks config"

# Each team member configures their webhook per project
/user:discord:setup THEIR_WEBHOOK
/user:discord:start
```

## 🔧 Troubleshooting

### No Notifications Received

1. Check if Discord integration is active:
   ```bash
   /user:discord:status
   ```

2. Verify configuration files exist:
   ```bash
   ls -la .claude/
   # Should show: discord-state.json, settings.json
   ```

3. Test webhook manually:
   ```bash
   curl -X POST "YOUR_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "Test notification"}'
   ```

4. Check Claude Code logs:
   ```bash
   tail -f ~/.claude/discord-notifications.log
   ```

### Hook Scripts Not Working

1. Check installation type and verify scripts:
   ```bash
   /user:discord:status  # Shows Local or Global installation
   
   # For local installation
   ls -la .claude/hooks/*discord*.py
   
   # For global installation  
   ls -la ~/.claude/hooks/*discord*.py
   ```

2. Test script manually:
   ```bash
   # Local
   echo '{}' | .claude/hooks/stop-discord.py
   
   # Global
   echo '{}' | ~/.claude/hooks/stop-discord.py
   ```

3. Fix permissions if needed:
   ```bash
   chmod +x .claude/hooks/*discord*.py      # Local
   chmod +x ~/.claude/hooks/*discord*.py   # Global
   ```

### Commands Not Available

1. Verify commands based on installation type:
   ```bash
   # Local
   ls .claude/commands/discord/
   
   # Global
   ls ~/.claude/commands/discord/
   ```

2. Restart Claude Code to reload commands

3. Check installation type:
   ```bash
   /user:discord:status
   ```

## 🗑️ Uninstallation

### Local Uninstall (Default)
Remove Discord integration from current project:
```bash
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/uninstall.sh | bash

# Or use slash command
/user:discord:remove
```

### Global Uninstall
Remove global Discord integration (affects all projects):
```bash
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/uninstall.sh | bash -s -- --global
```

### Manual Cleanup
```bash
# Local installation
rm -rf .claude/hooks/*discord*.py .claude/commands/discord/
rm -f .claude/discord-state.json

# Global installation  
rm -f ~/.claude/hooks/*discord*.py
rm -rf ~/.claude/commands/discord
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Discord Webhooks Guide](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
- [Project Documentation](docs/PROJECT-LEVEL-DISCORD-INTEGRATION.md)

---

**Happy coding with Discord notifications! 🚀**