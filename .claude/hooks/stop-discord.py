#!/usr/bin/env python3

"""
Discord Stop Hook for Claude Code
Event: Stop (when Claude finishes responding - task completion)
Project-level Discord integration - only runs if project has opted in
"""

import json
import sys
import os
import urllib.request
import urllib.parse
from datetime import datetime
from pathlib import Path
import re
import subprocess

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

def truncate_text(text, max_length=100):
    """Truncate text to specified length."""
    if not text:
        return ""
    if len(text) > max_length:
        return text[:max_length] + "..."
    return text

def parse_transcript(transcript_path):
    """Parse transcript and extract task summary (JSONL format)."""
    if not transcript_path or not Path(transcript_path).exists():
        return "", "", ""
    
    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        user_messages = ""
        tool_uses = []
        files_modified = []
        
        # Process last 10 lines for efficiency
        for line in lines[-10:]:
            try:
                entry = json.loads(line.strip())
                
                # Extract recent user messages (exclude tool results)
                if (entry.get('type') == 'user' and 
                    'tool_use_id' not in entry.get('message', {})):
                    user_messages = entry.get('message', {}).get('content', '')
                
                # Extract tool usage from assistant messages
                if entry.get('type') == 'assistant':
                    content = entry.get('message', {}).get('content', [])
                    if isinstance(content, list):
                        for item in content:
                            if isinstance(item, dict) and item.get('type') == 'tool_use':
                                tool_name = item.get('name')
                                if tool_name:
                                    tool_uses.append(tool_name)
                                
                                # Extract file paths for file modification tools
                                if tool_name in ['Write', 'Edit', 'MultiEdit']:
                                    file_path = item.get('input', {}).get('file_path')
                                    if file_path:
                                        files_modified.append(Path(file_path).name)
            
            except (json.JSONDecodeError, AttributeError):
                continue
        
        # Count and format tool uses
        tool_counts = {}
        for tool in tool_uses:
            tool_counts[tool] = tool_counts.get(tool, 0) + 1
        
        tool_summary = " ".join([f"{count}x {tool}" for tool, count in 
                                sorted(tool_counts.items(), key=lambda x: x[1], reverse=True)])
        
        # Deduplicate files
        files_summary = " ".join(sorted(set(files_modified)))
        
        return user_messages, tool_summary, files_summary
        
    except Exception as e:
        log_message(f"[DEBUG] Transcript parsing error: {e}")
        return "", "", ""

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
            log_message(f"✅ Session complete notification sent to {target} - Session: {session_short}")
        else:
            log_message(f"❌ Session complete notification failed (HTTP {status_code}) to {target} - Session: {session_short}")
            
    except Exception as e:
        target = f"thread {config['thread_id']}" if config['thread_id'] else "channel"
        session_short = session_id[:8] if session_id else 'unknown'
        log_message(f"❌ Session complete notification failed ({str(e)}) to {target} - Session: {session_short}")

def create_stop_embed(hook_input, config):
    """Create embed for Stop hook."""
    session_id = hook_input.get('session_id', 'unknown')
    transcript_path = hook_input.get('transcript_path', '')
    tool_name = hook_input.get('tool_name', '')
    tool_input = hook_input.get('tool_input', {})
    message = hook_input.get('message', '')
    
    # Parse transcript for enhanced details
    user_task, tool_summary, files_modified = parse_transcript(transcript_path)
    
    # Debug logging
    log_message(f"[DEBUG] Transcript path: {transcript_path}")
    log_message(f"[DEBUG] User task: '{user_task}'")
    log_message(f"[DEBUG] Tool summary: '{tool_summary}'")
    log_message(f"[DEBUG] Files modified: '{files_modified}'")
    
    # Fallback: Use hook input data if transcript parsing failed
    if not user_task and tool_name:
        user_task = f"Used {tool_name} tool"
        log_message(f"[DEBUG] Using fallback task description: {user_task}")
    
    # Format tool summary
    tool_display = "None"
    if tool_summary:
        # Format as bullet points, limit to 3
        tools = tool_summary.split()[:3]
        tool_display = "\n".join([f"• {tool}" for tool in tools])
    elif tool_name:
        tool_display = f"• {tool_name}"
        log_message(f"[DEBUG] Using fallback tool display: {tool_display}")
    
    # Format files modified
    files_display = "None"
    if files_modified:
        # Format as bullet points, limit to 3
        files = files_modified.split()[:3]
        files_display = "\n".join([f"• {file}" for file in files])
    elif isinstance(tool_input, dict) and tool_input.get('file_path'):
        fallback_file = Path(tool_input['file_path']).name
        files_display = f"• {fallback_file}"
        log_message(f"[DEBUG] Using fallback file display: {files_display}")
    
    # Build description
    description = "Session completed successfully"
    if user_task:
        description = truncate_text(user_task, 150)
    
    return {
        "embeds": [{
            "title": "✅ Session Complete",
            "description": description,
            "color": 5763719,  # Green
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
                    "name": "Tools Used",
                    "value": tool_display,
                    "inline": False
                },
                {
                    "name": "Files Modified",
                    "value": files_display,
                    "inline": False
                }
            ],
            "footer": {
                "text": "Claude Code - Session Complete"
            }
        }]
    }

def create_notification_embed(hook_input, config):
    """Create embed for Notification hook."""
    session_id = hook_input.get('session_id', 'unknown')
    message = hook_input.get('message', 'Claude needs your attention')
    
    return {
        "embeds": [{
            "title": "🔔 Task Needs Input",
            "description": truncate_text(message, 150),
            "color": 16776960,  # Yellow
            "fields": [
                {
                    "name": "Action Required",
                    "value": "Please check your Claude Code session",
                    "inline": False
                },
                {
                    "name": "Session ID",
                    "value": f"`{session_id[:8]}...`",
                    "inline": True
                }
            ],
            "footer": {
                "text": f"Claude Code - {datetime.now().strftime('%H:%M:%S')}"
            }
        }]
    }

def create_posttooluse_embed(hook_input, config):
    """Create embed for PostToolUse hook."""
    session_id = hook_input.get('session_id', 'unknown')
    tool_name = hook_input.get('tool_name', 'unknown')
    tool_input = hook_input.get('tool_input', {})
    
    # Extract relevant info based on tool type
    if tool_name in ['Write', 'Edit', 'MultiEdit']:
        file_path = tool_input.get('file_path', '') if isinstance(tool_input, dict) else ''
        tool_desc = f"📝 Modified {Path(file_path).name if file_path else 'file'}"
    elif tool_name == 'Bash':
        command = tool_input.get('command', '') if isinstance(tool_input, dict) else ''
        tool_desc = f"⚡ Executed: {truncate_text(command, 50)}"
    elif tool_name == 'Read':
        file_path = tool_input.get('file_path', '') if isinstance(tool_input, dict) else ''
        tool_desc = f"📖 Read {Path(file_path).name if file_path else 'file'}"
    else:
        tool_desc = f"🔧 Used {tool_name}"
    
    return {
        "embeds": [{
            "title": "⚡ Work in Progress",
            "description": tool_desc,
            "color": 16737792,  # Gold
            "fields": [
                {
                    "name": "Session ID",
                    "value": f"`{session_id[:8]}...`",
                    "inline": True
                },
                {
                    "name": "Timestamp",
                    "value": datetime.now().strftime('%H:%M:%S'),
                    "inline": True
                }
            ],
            "footer": {
                "text": "Claude Code - Tool Activity"
            }
        }]
    }

def main():
    """Main function."""
    # Load configuration
    config = load_discord_config()
    
    # Parse input
    hook_input = parse_input()
    
    # Get hook type and session ID
    hook_type = hook_input.get('hook_type', 'Stop')
    session_id = hook_input.get('session_id', 'unknown')
    
    # For Stop hooks, check if we're in a loop
    if hook_type == 'Stop':
        stop_active = hook_input.get('stop_hook_active', False)
        if stop_active:
            sys.exit(0)
    
    # Create appropriate embed based on hook type
    if hook_type == 'Stop':
        embed_data = create_stop_embed(hook_input, config)
        send_discord_message(embed_data, config, session_id)
    elif hook_type == 'Notification':
        embed_data = create_notification_embed(hook_input, config)
        send_discord_message(embed_data, config, session_id)
    elif hook_type == 'PostToolUse':
        # Only send notification for significant tools (uncomment to enable)
        # embed_data = create_posttooluse_embed(hook_input, config)
        # send_discord_message(embed_data, config, session_id)
        pass

if __name__ == "__main__":
    main()