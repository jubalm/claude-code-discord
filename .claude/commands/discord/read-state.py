#!/usr/bin/env python3

"""
Read values from Discord state JSON file
Replaces jq read operations with pure Python
"""

import json
import sys
from pathlib import Path

def read_discord_state(state_file, key, default=""):
    """Read a specific key from Discord state."""
    
    try:
        # Read existing state
        with open(state_file, 'r', encoding='utf-8') as f:
            state = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        state = {}
    
    # Get the value with default fallback
    value = state.get(key, default)
    
    # Handle boolean values
    if isinstance(value, bool):
        print("true" if value else "false")
    else:
        print(value)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: read-state.py <state_file> <key> [default]")
        sys.exit(1)
    
    state_file = sys.argv[1]
    key = sys.argv[2]
    default = sys.argv[3] if len(sys.argv) > 3 else ""
    
    try:
        read_discord_state(state_file, key, default)
    except Exception as e:
        print(default)  # Return default on any error