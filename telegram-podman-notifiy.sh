#!/usr/bin/env bash
TOKEN="YOUR_TELEGRAM_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"
HOSTNAME=$(hostname)
LOGS=$(journalctl --user -u podman-auto-update.service -n 50)
if echo "$LOGS" | grep -q "rolling back"; then
    UNIT=$(echo "$LOGS" | grep "rolling back" | sed -n 's/.*unit "\(.*\)".*/\1/p' | head -n 1)
    STATUS="*ROLLBACK ON $HOSTNAME*"
    MESSAGE="The unit \`$UNIT\` failed after updating. Podman restored the previous version to keep the service online."
elif echo "$LOGS" | grep -q "updated"; then
    UNITS=$(echo "$LOGS" | grep "updated" | sed -n 's/.*unit "\(.*\)".*/\1/p' | paste -sd ", " -)
    STATUS=" *UPDATE SUCCESSFUL*"
    MESSAGE="The following units were updated successfully: \`$UNITS\`."
else
    exit 0
fi
TEXT="$STATUS%0A%0A$MESSAGE"
curl -s -X POST "$URL" \
     -d chat_id="$CHAT_ID" \
     -d text="$TEXT" \
     -d parse_mode="Markdown" > /dev/null
