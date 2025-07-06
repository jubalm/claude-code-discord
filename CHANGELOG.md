# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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