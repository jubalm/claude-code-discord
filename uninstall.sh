#!/bin/bash

# Claude Discord Integration Uninstaller
# Removes global Discord integration components from Claude Code

set -e

CLAUDE_HOME="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_HOME}/hooks"
COMMANDS_DIR="${CLAUDE_HOME}/commands"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Discord integration is installed
check_installation() {
    local found_components=()
    
    # Check for hook scripts
    [ -f "${HOOKS_DIR}/discord-notify.sh" ] && found_components+=("discord-notify.sh")
    [ -f "${HOOKS_DIR}/posttooluse-discord.sh" ] && found_components+=("posttooluse-discord.sh")
    [ -f "${HOOKS_DIR}/notification-discord.sh" ] && found_components+=("notification-discord.sh")
    
    # Check for commands
    [ -d "${COMMANDS_DIR}/discord" ] && found_components+=("discord commands")
    
    if [ ${#found_components[@]} -eq 0 ]; then
        log_warning "No Discord integration components found"
        return 1
    fi
    
    log_info "Found Discord integration components:"
    printf ' • %s\n' "${found_components[@]}"
    return 0
}

# Create backup before removal
create_backup() {
    local backup_dir="${CLAUDE_HOME}/discord-backup-$(date +%Y%m%d-%H%M%S)"
    
    log_info "Creating backup before removal..."
    mkdir -p "$backup_dir"
    
    # Backup hook scripts
    [ -f "${HOOKS_DIR}/discord-notify.sh" ] && cp "${HOOKS_DIR}/discord-notify.sh" "$backup_dir/"
    [ -f "${HOOKS_DIR}/posttooluse-discord.sh" ] && cp "${HOOKS_DIR}/posttooluse-discord.sh" "$backup_dir/"
    [ -f "${HOOKS_DIR}/notification-discord.sh" ] && cp "${HOOKS_DIR}/notification-discord.sh" "$backup_dir/"
    
    # Backup commands
    [ -d "${COMMANDS_DIR}/discord" ] && cp -r "${COMMANDS_DIR}/discord" "$backup_dir/"
    
    log_success "Backup created at $backup_dir"
}

# Remove hook scripts
remove_hooks() {
    log_info "Removing hook scripts..."
    
    local removed=0
    
    for script in discord-notify.sh posttooluse-discord.sh notification-discord.sh; do
        if [ -f "${HOOKS_DIR}/$script" ]; then
            rm -f "${HOOKS_DIR}/$script"
            log_success "Removed $script"
            ((removed++))
        fi
    done
    
    if [ $removed -gt 0 ]; then
        log_success "Removed $removed hook scripts"
    else
        log_info "No hook scripts to remove"
    fi
}

# Remove slash commands
remove_commands() {
    log_info "Removing slash commands..."
    
    if [ -d "${COMMANDS_DIR}/discord" ]; then
        rm -rf "${COMMANDS_DIR}/discord"
        log_success "Removed discord commands directory"
    else
        log_info "No discord commands directory to remove"
    fi
}

# Verify removal
verify_removal() {
    log_info "Verifying removal..."
    
    local remaining=()
    
    # Check for remaining files
    [ -f "${HOOKS_DIR}/discord-notify.sh" ] && remaining+=("discord-notify.sh")
    [ -f "${HOOKS_DIR}/posttooluse-discord.sh" ] && remaining+=("posttooluse-discord.sh")
    [ -f "${HOOKS_DIR}/notification-discord.sh" ] && remaining+=("notification-discord.sh")
    [ -d "${COMMANDS_DIR}/discord" ] && remaining+=("discord commands")
    
    if [ ${#remaining[@]} -eq 0 ]; then
        log_success "All Discord integration components removed successfully"
        return 0
    else
        log_error "Some components could not be removed:"
        printf ' • %s\n' "${remaining[@]}"
        return 1
    fi
}

# Prompt for confirmation
confirm_removal() {
    echo ""
    log_warning "This will remove all global Discord integration components from Claude Code."
    log_warning "Project-specific configuration files (.claude/discord-state.json, .claude/settings.json) will NOT be removed."
    echo ""
    
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
}

# Main uninstallation function
main() {
    echo "=================================================="
    echo "Claude Discord Integration Uninstaller"
    echo "=================================================="
    echo ""
    
    # Check if Claude Code directory exists
    if [ ! -d "$CLAUDE_HOME" ]; then
        log_error "Claude Code directory not found at $CLAUDE_HOME"
        exit 1
    fi
    
    # Check if Discord integration is installed
    if ! check_installation; then
        echo ""
        log_info "Nothing to uninstall. Exiting."
        exit 0
    fi
    
    # Confirm removal
    confirm_removal
    
    # Create backup
    create_backup
    
    # Remove components
    remove_hooks
    remove_commands
    
    # Verify removal
    if verify_removal; then
        echo ""
        echo "=================================================="
        log_success "Uninstallation completed successfully!"
        echo "=================================================="
        echo ""
        log_info "What was removed:"
        echo "• Global hook scripts from ~/.claude/hooks/"
        echo "• Global slash commands from ~/.claude/commands/discord/"
        echo ""
        log_warning "What was NOT removed:"
        echo "• Project-specific .claude/discord-state.json files"
        echo "• Project-specific .claude/settings.json files"
        echo "• Any Discord webhook configurations"
        echo ""
        log_info "To remove project-specific configuration, manually delete:"
        echo "• .claude/discord-state.json in each project"
        echo "• Discord hooks from .claude/settings.json in each project"
        echo ""
        log_info "Backup created for safety - you can restore if needed"
    else
        echo ""
        log_error "Uninstallation completed with errors. Please check the issues above."
        exit 1
    fi
}

# Handle script interruption
trap 'log_error "Uninstallation interrupted"; exit 1' INT TERM

# Run with error handling
if ! main "$@"; then
    log_error "Uninstallation failed"
    exit 1
fi