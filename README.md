# Claude Code Discord Notification

**Stay informed about your Claude Code sessions with real-time Discord notifications - know what Claude is working on even when you're away from your computer**

Get real-time Discord notifications when Claude completes tasks, needs input, or makes progress on your projects. Each project can independently configure Discord integration without affecting other projects.

## ✨ Features

- 🎯 **Project-scoped notifications** - Each project controls its own Discord integration
- 🔔 **Smart notification types** - Input needed, work in progress, session complete
- 🧵 **Thread support** - Organize notifications by session with Discord threads
- ⚡ **Easy control** - Simple slash commands for setup and management
- 🛡️ **Non-destructive setup** - Preserves existing Claude Code configuration
- 🔧 **Configurable webhooks** - No hardcoded URLs, bring your own webhook

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/install.sh | bash
```

Or clone and install manually:

```bash
git clone https://github.com/jubalm/claude-code-discord.git
cd claude-discord-integration
chmod +x install.sh
./install.sh
```

## 📋 Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- Python 3 (universally available)
- Discord webhook URL

## 🎯 Quick Start

### 1. Get Your Discord Webhook URL

1. Go to your Discord server settings
2. Navigate to **Integrations** → **Webhooks**
3. Click **New Webhook** or use an existing one
4. Copy the webhook URL

### 2. Setup and Enable

Navigate to your project directory and run:

```bash
# Setup Discord integration
/user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL

# Enable notifications
/user:discord:start
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

Each project is independent. You can have different Discord configurations per project:

```bash
# Project A - posts to #development channel
cd /path/to/project-a
/user:discord:setup https://discord.com/api/webhooks/DEV_WEBHOOK

# Project B - posts to #ai-testing thread  
cd /path/to/project-b
/user:discord:setup https://discord.com/api/webhooks/TEST_WEBHOOK TOKEN THREAD_ID
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

Commit `.claude/settings.json` to share Discord integration with your team:

```bash
# .gitignore - exclude personal Discord config
.claude/discord-state.json
.claude/settings.json.backup

# Commit the hooks configuration for the team
git add .claude/settings.json
git commit -m "Add Discord notifications for team"
```

Team members can then add their own webhook:

```bash
# Each team member configures their own webhook
/user:discord:setup https://discord.com/api/webhooks/THEIR_WEBHOOK
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

1. Verify scripts exist and are executable:
   ```bash
   ls -la ~/.claude/hooks/*discord*.py
   ```

2. Test script manually:
   ```bash
   echo '{}' | ~/.claude/hooks/stop-discord.py
   ```

3. Check script permissions:
   ```bash
   chmod +x ~/.claude/hooks/*discord*.py
   ```

### Commands Not Available

1. Verify commands directory:
   ```bash
   ls ~/.claude/commands/discord/
   ```

2. Restart Claude Code to reload commands

3. Try with full command prefix:
   ```bash
   /user:discord:status
   ```

## 🗑️ Uninstallation

```bash
# Download and run uninstall script
curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/uninstall.sh | bash

# Or manually remove files
rm -f ~/.claude/hooks/*discord*.py
rm -rf ~/.claude/commands/discord
```

Note: This only removes global components. Project-specific `.claude/` files remain.

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