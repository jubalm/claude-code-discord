#!/bin/bash

# Claude Discord Integration Installer
# Installs project-level Discord notification hooks for Claude Code

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

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq first:"
        echo "  macOS: brew install jq"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        echo "  CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed."
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

# Check if Claude Code is installed
check_claude_code() {
    log_info "Checking Claude Code installation..."
    
    if [ ! -d "$CLAUDE_HOME" ]; then
        log_error "Claude Code directory not found at $CLAUDE_HOME"
        log_error "Please install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
        exit 1
    fi
    
    log_success "Claude Code found"
}

# Create necessary directories
create_directories() {
    log_info "Creating directories..."
    
    mkdir -p "$HOOKS_DIR"
    mkdir -p "$COMMANDS_DIR"
    
    log_success "Directories created"
}

# Backup existing configurations
backup_existing() {
    local backup_dir="${CLAUDE_HOME}/backup-$(date +%Y%m%d-%H%M%S)"
    local needs_backup=false
    
    # Check if any Discord-related files exist
    if [ -f "${HOOKS_DIR}/discord-notify.sh" ] || [ -f "${HOOKS_DIR}/posttooluse-discord.sh" ] || [ -f "${HOOKS_DIR}/notification-discord.sh" ] || [ -d "${COMMANDS_DIR}/discord" ]; then
        needs_backup=true
    fi
    
    if [ "$needs_backup" = true ]; then
        log_warning "Existing Discord integration found. Creating backup..."
        mkdir -p "$backup_dir"
        
        # Backup hook scripts
        [ -f "${HOOKS_DIR}/discord-notify.sh" ] && cp "${HOOKS_DIR}/discord-notify.sh" "$backup_dir/"
        [ -f "${HOOKS_DIR}/posttooluse-discord.sh" ] && cp "${HOOKS_DIR}/posttooluse-discord.sh" "$backup_dir/"
        [ -f "${HOOKS_DIR}/notification-discord.sh" ] && cp "${HOOKS_DIR}/notification-discord.sh" "$backup_dir/"
        
        # Backup commands
        [ -d "${COMMANDS_DIR}/discord" ] && cp -r "${COMMANDS_DIR}/discord" "$backup_dir/"
        
        log_success "Backup created at $backup_dir"
    fi
}

# Install hook scripts
install_hooks() {
    log_info "Installing hook scripts..."
    
    # Copy Python hook scripts (primary)
    cp hooks/stop-discord.py "$HOOKS_DIR/"
    cp hooks/posttooluse-discord.py "$HOOKS_DIR/"
    cp hooks/notification-discord.py "$HOOKS_DIR/"
    
    # Copy shell hook scripts (backup)
    cp hooks/discord-notify.sh "$HOOKS_DIR/"
    cp hooks/posttooluse-discord.sh "$HOOKS_DIR/"
    cp hooks/notification-discord.sh "$HOOKS_DIR/"
    
    # Make Python scripts executable
    chmod +x "${HOOKS_DIR}/stop-discord.py"
    chmod +x "${HOOKS_DIR}/posttooluse-discord.py"
    chmod +x "${HOOKS_DIR}/notification-discord.py"
    
    # Make shell scripts executable
    chmod +x "${HOOKS_DIR}/discord-notify.sh"
    chmod +x "${HOOKS_DIR}/posttooluse-discord.sh"
    chmod +x "${HOOKS_DIR}/notification-discord.sh"
    
    log_success "Hook scripts installed"
}

# Install slash commands
install_commands() {
    log_info "Installing slash commands..."
    
    # Copy command directory
    cp -r commands/discord "$COMMANDS_DIR/"
    
    log_success "Slash commands installed"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Check Python hook scripts (primary)
    for script in stop-discord.py posttooluse-discord.py notification-discord.py; do
        if [ ! -f "${HOOKS_DIR}/$script" ]; then
            log_error "Python hook script not found: $script"
            ((errors++))
        elif [ ! -x "${HOOKS_DIR}/$script" ]; then
            log_error "Python hook script not executable: $script"
            ((errors++))
        fi
    done
    
    # Check shell hook scripts (backup)
    for script in discord-notify.sh posttooluse-discord.sh notification-discord.sh; do
        if [ ! -f "${HOOKS_DIR}/$script" ]; then
            log_warning "Shell hook script not found: $script"
        elif [ ! -x "${HOOKS_DIR}/$script" ]; then
            log_warning "Shell hook script not executable: $script"
        fi
    done
    
    # Check commands
    for cmd in setup.md start.md stop.md status.md; do
        if [ ! -f "${COMMANDS_DIR}/discord/$cmd" ]; then
            log_error "Command not found: discord/$cmd"
            ((errors++))
        fi
    done
    
    # Check Python utility scripts
    for script in merge-settings.py update-state.py read-state.py; do
        if [ ! -f "${COMMANDS_DIR}/discord/$script" ]; then
            log_error "Python utility script not found: discord/$script"
            ((errors++))
        elif [ ! -x "${COMMANDS_DIR}/discord/$script" ]; then
            log_error "Python utility script not executable: discord/$script"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "Installation verification passed"
        return 0
    else
        log_error "Installation verification failed with $errors errors"
        return 1
    fi
}

# Main installation function
main() {
    echo "=================================================="
    echo "Claude Discord Integration Installer"
    echo "=================================================="
    echo ""
    
    # Check if script is being run from the correct directory
    if [ ! -f "hooks/discord-notify.sh" ] || [ ! -d "commands/discord" ]; then
        log_error "Please run this script from the claude-discord-integration directory"
        log_error "The directory should contain 'hooks/' and 'commands/' subdirectories"
        exit 1
    fi
    
    check_dependencies
    check_claude_code
    create_directories
    backup_existing
    install_hooks
    install_commands
    
    if verify_installation; then
        echo ""
        echo "=================================================="
        log_success "Installation completed successfully!"
        echo "=================================================="
        echo ""
        echo "🎯 Next Steps:"
        echo "1. Navigate to a project directory"
        echo "2. Run: /user:discord:setup YOUR_WEBHOOK_URL"
        echo "3. Run: /user:discord:start"
        echo "4. Start working - notifications will be sent automatically!"
        echo ""
        echo "📚 Available Commands:"
        echo "• /user:discord:setup WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID] - Setup Discord integration"
        echo "• /user:discord:start [THREAD_ID] - Enable notifications"
        echo "• /user:discord:stop - Disable notifications"
        echo "• /user:discord:status - Show current status"
        echo ""
        echo "📖 Documentation: docs/PROJECT-LEVEL-DISCORD-INTEGRATION.md"
        echo ""
        echo "Happy coding! 🚀"
    else
        echo ""
        log_error "Installation failed. Please check the errors above and try again."
        exit 1
    fi
}

# Run with error handling
if ! main "$@"; then
    log_error "Installation failed"
    exit 1
fi