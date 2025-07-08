#!/usr/bin/env python3

"""
Discord Start Command Handler
Unified Python handler for starting Discord notifications
"""

import sys
import os
from discord_utils import DiscordUtils

def start_discord_notifications(args):
    """Start Discord notifications with proper error handling"""
    
    # Ensure .claude directory exists
    os.makedirs(".claude", exist_ok=True)
    
    # Check if Discord is configured
    if not DiscordUtils.check_state_exists():
        DiscordUtils.print_error("Discord not configured for this project")
        print("Run: /user:discord:setup YOUR_WEBHOOK_URL")
        return False
    
    # Load current state
    state = DiscordUtils.load_state()
    if not state:
        DiscordUtils.print_error("Failed to load Discord configuration")
        return False
    
    # Parse arguments for thread ID
    thread_id = None
    if args and len(args) > 0:
        thread_id = args[0]
    
    # Update state
    state['active'] = True
    if thread_id:
        state['thread_id'] = thread_id
    
    # Save updated state
    if not DiscordUtils.save_state(state):
        return False
    
    # Display success message
    project_name = DiscordUtils.get_project_name()
    
    if thread_id:
        DiscordUtils.print_success(f"Discord notifications enabled for thread: {thread_id}")
    else:
        # Check if there's an existing thread ID
        existing_thread = state.get('thread_id')
        if existing_thread:
            DiscordUtils.print_success(f"Discord notifications enabled for thread: {existing_thread}")
        else:
            DiscordUtils.print_success("Discord notifications enabled for channel")
    
    print("")
    print(f"Discord notifications are now active for project: **{project_name}**")
    print("")
    
    # Usage information
    print("**Usage:**")
    print("- `/user:discord:start` - Post to main channel")
    print("- `/user:discord:start THREAD_ID` - Post to specific thread")
    print("- `/user:discord:stop` - Disable notifications")
    print("- `/user:discord:status` - Check current state")
    print("")
    
    print("**Other commands:**")
    print("- `/user:discord:stop` - Disable notifications")
    print("- `/user:discord:status` - Check current state")
    print("- `/user:discord:setup` - Reconfigure Discord integration")
    print("- `/user:discord:remove` - Remove integration")
    print("")
    
    # Show installation type
    install_type, _, _ = DiscordUtils.get_installation_type()
    if install_type == "local":
        DiscordUtils.print_status_line("**Installation type**", "Local (project-specific)", DiscordUtils.COLORS['LOCAL'])
    else:
        DiscordUtils.print_status_line("**Installation type**", "Global (multi-project)", DiscordUtils.COLORS['GLOBAL'])
    
    return True

def main():
    """Main entry point"""
    # Get arguments from environment variable (set by Claude Code)
    args_string = os.environ.get('ARGUMENTS', '')
    args = DiscordUtils.parse_arguments(args_string)
    
    try:
        if start_discord_notifications(args):
            sys.exit(0)
        else:
            sys.exit(1)
    except Exception as e:
        DiscordUtils.print_error(f"Start failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()