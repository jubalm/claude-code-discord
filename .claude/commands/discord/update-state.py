#!/usr/bin/env python3

"""
Update Discord state JSON file
Replaces jq operations with pure Python
"""

import json
import sys
from pathlib import Path

def update_discord_state(state_file, action, thread_id=None):
    """Update Discord state based on action."""
    
    try:
        # Read existing state
        with open(state_file, 'r', encoding='utf-8') as f:
            state = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        state = {}
    
    if action == 'start':
        state['active'] = True
        if thread_id:
            state['thread_id'] = thread_id
    elif action == 'stop':
        state['active'] = False
    elif action == 'get_thread_id':
        # Just return the thread_id, don't modify file
        print(state.get('thread_id', ''))
        return
    
    # Write back to file
    with open(state_file, 'w', encoding='utf-8') as f:
        json.dump(state, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: update-state.py <state_file> <action> [thread_id]")
        print("Actions: start, stop, get_thread_id")
        sys.exit(1)
    
    state_file = sys.argv[1]
    action = sys.argv[2]
    thread_id = sys.argv[3] if len(sys.argv) > 3 else None
    
    try:
        update_discord_state(state_file, action, thread_id)
    except Exception as e:
        print(f"❌ Failed to update state: {e}")
        sys.exit(1)