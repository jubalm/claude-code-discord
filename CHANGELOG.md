# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-07-07

### 🐛 Critical Bug Fix
- **Fixed remaining HTTP 403 errors in global hooks** - Updated global Python hook installations to include User-Agent headers

### 🧪 Verification  
- **End-to-end testing confirmed** - All notification types now working correctly without HTTP errors
- **Complete functionality restored** - PostToolUse, Stop, and Notification hooks all sending Discord messages successfully

## [0.2.0] - 2025-07-07

### 🐛 Critical Bug Fixes
- **Fixed HTTP 403 Forbidden errors** - Added required User-Agent headers to all Python webhook requests
- **Fixed broken uninstall script** - Updated to properly handle Python files instead of shell scripts
- **Fixed broken install script** - Removed references to non-existent shell scripts

### ✨ New Features
- **Project-level removal command** - New `/user:discord:remove` slash command for clean project-specific removal
- **Smart hook preservation** - Removal command preserves non-Discord hooks when cleaning up Discord integration
- **Complete install/uninstall symmetry** - Uninstall script removes exactly what install script adds

### 🏗️ Architecture Improvements
- **Pure Python implementation** - Completely removed all shell scripts (.sh files) from the codebase
- **Reduced dependencies** - Removed `jq` and `curl` requirements, now only needs Python 3
- **Consistent documentation** - Updated all references from shell scripts to Python scripts

### 🧪 Testing Improvements
- **End-to-end validation** - Comprehensive testing of install → use → uninstall → reinstall cycle
- **Webhook validation** - Improved Discord webhook URL testing and validation
- **Error handling** - Better error messages and recovery for common issues

### 📁 Repository Changes
- **Added**: `commands/discord/remove.md` - Project-level removal command
- **Removed**: All `.sh` files from `hooks/` directory
- **Updated**: `install.sh` and `uninstall.sh` for Python-only operation

## [0.1.1] - 2025-01-07

### Fixed
- 🔗 **Installation URLs** - Fixed repository URLs in documentation that were causing 404 errors
  - Updated `CLAUDE.md` curl command to use correct GitHub repository path
  - Updated `README.md` curl and git clone commands to use correct repository path
  - Changed `USERNAME/claude-discord-integration` → `jubalm/claude-code-discord`

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