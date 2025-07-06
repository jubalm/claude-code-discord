#!/bin/bash

# Discord Stop Hook for Claude Code  
# Event: Stop (when Claude finishes responding - task completion)
# Project-level Discord integration - only runs if project has opted in

LOG_FILE="$HOME/.claude/discord-notifications.log"

# Check if project has Discord integration enabled
if [ ! -f ".claude/discord-state.json" ]; then
    # No Discord config for this project, exit silently
    exit 0
fi

# Read project Discord state
DISCORD_STATE=$(cat .claude/discord-state.json 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Failed to read discord-state.json" >> "$LOG_FILE"
    exit 0
fi

# Check if Discord notifications are active for this project
ACTIVE=$(echo "$DISCORD_STATE" | jq -r '.active // false' 2>/dev/null)
if [ "$ACTIVE" != "true" ]; then
    # Discord disabled for this project
    exit 0
fi

# Get Discord configuration
DISCORD_WEBHOOK_URL=$(echo "$DISCORD_STATE" | jq -r '.webhook_url // ""' 2>/dev/null)
THREAD_ID=$(echo "$DISCORD_STATE" | jq -r '.thread_id // ""' 2>/dev/null)
AUTH_TOKEN=$(echo "$DISCORD_STATE" | jq -r '.auth_token // ""' 2>/dev/null)

if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ No webhook URL configured in discord-state.json" >> "$LOG_FILE"
    exit 0
fi

# Read JSON input from stdin
INPUT=$(cat)

# Test function for debugging (uncomment to use)
# test_transcript_parsing() {
#     echo "=== TRANSCRIPT PARSING TEST ===" >> "$LOG_FILE"
#     if [ -f "$TRANSCRIPT_PATH" ]; then
#         echo "File exists: $TRANSCRIPT_PATH" >> "$LOG_FILE"
#         echo "File size: $(wc -c < "$TRANSCRIPT_PATH") bytes" >> "$LOG_FILE"
#         echo "First 200 chars:" >> "$LOG_FILE"
#         head -c 200 "$TRANSCRIPT_PATH" >> "$LOG_FILE"
#         echo "" >> "$LOG_FILE"
#     else
#         echo "File not found: $TRANSCRIPT_PATH" >> "$LOG_FILE"
#     fi
#     echo "=== END TEST ===" >> "$LOG_FILE"
# }

# Extract information from the hook input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
HOOK_TYPE=$(echo "$INPUT" | jq -r '.hook_type // "Stop"')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"')
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""')
MESSAGE=$(echo "$INPUT" | jq -r '.message // ""')

# For Stop hooks, check if we're in a loop
if [ "$HOOK_TYPE" = "Stop" ]; then
    STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
    if [ "$STOP_ACTIVE" = "true" ]; then
        exit 0
    fi
fi

# Function to parse transcript and extract task summary (JSONL format)
parse_transcript() {
    local transcript_path="$1"
    
    if [ -f "$transcript_path" ]; then
        # Extract recent user messages from JSONL format (exclude tool results)
        local user_messages=$(grep '"type":"user"' "$transcript_path" | grep -v '"tool_use_id"' | tail -1 | jq -r '.message.content // ""' 2>/dev/null || echo "")
        
        # Extract tool usage from assistant messages with tool_use content (remove newlines)
        local tool_uses=$(grep '"type":"assistant"' "$transcript_path" | tail -10 | jq -r '.message.content[]? | select(.type == "tool_use") | .name' 2>/dev/null | sort | uniq -c | sort -nr | tr '\n' ' ' || echo "")
        
        # Extract files modified from tool inputs (deduplicate and use basename)
        local files_modified=$(grep '"type":"assistant"' "$transcript_path" | tail -10 | jq -r '.message.content[]? | select(.type == "tool_use" and (.name == "Write" or .name == "Edit" or .name == "MultiEdit")) | .input.file_path' 2>/dev/null | xargs -I {} basename {} | sort | uniq | tr '\n' ' ' || echo "")
        
        echo "$user_messages|||$tool_uses|||$files_modified"
    else
        echo "|||"
    fi
}

# Simplified Stop hook - just shows session completion

# Function to escape JSON strings
escape_json() {
    local text="$1"
    # Escape backslashes, quotes, and newlines for JSON
    echo "$text" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//'
}

# Function to truncate text
truncate_text() {
    local text="$1"
    local max_length="${2:-100}"
    
    if [ ${#text} -gt $max_length ]; then
        echo "${text:0:$max_length}..."
    else
        echo "$text"
    fi
}

# Function to send Discord message with thread support
send_discord_message() {
    local embed="$1"
    
    # Determine webhook URL - add thread_id if posting to thread
    local webhook_url="$DISCORD_WEBHOOK_URL"
    if [ -n "$THREAD_ID" ] && [ "$THREAD_ID" != "" ]; then
        webhook_url="${DISCORD_WEBHOOK_URL}?thread_id=${THREAD_ID}"
    fi
    
    # Send the message
    local curl_response=$(curl -s -w "%{http_code}" -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "$embed" 2>/dev/null)
    
    # Log the notification with status
    local http_code="${curl_response: -3}"
    local target="channel"
    if [ -n "$THREAD_ID" ] && [ "$THREAD_ID" != "" ]; then
        target="thread $THREAD_ID"
    fi
    
    if [ "$http_code" = "204" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Session complete notification sent to $target - Session: ${SESSION_ID:0:8}" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Session complete notification failed (HTTP $http_code) to $target - Session: ${SESSION_ID:0:8}" >> "$LOG_FILE"
    fi
}

# Determine the message based on context
case "$HOOK_TYPE" in
    "Stop")
        # Task completion notification with enhanced details
        TRANSCRIPT_DATA=$(parse_transcript "$TRANSCRIPT_PATH")
        USER_TASK=$(echo "$TRANSCRIPT_DATA" | awk -F'\\|\\|\\|' '{print $1}')
        TOOL_SUMMARY=$(echo "$TRANSCRIPT_DATA" | awk -F'\\|\\|\\|' '{print $2}')
        FILES_MODIFIED=$(echo "$TRANSCRIPT_DATA" | awk -F'\\|\\|\\|' '{print $3}')
        
        # Debug logging
        echo "[DEBUG] Transcript path: $TRANSCRIPT_PATH" >> "$LOG_FILE"
        echo "[DEBUG] User task: '$USER_TASK'" >> "$LOG_FILE"
        echo "[DEBUG] Tool summary: '$TOOL_SUMMARY'" >> "$LOG_FILE"
        echo "[DEBUG] Files modified: '$FILES_MODIFIED'" >> "$LOG_FILE"
        
        # Fallback: Use hook input data if transcript parsing failed
        if [ -z "$USER_TASK" ] || [ "$USER_TASK" = "" ]; then
            if [ -n "$TOOL_NAME" ] && [ "$TOOL_NAME" != "" ]; then
                USER_TASK="Used $TOOL_NAME tool"
                echo "[DEBUG] Using fallback task description: $USER_TASK" >> "$LOG_FILE"
            fi
        fi
        
        # Format tool summary
        TOOL_DISPLAY="None"
        if [ -n "$TOOL_SUMMARY" ] && [ "$TOOL_SUMMARY" != "" ]; then
            TOOL_DISPLAY=$(echo "$TOOL_SUMMARY" | head -3 | sed 's/^[[:space:]]*/• /')
        elif [ -n "$TOOL_NAME" ] && [ "$TOOL_NAME" != "" ]; then
            # Fallback: Use current tool info
            TOOL_DISPLAY="• $TOOL_NAME"
            echo "[DEBUG] Using fallback tool display: $TOOL_DISPLAY" >> "$LOG_FILE"
        fi
        
        # Format files modified
        FILES_DISPLAY="None"
        if [ -n "$FILES_MODIFIED" ] && [ "$FILES_MODIFIED" != "" ]; then
            FILES_DISPLAY=$(echo "$FILES_MODIFIED" | head -3 | sed 's/^/• /' | tr '\n' ' ')
        elif [ -n "$TOOL_INPUT" ] && [ "$TOOL_INPUT" != "{}" ]; then
            # Fallback: Extract file path from current tool input
            FALLBACK_FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""' 2>/dev/null)
            if [ -n "$FALLBACK_FILE" ] && [ "$FALLBACK_FILE" != "" ]; then
                FILES_DISPLAY="• $(basename "$FALLBACK_FILE")"
                echo "[DEBUG] Using fallback file display: $FILES_DISPLAY" >> "$LOG_FILE"
            fi
        fi
        
        # Build description with proper escaping
        DESCRIPTION="Session completed successfully"
        if [ -n "$USER_TASK" ] && [ "$USER_TASK" != "" ]; then
            DESCRIPTION="$(escape_json "$(truncate_text "$USER_TASK" 150)")"
        fi
        
        # Escape all display fields
        TOOL_DISPLAY_ESCAPED="$(escape_json "$TOOL_DISPLAY")"
        FILES_DISPLAY_ESCAPED="$(escape_json "$FILES_DISPLAY")"
        
        EMBED_JSON=$(cat <<EOF
{
  "embeds": [{
    "title": "✅ Session Complete",
    "description": "$DESCRIPTION",
    "color": 5763719,
    "fields": [
      {
        "name": "Session ID",
        "value": "\`${SESSION_ID:0:8}...\`",
        "inline": true
      },
      {
        "name": "Timestamp",
        "value": "$(date '+%Y-%m-%d %H:%M:%S')",
        "inline": true
      },
      {
        "name": "Tools Used",
        "value": "$TOOL_DISPLAY_ESCAPED",
        "inline": false
      },
      {
        "name": "Files Modified",
        "value": "$FILES_DISPLAY_ESCAPED",
        "inline": false
      }
    ],
    "footer": {
      "text": "Claude Code - Session Complete"
    }
  }]
}
EOF
)
        send_discord_message "" "$EMBED_JSON"
        ;;
        
    "Notification")
        # Claude needs input
        EMBED_JSON=$(cat <<EOF
{
  "embeds": [{
    "title": "🔔 Task Needs Input",
    "description": "$(truncate_text "$MESSAGE" 150)",
    "color": 16776960,
    "fields": [
      {
        "name": "Action Required",
        "value": "Please check your Claude Code session",
        "inline": false
      },
      {
        "name": "Session ID",
        "value": "\`${SESSION_ID:0:8}...\`",
        "inline": true
      }
    ],
    "footer": {
      "text": "Claude Code - $(date '+%H:%M:%S')"
    }
  }]
}
EOF
)
        send_discord_message "" "$EMBED_JSON"
        ;;
        
    "PostToolUse")
        # Tool completion with contextual information
        if [ -n "$TOOL_NAME" ]; then
            # Extract relevant info based on tool type
            case "$TOOL_NAME" in
                "Write"|"Edit"|"MultiEdit")
                    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
                    TOOL_DESC="📝 Modified $(basename "$FILE_PATH")"
                    ;;
                "Bash")
                    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')
                    TOOL_DESC="⚡ Executed: $(truncate_text "$COMMAND" 50)"
                    ;;
                "Read")
                    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
                    TOOL_DESC="📖 Read $(basename "$FILE_PATH")"
                    ;;
                *)
                    TOOL_DESC="🔧 Used $TOOL_NAME"
                    ;;
            esac
            
            # Only send notification for significant tools (uncomment to enable)
            # send_discord_message "$TOOL_DESC"
        fi
        ;;
esac

exit 0
