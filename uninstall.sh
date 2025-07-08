#!/bin/bash

# Claude Discord Integration Uninstaller
# Local-first uninstaller with global option
# Usage: ./uninstall.sh [--global] [--quiet]

set -e

# Parse command line arguments
GLOBAL_UNINSTALL=false
QUIET=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --global)
            GLOBAL_UNINSTALL=true
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--global] [--quiet]"
            exit 1
            ;;
    esac
done

# Determine uninstall mode and paths
if [ "$GLOBAL_UNINSTALL" = true ]; then
    CLAUDE_HOME="${HOME}/.claude"
    HOOKS_DIR="${CLAUDE_HOME}/hooks"
    COMMANDS_DIR="${CLAUDE_HOME}/commands"
    UNINSTALL_MODE="global"
else
    # Default: Local uninstall (requires .claude directory)
    if [ ! -d ".claude" ]; then
        echo "❌ No .claude directory found in current location."
        echo ""
        echo "This appears to be a directory without Discord integration."
        echo ""
        echo "Available options:"
        echo "• Run from a project directory with Discord integration"
        echo "• Use --global flag to remove global installation:"
        echo "  curl -fsSL https://raw.githubusercontent.com/jubalm/claude-discord-integration/main/uninstall.sh | bash -s -- --global"
        exit 1
    fi
    
    CLAUDE_HOME=".claude"
    HOOKS_DIR="${CLAUDE_HOME}/hooks"
    COMMANDS_DIR="${CLAUDE_HOME}/commands"
    UNINSTALL_MODE="local"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

log_warning() {
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}[WARNING]${NC} $1"
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Discord integration is installed
check_installation() {
    local found_components=()
    
    # Check for hook scripts
    [ -f "${HOOKS_DIR}/stop-discord.py" ] && found_components+=("stop-discord.py")
    [ -f "${HOOKS_DIR}/posttooluse-discord.py" ] && found_components+=("posttooluse-discord.py")
    [ -f "${HOOKS_DIR}/notification-discord.py" ] && found_components+=("notification-discord.py")
    
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
    [ -f "${HOOKS_DIR}/stop-discord.py" ] && cp "${HOOKS_DIR}/stop-discord.py" "$backup_dir/"
    [ -f "${HOOKS_DIR}/posttooluse-discord.py" ] && cp "${HOOKS_DIR}/posttooluse-discord.py" "$backup_dir/"
    [ -f "${HOOKS_DIR}/notification-discord.py" ] && cp "${HOOKS_DIR}/notification-discord.py" "$backup_dir/"
    
    # Backup commands
    [ -d "${COMMANDS_DIR}/discord" ] && cp -r "${COMMANDS_DIR}/discord" "$backup_dir/"
    
    log_success "Backup created at $backup_dir"
}

# Remove hook scripts
remove_hooks() {
    log_info "Removing hook scripts..."
    
    local removed=0
    
    for script in stop-discord.py posttooluse-discord.py notification-discord.py; do
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
    [ -f "${HOOKS_DIR}/stop-discord.py" ] && remaining+=("stop-discord.py")
    [ -f "${HOOKS_DIR}/posttooluse-discord.py" ] && remaining+=("posttooluse-discord.py")
    [ -f "${HOOKS_DIR}/notification-discord.py" ] && remaining+=("notification-discord.py")
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
    if [ "$QUIET" = true ]; then
        return 0  # Skip confirmation in quiet mode
    fi
    
    echo ""
    if [ "$GLOBAL_UNINSTALL" = true ]; then
        log_warning "This will remove all global Discord integration components from Claude Code."
        log_warning "Project-specific configuration files (.claude/discord-state.json, .claude/settings.json) will NOT be removed."
    else
        log_warning "This will remove Discord integration from the current project only."
        log_warning "Global components in ~/.claude/ will NOT be affected."
    fi
    echo ""
    
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
}

# Remove settings.json hooks safely (local uninstall only)
remove_settings_hooks() {
    if [ "$GLOBAL_UNINSTALL" = true ]; then
        return 0  # Skip for global uninstall
    fi
    
    if [ ! -f ".claude/settings.json" ]; then
        log_info "No settings.json file to clean"
        return 0
    fi
    
    log_info "Removing Discord hooks from settings.json..."
    
    # Create backup
    cp .claude/settings.json .claude/settings.json.backup-$(date +%Y%m%d-%H%M%S)
    
    # Use the same Python code as in remove.md to safely remove hooks
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
}

# Main uninstallation function
main() {
    if [ "$QUIET" = false ]; then
        echo "=================================================="
        echo "Claude Discord Integration Uninstaller"
        echo "Uninstall Mode: $UNINSTALL_MODE"
        echo "=================================================="
        echo ""
    fi
    
    # Check if Discord integration is installed
    if ! check_installation; then
        if [ "$QUIET" = false ]; then
            echo ""
            log_info "Nothing to uninstall. Exiting."
        fi
        exit 0
    fi
    
    # Confirm removal
    confirm_removal
    
    # Create backup
    create_backup
    
    # Remove components
    remove_hooks
    remove_commands
    remove_settings_hooks
    
    # Remove discord-state.json for local uninstalls
    if [ "$GLOBAL_UNINSTALL" = false ] && [ -f ".claude/discord-state.json" ]; then
        log_info "Removing discord-state.json..."
        rm -f .claude/discord-state.json
        log_success "Removed discord-state.json"
    fi
    
    # Verify removal
    if verify_removal; then
        if [ "$QUIET" = false ]; then
            echo ""
            echo "=================================================="
            log_success "Uninstallation completed successfully!"
            echo "=================================================="
            echo ""
            
            if [ "$GLOBAL_UNINSTALL" = true ]; then
                log_info "What was removed:"
                echo "• Global hook scripts from ~/.claude/hooks/"
                echo "• Global slash commands from ~/.claude/commands/discord/"
                echo ""
                log_warning "What was NOT removed:"
                echo "• Project-specific .claude/discord-state.json files"
                echo "• Project-specific .claude/settings.json files"
                echo "• Any Discord webhook configurations"
                echo ""
                log_info "To remove project-specific configuration:"
                echo "• Use /user:discord:remove in each project"
                echo "• Or manually delete .claude/discord-state.json files"
            else
                log_info "What was removed:"
                echo "• Local hook scripts from .claude/hooks/"
                echo "• Local slash commands from .claude/commands/discord/"
                echo "• Discord hooks from .claude/settings.json"
                echo "• .claude/discord-state.json (if present)"
                echo ""
                log_warning "What was NOT removed:"
                echo "• Global components in ~/.claude/"
                echo "• Other hooks and settings in .claude/settings.json"
            fi
            
            echo ""
            log_info "Backup created for safety - you can restore if needed"
        fi
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