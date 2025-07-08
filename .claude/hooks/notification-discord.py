#!/usr/bin/env python3

"""
Discord Notification Hook for Claude Code
Event: Notification (when Claude needs user input/attention)
Project-level Discord integration - only runs if project has opted in
"""

import json
import sys
import os
import urllib.request
import urllib.parse
from datetime import datetime
from pathlib import Path

LOG_FILE = Path.home() / ".claude" / "discord-notifications.log"

def log_message(message):
    """Log a message with timestamp."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(f"[{timestamp}] {message}\n")
    except Exception:
        pass  # Fail silently if logging fails

def load_discord_config():
    """Load and validate Discord configuration."""
    config_path = Path(".claude/discord-state.json")
    
    # Check if project has Discord integration enabled
    if not config_path.exists():
        # No Discord config for this project, exit silently
        sys.exit(0)
    
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        log_message("❌ Failed to read discord-state.json")
        sys.exit(0)
    
    # Check if Discord notifications are active for this project
    if not config.get('active', False):
        # Discord disabled for this project
        sys.exit(0)
    
    webhook_url = config.get('webhook_url', '')
    if not webhook_url:
        log_message("❌ No webhook URL configured in discord-state.json")
        sys.exit(0)
    
    return {
        'webhook_url': webhook_url,
        'thread_id': config.get('thread_id', ''),
        'auth_token': config.get('auth_token', ''),
        'project_name': config.get('project_name', 'Unknown Project')
    }

def parse_input():
    """Parse JSON input from stdin."""
    try:
        input_data = sys.stdin.read()
        if not input_data.strip():
            return {}
        return json.loads(input_data)
    except json.JSONDecodeError:
        return {}

def truncate_text(text, max_length=200):
    """Truncate text to specified length."""
    if not text:
        return ""
    if len(text) > max_length:
        return text[:max_length] + "..."
    return text

def send_discord_message(embed_data, config, session_id):
    """Send Discord message with thread support."""
    webhook_url = config['webhook_url']
    
    # Add thread_id if posting to thread
    if config['thread_id']:
        separator = '&' if '?' in webhook_url else '?'
        webhook_url = f"{webhook_url}{separator}thread_id={config['thread_id']}"
    
    try:
        # Prepare the request
        data = json.dumps(embed_data).encode('utf-8')
        
        req = urllib.request.Request(
            webhook_url,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        # Send the request
        with urllib.request.urlopen(req) as response:
            status_code = response.getcode()
        
        # Log the result
        target = f"thread {config['thread_id']}" if config['thread_id'] else "channel"
        session_short = session_id[:8] if session_id else 'unknown'
        
        if status_code == 204:
            log_message(f"🔔 Input needed notification sent to {target} - Session: {session_short}")
        else:
            log_message(f"❌ Notification failed (HTTP {status_code}) to {target} - Session: {session_short}")
            
    except Exception as e:
        target = f"thread {config['thread_id']}" if config['thread_id'] else "channel"
        session_short = session_id[:8] if session_id else 'unknown'
        log_message(f"❌ Notification failed ({str(e)}) to {target} - Session: {session_short}")

def create_notification_embed(session_id, message, title):
    """Create embed for input needed notification."""
    return {
        "embeds": [{
            "title": "🔔 Input Needed",
            "description": truncate_text(message, 200),
            "color": 3447003,  # Blue
            "fields": [
                {
                    "name": "Session ID",
                    "value": f"`{session_id[:8]}...`",
                    "inline": True
                },
                {
                    "name": "Timestamp",
                    "value": datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                    "inline": True
                },
                {
                    "name": "Source",
                    "value": title,
                    "inline": True
                }
            ],
            "footer": {
                "text": "Claude Code - Input Required"
            }
        }]
    }

def main():
    """Main function."""
    # Load configuration
    config = load_discord_config()
    
    # Parse input
    hook_input = parse_input()
    
    # Extract information from the hook input
    session_id = hook_input.get('session_id', 'unknown')
    message = hook_input.get('message', 'Claude needs your attention')
    title = hook_input.get('title', 'Claude Code')
    
    # Build the notification embed
    embed_data = create_notification_embed(session_id, message, title)
    
    # Send the notification
    send_discord_message(embed_data, config, session_id)

if __name__ == "__main__":
    main()