#!/usr/bin/env python3

"""
Discord Setup Command Handler
Unified Python handler for Discord integration setup
"""

import sys
import os
from pathlib import Path
from discord_utils import DiscordUtils

def setup_discord_integration(args):
    """Setup Discord integration with proper error handling and validation"""
    
    # Parse arguments
    if not args or len(args) < 1:
        DiscordUtils.print_error("Please provide your Discord webhook URL as an argument")
        print("")
        print("Usage:")
        print("  /user:discord:setup WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID]")
        print("")
        print("Examples:")
        print("  /user:discord:setup https://discord.com/api/webhooks/YOUR_WEBHOOK_URL")
        print("  /user:discord:setup YOUR_WEBHOOK_URL auth_token")
        print("  /user:discord:setup YOUR_WEBHOOK_URL auth_token thread_id")
        return False
    
    webhook_url = args[0]
    auth_token = args[1] if len(args) > 1 else None
    thread_id = args[2] if len(args) > 2 else None
    
    # Validate webhook URL
    if not DiscordUtils.validate_webhook_url(webhook_url):
        DiscordUtils.print_error("Invalid webhook URL format")
        print("URL must start with: https://discord.com/api/webhooks/")
        return False
    
    # Create .claude directory if it doesn't exist
    os.makedirs(".claude", exist_ok=True)
    
    # Print setup header
    DiscordUtils.print_header(f"Discord Integration Setup for {DiscordUtils.get_project_name()}")
    print("")
    
    # Create state configuration
    project_name = DiscordUtils.get_project_name()
    state_config = DiscordUtils.create_state_config(
        webhook_url=webhook_url,
        project_name=project_name,
        auth_token=auth_token,
        thread_id=thread_id
    )
    
    # Save state configuration
    if not DiscordUtils.save_state(state_config):
        return False
    
    # Setup hooks configuration
    settings_file = ".claude/settings.json"
    
    # Check if settings file exists and create backup
    if os.path.exists(settings_file):
        print("Existing .claude/settings.json found - merging Discord hooks...")
        if DiscordUtils.backup_settings(settings_file):
            print("📁 Backup saved as .claude/settings.json.backup")
        
        # Merge Discord hooks with existing configuration
        if not DiscordUtils.merge_hooks_config(settings_file):
            return False
        
        DiscordUtils.print_success("Discord hooks merged with existing configuration")
    else:
        print("Creating new .claude/settings.json...")
        
        # Create new settings file with Discord hooks
        if not DiscordUtils.merge_hooks_config(settings_file):
            return False
        
        DiscordUtils.print_success("New .claude/settings.json created")
    
    # Print success summary
    print("")
    DiscordUtils.print_success("Discord integration setup complete!")
    print("")
    
    # Configuration summary
    print("📊 Configuration Summary:")
    print(f"  Project: {project_name}")
    print(f"  Webhook: {DiscordUtils.mask_webhook_url(webhook_url)}")
    
    if auth_token:
        DiscordUtils.print_status_line("  Auth", "Configured", DiscordUtils.COLORS['SUCCESS'])
    else:
        DiscordUtils.print_status_line("  Auth", "Not configured", DiscordUtils.COLORS['ERROR'])
    
    if thread_id:
        DiscordUtils.print_status_line("  Thread", thread_id, DiscordUtils.COLORS['THREAD'])
    else:
        DiscordUtils.print_status_line("  Thread", "Channel mode", DiscordUtils.COLORS['CHANNEL'])
    
    DiscordUtils.print_status_line("  Status", "Disabled (run /user:discord:start to enable)", DiscordUtils.COLORS['INACTIVE'])
    
    print("")
    print("🎯 Next Steps:")
    
    # Determine installation type for next steps
    install_type, _, _ = DiscordUtils.get_installation_type()
    
    if install_type == "local":
        print("  1. /user:discord:start - Enable Discord notifications")
        print("  2. Start working - notifications will be sent automatically!")
        print("")
        print("💡 Commands Available:")
        for command in DiscordUtils.get_available_commands():
            print(f"  {command}")
        print("")
        DiscordUtils.print_status_line("📍 Installation", "Local (project-specific)", DiscordUtils.COLORS['LOCAL'])
    else:
        print("  1. /user:discord:start - Enable Discord notifications")
        print("  2. Start working - notifications will be sent automatically!")
        print("")
        print("💡 Commands Available:")
        for command in DiscordUtils.get_available_commands():
            print(f"  {command}")
        print("")
        DiscordUtils.print_status_line("📍 Installation", "Global (multi-project)", DiscordUtils.COLORS['GLOBAL'])
    
    return True

def main():
    """Main entry point"""
    # Get arguments from environment variable (set by Claude Code)
    args_string = os.environ.get('ARGUMENTS', '')
    args = DiscordUtils.parse_arguments(args_string)
    
    try:
        if setup_discord_integration(args):
            sys.exit(0)
        else:
            sys.exit(1)
    except Exception as e:
        DiscordUtils.print_error(f"Setup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()