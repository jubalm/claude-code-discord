#!/bin/bash

# Discord PostToolUse Hook for Claude Code
# Event: PostToolUse (after each tool execution - shows work in progress)
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

# Extract information from the hook input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"')
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""')

# Function to escape JSON strings
escape_json() {
    local text="$1"
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
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚡ Work progress notification sent to $target - Session: ${SESSION_ID:0:8}" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ PostToolUse notification failed (HTTP $http_code) to $target - Session: ${SESSION_ID:0:8}" >> "$LOG_FILE"
    fi
}

# Generate contextual description based on tool type
get_tool_description() {
    local tool_name="$1"
    local tool_input="$2"
    
    case "$tool_name" in
        "Write"|"Edit"|"MultiEdit")
            local file_path=$(echo "$tool_input" | jq -r '.file_path // ""')
            echo "📝 Modified $(basename "$file_path")"
            ;;
        "Bash")
            local command=$(echo "$tool_input" | jq -r '.command // ""')
            echo "⚡ Executed: $(truncate_text "$command" 50)"
            ;;
        "Read")
            local file_path=$(echo "$tool_input" | jq -r '.file_path // ""')
            echo "📖 Read $(basename "$file_path")"
            ;;
        "TodoWrite"|"TodoRead")
            echo "📋 Updated task list"
            ;;
        "WebFetch"|"WebSearch")
            echo "🌐 Web research"
            ;;
        "Glob"|"Grep")
            echo "🔍 Code search"
            ;;
        *)
            echo "🔧 Used $tool_name"
            ;;
    esac
}

# Only notify for significant tools (avoid spam from minor operations)
case "$TOOL_NAME" in
    "Write"|"Edit"|"MultiEdit"|"Bash"|"TodoWrite")
        TOOL_DESCRIPTION=$(get_tool_description "$TOOL_NAME" "$TOOL_INPUT")
        ESCAPED_DESCRIPTION=$(escape_json "$TOOL_DESCRIPTION")
        
        # Build the progress notification embed
        EMBED_JSON=$(cat <<EOF
{
  "embeds": [{
    "title": "⚡ Work in Progress",
    "description": "$ESCAPED_DESCRIPTION",
    "color": 15844367,
    "fields": [
      {
        "name": "Session ID",
        "value": "\`${SESSION_ID:0:8}...\`",
        "inline": true
      },
      {
        "name": "Tool",
        "value": "$TOOL_NAME",
        "inline": true
      },
      {
        "name": "Timestamp",
        "value": "$(date '+%Y-%m-%d %H:%M:%S')",
        "inline": true
      }
    ],
    "footer": {
      "text": "Claude Code - Working..."
    }
  }]
}
EOF
)
        
        # Send the notification
        send_discord_message "$EMBED_JSON"
        ;;
    *)
        # Log but don't notify for minor tools
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔧 Tool used: $TOOL_NAME - Session: ${SESSION_ID:0:8}" >> "$LOG_FILE"
        ;;
esac

exit 0