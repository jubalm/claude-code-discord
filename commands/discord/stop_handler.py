#!/usr/bin/env python3

"""
Discord Stop Command Handler
Unified Python handler for stopping Discord notifications
"""

import sys
import os
from discord_utils import DiscordUtils

def stop_discord_notifications():
    """Stop Discord notifications with proper error handling"""
    
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
    
    # Update state to disable notifications
    state['active'] = False
    
    # Save updated state
    if not DiscordUtils.save_state(state):
        return False
    
    # Display success message
    project_name = DiscordUtils.get_project_name()
    DiscordUtils.print_success(f"Discord notifications disabled for project: {project_name}")
    
    print("")
    print("Discord notifications are now **disabled**")
    print("")
    
    # Show current configuration
    thread_id = state.get('thread_id')
    if thread_id:
        DiscordUtils.print_status_line("Previous target", f"Thread ({thread_id})", DiscordUtils.COLORS['THREAD'])
    else:
        DiscordUtils.print_status_line("Previous target", "Channel", DiscordUtils.COLORS['CHANNEL'])
    
    print("")
    print("**To re-enable notifications:**")
    print("- `/user:discord:start` - Enable for channel")
    print("- `/user:discord:start THREAD_ID` - Enable for specific thread")
    print("")
    
    print("**Other commands:**")
    print("- `/user:discord:status` - Check current state")
    print("- `/user:discord:setup` - Reconfigure Discord integration")
    print("- `/user:discord:remove` - Remove integration completely")
    
    return True

def main():
    """Main entry point"""
    try:
        if stop_discord_notifications():
            sys.exit(0)
        else:
            sys.exit(1)
    except Exception as e:
        DiscordUtils.print_error(f"Stop failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()