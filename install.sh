#!/bin/bash

# Claude Discord Integration Installer
# Local-first Discord notification hooks for Claude Code
# Usage: ./install.sh [--global] [--quiet]

set -e

# Parse command line arguments
GLOBAL_INSTALL=false
QUIET=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --global)
            GLOBAL_INSTALL=true
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

# Set installation paths based on mode
if [ "$GLOBAL_INSTALL" = true ]; then
    CLAUDE_HOME="${HOME}/.claude"
    HOOKS_DIR="${CLAUDE_HOME}/hooks"
    COMMANDS_DIR="${CLAUDE_HOME}/commands"
    INSTALL_MODE="global"
else
    CLAUDE_HOME=".claude"
    HOOKS_DIR="${CLAUDE_HOME}/hooks"
    COMMANDS_DIR="${CLAUDE_HOME}/commands"
    INSTALL_MODE="local"
fi

# GitHub repository base URL
GITHUB_BASE="https://raw.githubusercontent.com/jubalm/claude-discord-integration/main"

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

# Download file from GitHub
download_file() {
    local url="$1"
    local destination="$2"
    local description="$3"
    
    log_info "Downloading $description..."
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$destination"
    elif command -v wget &> /dev/null; then
        wget -q -O "$destination" "$url"
    else
        log_error "Neither curl nor wget is available. Please install one of them."
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "$description downloaded"
        return 0
    else
        log_error "Failed to download $description"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        log_error "python3 is required but not installed."
        exit 1
    fi
    
    log_success "Dependencies check passed"
}

# Check if Claude Code is installed (for global installations)
check_claude_code() {
    if [ "$GLOBAL_INSTALL" = true ]; then
        log_info "Checking Claude Code installation..."
        
        if [ ! -d "${HOME}/.claude" ]; then
            log_error "Claude Code directory not found at ${HOME}/.claude"
            log_error "Please install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
            exit 1
        fi
        
        log_success "Claude Code found"
    else
        log_info "Local installation - Claude Code check skipped"
    fi
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
    if [ -f "${HOOKS_DIR}/stop-discord.py" ] || [ -f "${HOOKS_DIR}/posttooluse-discord.py" ] || [ -f "${HOOKS_DIR}/notification-discord.py" ] || [ -d "${COMMANDS_DIR}/discord" ]; then
        needs_backup=true
    fi
    
    # Also check for legacy files
    if [ -f "${HOOKS_DIR}/discord-notify.sh" ] || [ -f "${HOOKS_DIR}/posttooluse-discord.sh" ] || [ -f "${HOOKS_DIR}/notification-discord.sh" ]; then
        needs_backup=true
    fi
    
    if [ "$needs_backup" = true ]; then
        log_warning "Existing Discord integration found. Creating backup..."
        mkdir -p "$backup_dir"
        
        # Backup current Python hook scripts
        [ -f "${HOOKS_DIR}/stop-discord.py" ] && cp "${HOOKS_DIR}/stop-discord.py" "$backup_dir/"
        [ -f "${HOOKS_DIR}/posttooluse-discord.py" ] && cp "${HOOKS_DIR}/posttooluse-discord.py" "$backup_dir/"
        [ -f "${HOOKS_DIR}/notification-discord.py" ] && cp "${HOOKS_DIR}/notification-discord.py" "$backup_dir/"
        
        # Backup legacy shell scripts
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
    
    # Download and install Python hook scripts
    download_file "${GITHUB_BASE}/hooks/stop-discord.py" "${HOOKS_DIR}/stop-discord.py" "Stop hook script"
    download_file "${GITHUB_BASE}/hooks/posttooluse-discord.py" "${HOOKS_DIR}/posttooluse-discord.py" "PostToolUse hook script"
    download_file "${GITHUB_BASE}/hooks/notification-discord.py" "${HOOKS_DIR}/notification-discord.py" "Notification hook script"
    
    # Make Python scripts executable
    chmod +x "${HOOKS_DIR}/stop-discord.py"
    chmod +x "${HOOKS_DIR}/posttooluse-discord.py"
    chmod +x "${HOOKS_DIR}/notification-discord.py"
    
    log_success "Hook scripts installed"
}

# Install slash commands
install_commands() {
    log_info "Installing slash commands..."
    
    # Create discord commands directory
    mkdir -p "${COMMANDS_DIR}/discord"
    
    # Download command files
    download_file "${GITHUB_BASE}/commands/discord/setup.md" "${COMMANDS_DIR}/discord/setup.md" "Setup command"
    download_file "${GITHUB_BASE}/commands/discord/start.md" "${COMMANDS_DIR}/discord/start.md" "Start command"
    download_file "${GITHUB_BASE}/commands/discord/stop.md" "${COMMANDS_DIR}/discord/stop.md" "Stop command"
    download_file "${GITHUB_BASE}/commands/discord/status.md" "${COMMANDS_DIR}/discord/status.md" "Status command"
    download_file "${GITHUB_BASE}/commands/discord/remove.md" "${COMMANDS_DIR}/discord/remove.md" "Remove command"
    
    # Download Python utility scripts
    download_file "${GITHUB_BASE}/commands/discord/merge-settings.py" "${COMMANDS_DIR}/discord/merge-settings.py" "Settings merge script"
    download_file "${GITHUB_BASE}/commands/discord/update-state.py" "${COMMANDS_DIR}/discord/update-state.py" "State update script"
    download_file "${GITHUB_BASE}/commands/discord/read-state.py" "${COMMANDS_DIR}/discord/read-state.py" "State read script"
    
    # Make Python scripts executable
    chmod +x "${COMMANDS_DIR}/discord/merge-settings.py"
    chmod +x "${COMMANDS_DIR}/discord/update-state.py"
    chmod +x "${COMMANDS_DIR}/discord/read-state.py"
    
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
    
    # Check commands
    for cmd in setup.md start.md stop.md status.md remove.md; do
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
    if [ "$QUIET" = false ]; then
        echo "=================================================="
        echo "Claude Discord Integration Installer"
        echo "Installation Mode: $INSTALL_MODE"
        echo "=================================================="
        echo ""
    fi
    
    check_dependencies
    check_claude_code
    create_directories
    backup_existing
    install_hooks
    install_commands
    
    if verify_installation; then
        if [ "$QUIET" = false ]; then
            echo ""
            echo "=================================================="
            log_success "Installation completed successfully!"
            echo "=================================================="
            echo ""
            
            if [ "$GLOBAL_INSTALL" = true ]; then
                echo "🎯 Next Steps (Global Installation):"
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
                echo "• /user:discord:remove - Remove project integration"
            else
                echo "🎯 Next Steps (Local Installation):"
                echo "1. Run: /user:discord:setup YOUR_WEBHOOK_URL"
                echo "2. Run: /user:discord:start"
                echo "3. Start working - notifications will be sent automatically!"
                echo ""
                echo "📚 Available Commands:"
                echo "• /user:discord:setup WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID] - Setup Discord integration"
                echo "• /user:discord:start [THREAD_ID] - Enable notifications"
                echo "• /user:discord:stop - Disable notifications"
                echo "• /user:discord:status - Show current status"
                echo "• /user:discord:remove - Remove integration"
            fi
            
            echo ""
            echo "Happy coding! 🚀"
        fi
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