#!/usr/bin/env python3

"""
Discord Remove Command Handler
Unified Python handler for removing Discord integration
"""

import sys
import os
import json
import shutil
from datetime import datetime
from discord_utils import DiscordUtils

def remove_discord_hooks_from_settings(settings_file=".claude/settings.json"):
    """Remove Discord hooks from settings.json while preserving others"""
    
    try:
        with open(settings_file, 'r') as f:
            settings = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return True  # Nothing to remove
    
    if 'hooks' not in settings:
        return True  # No hooks to process
    
    hooks = settings['hooks']
    
    # Remove Discord hooks while preserving others
    for hook_type in ['Stop', 'Notification', 'PostToolUse']:
        if hook_type in hooks:
            # Filter out hooks that contain 'discord' in their command
            filtered_hooks = []
            for hook_config in hooks[hook_type]:
                if 'hooks' in hook_config:
                    # Filter out discord commands
                    non_discord_hooks = [
                        h for h in hook_config['hooks'] 
                        if 'discord' not in h.get('command', '')
                    ]
                    if non_discord_hooks:
                        new_config = hook_config.copy()
                        new_config['hooks'] = non_discord_hooks
                        filtered_hooks.append(new_config)
            
            if filtered_hooks:
                hooks[hook_type] = filtered_hooks
            else:
                del hooks[hook_type]
    
    # Write back the cleaned settings
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=2)
    
    return True

def remove_discord_integration():
    """Remove Discord integration from the current project"""
    
    project_name = DiscordUtils.get_project_name()
    
    # Check if Discord is configured
    if not DiscordUtils.check_state_exists():
        DiscordUtils.print_info(f"No Discord integration found in this project")
        print("")
        print(f"Current project: {project_name}")
        print("Status: Not configured")
        print("")
        print("To set up Discord integration:")
        print("• /user:discord:setup WEBHOOK_URL - Configure Discord integration")
        return True
    
    # Show current configuration
    DiscordUtils.print_header(f"Discord Integration Removal for {project_name}", "=")
    print("")
    
    # Get current state
    state = DiscordUtils.load_state()
    
    active = state.get('active', False)
    project_name_state = state.get('project_name', 'unknown')
    webhook_url = state.get('webhook_url', '')
    
    print("📊 Current Configuration:")
    print(f"  Project: {project_name_state}")
    
    if active:
        DiscordUtils.print_status_line("  Status", "Active", DiscordUtils.COLORS['ACTIVE'])
    else:
        DiscordUtils.print_status_line("  Status", "Disabled", DiscordUtils.COLORS['INACTIVE'])
    
    print(f"  Webhook: {DiscordUtils.mask_webhook_url(webhook_url)}")
    
    settings_exists = os.path.exists(".claude/settings.json")
    DiscordUtils.print_status_line("  Hooks", "Configured" if settings_exists else "Not configured", 
                                 DiscordUtils.COLORS['SUCCESS'] if settings_exists else DiscordUtils.COLORS['ERROR'])
    
    print("")
    
    # Warning and confirmation
    DiscordUtils.print_warning("WARNING: This will remove Discord integration from this project:")
    print("  • Delete .claude/discord-state.json")
    print("  • Remove Discord hooks from .claude/settings.json")
    print("  • Preserve other hooks and settings")
    print("")
    print("Global Discord components (in ~/.claude/) will NOT be affected.")
    print("")
    
    # Simple confirmation
    print("🔄 Proceeding with removal...")
    print("")
    
    # Create backup of settings.json
    if os.path.exists(".claude/settings.json"):
        print("📁 Creating backup of settings.json...")
        
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_file = f".claude/settings.json.backup-{timestamp}"
        
        try:
            shutil.copy2(".claude/settings.json", backup_file)
            DiscordUtils.print_success("Backup created")
        except Exception as e:
            DiscordUtils.print_error(f"Failed to create backup: {e}")
            return False
    
    # Remove discord-state.json
    if os.path.exists(".claude/discord-state.json"):
        try:
            os.remove(".claude/discord-state.json")
            DiscordUtils.print_success("Removed discord-state.json")
        except Exception as e:
            DiscordUtils.print_error(f"Failed to remove discord-state.json: {e}")
            return False
    
    # Remove Discord hooks from settings.json
    if os.path.exists(".claude/settings.json"):
        print("🔧 Removing Discord hooks from settings.json...")
        
        try:
            if remove_discord_hooks_from_settings():
                DiscordUtils.print_success("Discord hooks removed from settings.json")
            else:
                DiscordUtils.print_error("Failed to remove Discord hooks")
                return False
        except Exception as e:
            DiscordUtils.print_error(f"Error updating settings.json: {e}")
            return False
    else:
        DiscordUtils.print_info("No settings.json file found")
    
    # Success summary
    print("")
    print("=" * 50)
    DiscordUtils.print_success("Discord integration removal completed!")
    print("=" * 50)
    print("")
    
    print("📊 What was removed:")
    print("  • .claude/discord-state.json (Discord configuration)")
    print("  • Discord hooks from .claude/settings.json")
    print("")
    
    print("📁 What was preserved:")
    print("  • Other hooks in .claude/settings.json")
    print("  • Global Discord components in ~/.claude/")
    print("  • Backup of settings.json created")
    print("")
    
    print("🔄 To re-enable Discord integration:")
    print("  • /user:discord:setup WEBHOOK_URL - Reconfigure")
    print("")
    
    print("🗑️  To completely remove global Discord components:")
    print("  • curl -fsSL https://raw.githubusercontent.com/jubalm/claude-code-discord/main/uninstall.sh | bash -s -- --global")
    
    return True

def main():
    """Main entry point"""
    try:
        if remove_discord_integration():
            sys.exit(0)
        else:
            sys.exit(1)
    except Exception as e:
        DiscordUtils.print_error(f"Remove failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()