# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-07

### Added
- 🐍 **Python-first implementation** - Eliminates external dependencies (`jq`, `curl`)
- 🏗️ **Consistent naming convention** - All hooks follow `{event-type}-discord.py` pattern
- 🛠️ **Utility scripts** - Modular Python scripts for JSON operations
- ⚡ **Better error handling** - Native Python exception handling vs shell error codes
- 🔧 **Maintainable codebase** - More readable and debuggable Python code

### Changed
- **Hook scripts converted to Python**:
  - `discord-notify.sh` → `stop-discord.py`
  - `notification-discord.sh` → `notification-discord.py` 
  - `posttooluse-discord.sh` → `posttooluse-discord.py`
- **Slash commands updated** to use Python for JSON operations
- **Installation script** now installs Python versions alongside shell backups

### Improved
- **Zero external dependencies** - Only requires Python (universally available)
- **Native JSON processing** - Proper parsing vs shell string manipulation
- **Enhanced logging** - Python logging vs echo-to-file
- **Faster execution** - Python startup vs multiple shell subprocess calls

### Backward Compatibility
- Shell hook scripts maintained as backup
- Existing configurations continue to work
- Non-breaking changes to slash commands

## [0.0.1-beta] - 2025-01-06

### Added
- 🎯 Project-level Discord integration for Claude Code Discord Notification
- 🔔 Three notification types: Input Needed, Work in Progress, Session Complete
- 🧵 Discord thread support for organized notifications
- ⚡ Custom slash commands for easy control (`/user:discord:setup`, `/user:discord:start`, etc.)
- 🛡️ Non-destructive setup that preserves existing Claude Code configuration
- 🔧 Configurable webhook URLs (no hardcoded values)
- 📦 One-command installation via curl
- 🗑️ Clean uninstallation script
- 📚 Comprehensive documentation and troubleshooting guide

### Features
- **Hook Scripts**: Respond to Claude events (Stop, PostToolUse, Notification)
- **Slash Commands**: Project configuration and control
- **Project Isolation**: Each project controls its own Discord integration
- **Thread Organization**: Group notifications by session using Discord threads
- **Configuration Backup**: Automatic backup during setup
- **Team Collaboration**: Shareable hooks configuration via `.claude/settings.json`

### Security
- No hardcoded webhook URLs or tokens
- Project-scoped configuration (no global pollution)
- Automatic backup before configuration changes
- Validation of Discord webhook URLs

## [Unreleased]

### Planned
- GUI configuration tool
- Multiple webhook support per project
- Notification filtering and customization
- Integration with other chat platforms (Slack, Teams)
- Advanced thread management features