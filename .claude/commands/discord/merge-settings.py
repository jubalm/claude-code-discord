#!/usr/bin/env python3

"""
Merge Discord hooks into existing Claude settings.json
This replaces the complex jq operation with pure Python
"""

import json
import sys
from pathlib import Path

def merge_discord_hooks(settings_file):
    """Merge Discord hooks into existing settings."""
    
    # Determine hook paths (local-first, fallback to global)
    if Path(".claude/hooks/stop-discord.py").exists():
        # Local installation
        hooks_base = ".claude/hooks"
    else:
        # Global installation
        hooks_base = "$HOME/.claude/hooks"
    
    # Discord hooks configuration
    discord_hooks = {
        "Stop": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"{hooks_base}/stop-discord.py"
                    }
                ]
            }
        ],
        "Notification": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"{hooks_base}/notification-discord.py"
                    }
                ]
            }
        ],
        "PostToolUse": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": f"{hooks_base}/posttooluse-discord.py"
                    }
                ]
            }
        ]
    }
    
    try:
        # Read existing settings
        with open(settings_file, 'r', encoding='utf-8') as f:
            settings = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        settings = {}
    
    # Ensure hooks section exists
    if 'hooks' not in settings:
        settings['hooks'] = {}
    
    # Merge Discord hooks (this will override existing Discord hooks if they exist)
    settings['hooks'].update(discord_hooks)
    
    # Write back to file
    with open(settings_file, 'w', encoding='utf-8') as f:
        json.dump(settings, f, indent=2)
    
    return True

if __name__ == "__main__":
    settings_file = sys.argv[1] if len(sys.argv) > 1 else ".claude/settings.json"
    
    try:
        merge_discord_hooks(settings_file)
        print("✅ Discord hooks merged successfully")
    except Exception as e:
        print(f"❌ Failed to merge settings: {e}")
        sys.exit(1)