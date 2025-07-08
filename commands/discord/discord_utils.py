#!/usr/bin/env python3

"""
Shared utilities for Discord integration commands
Provides common functions for JSON handling, path detection, validation, and formatting
"""

import json
import os
import sys
import re
from pathlib import Path
from typing import Dict, Any, Optional, List, Tuple

class DiscordUtils:
    """Utility class for Discord integration operations"""
    
    # Color codes for output formatting
    COLORS = {
        'SUCCESS': '✅',
        'ERROR': '❌',
        'INFO': 'ℹ️',
        'WARNING': '⚠️',
        'ACTIVE': '🟢',
        'INACTIVE': '🔴',
        'LOCAL': '📍',
        'GLOBAL': '🌐',
        'THREAD': '🧵',
        'CHANNEL': '📢',
        'AUTH': '🔐',
        'SETTINGS': '🔧',
        'HOOKS': '🪝'
    }
    
    @staticmethod
    def get_installation_type() -> Tuple[str, str]:
        """
        Determine installation type and return paths
        Returns: (installation_type, commands_base, hooks_base)
        """
        local_commands = Path(".claude/commands/discord")
        local_hooks = Path(".claude/hooks")
        
        if local_commands.exists() and local_hooks.exists():
            return "local", ".claude/commands/discord", ".claude/hooks"
        else:
            home_commands = Path.home() / ".claude/commands/discord"
            home_hooks = Path.home() / ".claude/hooks"
            return "global", str(home_commands), str(home_hooks)
    
    @staticmethod
    def load_state(state_file: str = ".claude/discord-state.json") -> Dict[str, Any]:
        """Load Discord state from JSON file"""
        try:
            with open(state_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {}
    
    @staticmethod
    def save_state(state: Dict[str, Any], state_file: str = ".claude/discord-state.json") -> bool:
        """Save Discord state to JSON file"""
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(state_file), exist_ok=True)
            
            with open(state_file, 'w', encoding='utf-8') as f:
                json.dump(state, f, indent=2)
            return True
        except Exception as e:
            print(f"{DiscordUtils.COLORS['ERROR']} Failed to save state: {e}")
            return False
    
    @staticmethod
    def validate_webhook_url(url: str) -> bool:
        """Validate Discord webhook URL format"""
        if not url:
            return False
        
        pattern = r'^https://discord\.com/api/webhooks/\d+/[a-zA-Z0-9_-]+$'
        return bool(re.match(pattern, url))
    
    @staticmethod
    def mask_webhook_url(url: str) -> str:
        """Mask webhook URL for display"""
        if not url:
            return "Not configured"
        
        # Extract webhook ID and mask the token
        match = re.match(r'^(https://discord\.com/api/webhooks/\d+)/', url)
        if match:
            return f"{match.group(1)}/..."
        return "Invalid URL"
    
    @staticmethod
    def get_project_name() -> str:
        """Get current project name (directory name)"""
        return os.path.basename(os.getcwd())
    
    @staticmethod
    def parse_arguments(args_string: str) -> List[str]:
        """Parse space-separated arguments string"""
        if not args_string or not args_string.strip():
            return []
        return args_string.strip().split()
    
    @staticmethod
    def print_header(title: str, char: str = "=") -> None:
        """Print formatted header"""
        print(f"{DiscordUtils.COLORS['SETTINGS']} {title}")
        print(char * (len(title) + 2))
    
    @staticmethod
    def print_status_line(label: str, value: str, emoji: str = "") -> None:
        """Print formatted status line"""
        if emoji:
            print(f"{label}: {emoji} {value}")
        else:
            print(f"{label}: {value}")
    
    @staticmethod
    def print_success(message: str) -> None:
        """Print success message"""
        print(f"{DiscordUtils.COLORS['SUCCESS']} {message}")
    
    @staticmethod
    def print_error(message: str) -> None:
        """Print error message"""
        print(f"{DiscordUtils.COLORS['ERROR']} {message}")
    
    @staticmethod
    def print_info(message: str) -> None:
        """Print info message"""
        print(f"{DiscordUtils.COLORS['INFO']} {message}")
    
    @staticmethod
    def print_warning(message: str) -> None:
        """Print warning message"""
        print(f"{DiscordUtils.COLORS['WARNING']} {message}")
    
    @staticmethod
    def create_state_config(webhook_url: str, project_name: str, 
                           auth_token: Optional[str] = None, 
                           thread_id: Optional[str] = None) -> Dict[str, Any]:
        """Create initial state configuration"""
        config = {
            "active": False,
            "webhook_url": webhook_url,
            "project_name": project_name
        }
        
        if auth_token:
            config["auth_token"] = auth_token
        
        if thread_id:
            config["thread_id"] = thread_id
        
        return config
    
    @staticmethod
    def merge_hooks_config(settings_file: str = ".claude/settings.json") -> bool:
        """Merge Discord hooks into settings.json"""
        try:
            # Get installation paths
            install_type, commands_base, hooks_base = DiscordUtils.get_installation_type()
            
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
            
            # Load existing settings
            try:
                with open(settings_file, 'r', encoding='utf-8') as f:
                    settings = json.load(f)
            except (FileNotFoundError, json.JSONDecodeError):
                settings = {}
            
            # Ensure hooks section exists
            if 'hooks' not in settings:
                settings['hooks'] = {}
            
            # Merge Discord hooks
            settings['hooks'].update(discord_hooks)
            
            # Save back to file
            with open(settings_file, 'w', encoding='utf-8') as f:
                json.dump(settings, f, indent=2)
            
            return True
            
        except Exception as e:
            DiscordUtils.print_error(f"Failed to merge hooks: {e}")
            return False
    
    @staticmethod
    def backup_settings(settings_file: str = ".claude/settings.json") -> bool:
        """Create backup of settings file"""
        try:
            if os.path.exists(settings_file):
                import shutil
                backup_file = f"{settings_file}.backup"
                shutil.copy2(settings_file, backup_file)
                return True
            return False
        except Exception:
            return False
    
    @staticmethod
    def check_state_exists(state_file: str = ".claude/discord-state.json") -> bool:
        """Check if Discord state file exists"""
        return os.path.exists(state_file)
    
    @staticmethod
    def get_available_commands() -> List[str]:
        """Get list of available Discord commands"""
        return [
            "/user:discord:setup WEBHOOK_URL [AUTH_TOKEN] [THREAD_ID] - Setup Discord integration",
            "/user:discord:start [THREAD_ID] - Enable notifications",
            "/user:discord:stop - Disable notifications",
            "/user:discord:status - Check current status",
            "/user:discord:remove - Remove integration"
        ]
    
    @staticmethod
    def exit_with_error(message: str, code: int = 1) -> None:
        """Print error and exit"""
        DiscordUtils.print_error(message)
        sys.exit(code)
    
    @staticmethod
    def exit_with_success(message: str) -> None:
        """Print success and exit"""
        DiscordUtils.print_success(message)
        sys.exit(0)