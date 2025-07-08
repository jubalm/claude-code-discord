#!/usr/bin/env python3

"""
Discord Status Command Handler
Unified Python handler for checking Discord integration status
"""

import sys
import os
from discord_utils import DiscordUtils

def show_discord_status():
    """Show Discord integration status with detailed information"""
    
    project_name = DiscordUtils.get_project_name()
    
    if DiscordUtils.check_state_exists():
        # Load state
        state = DiscordUtils.load_state()
        
        # Print header
        DiscordUtils.print_header(f"Discord Status for {project_name}")
        print("")
        
        # Extract state information
        active = state.get('active', False)
        project_name_state = state.get('project_name', 'unknown')
        thread_id = state.get('thread_id', '')
        has_auth = bool(state.get('auth_token', ''))
        webhook_url = state.get('webhook_url', '')
        
        # Project and status
        print(f"Project: {project_name_state}")
        
        if active:
            DiscordUtils.print_status_line("Status", "Active", DiscordUtils.COLORS['ACTIVE'])
        else:
            DiscordUtils.print_status_line("Status", "Disabled", DiscordUtils.COLORS['INACTIVE'])
        
        # Target (thread or channel)
        if thread_id:
            DiscordUtils.print_status_line("Target", f"Thread ({thread_id})", DiscordUtils.COLORS['THREAD'])
        else:
            DiscordUtils.print_status_line("Target", "Channel", DiscordUtils.COLORS['CHANNEL'])
        
        # Authentication
        if has_auth:
            DiscordUtils.print_status_line("Auth", "Configured", DiscordUtils.COLORS['AUTH'])
        else:
            DiscordUtils.print_status_line("Auth", "Not configured", DiscordUtils.COLORS['ERROR'])
        
        # Webhook URL (masked)
        if webhook_url:
            print(f"Webhook: {DiscordUtils.mask_webhook_url(webhook_url)}")
        
        print("")
        
        # Configuration files
        settings_exists = os.path.exists(".claude/settings.json")
        DiscordUtils.print_status_line("Hooks configured", "Yes" if settings_exists else "No", 
                                     DiscordUtils.COLORS['SUCCESS'] if settings_exists else DiscordUtils.COLORS['ERROR'])
        
        # Installation type
        install_type, _, _ = DiscordUtils.get_installation_type()
        if install_type == "local":
            DiscordUtils.print_status_line("Installation", "Local (project-specific)", DiscordUtils.COLORS['LOCAL'])
        else:
            DiscordUtils.print_status_line("Installation", "Global (multi-project)", DiscordUtils.COLORS['GLOBAL'])
        
    else:
        # No Discord integration configured
        DiscordUtils.print_info(f"No Discord integration configured for {project_name}")
        print("")
        print("To get started:")
        print("• /user:discord:setup YOUR_WEBHOOK_URL - Setup Discord integration")
    
    print("")
    print("**Available Commands:**")
    for command in DiscordUtils.get_available_commands():
        print(f"- {command}")
    
    return True

def main():
    """Main entry point"""
    try:
        show_discord_status()
        sys.exit(0)
    except Exception as e:
        DiscordUtils.print_error(f"Status check failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()