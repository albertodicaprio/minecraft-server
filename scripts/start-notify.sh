#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"
: "${TELEGRAM_CHAT_ID:?TELEGRAM_CHAT_ID is required}"

trap 'exit 0' TERM INT

tail --pid="$$" -F "$DATA_DIR/logs/latest.log" | while read -r line; do
  if [[ "$line" == *"<"*">"* || "$line" == *"joined the game"* || "$line" == *"left the game"* || "$line" == *"This server is running Paper version"* || "$line" == *"Stopping server" ]]; then
    echo "$line"
    line_clean="$(echo "$line" | sed -E 's/^\[[0-9:]+\] \[[^]]+\]: (\[Not Secure\] )?//')"
    echo "SEND: $line_clean"
    curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=${line_clean}" >/dev/null
  fi
done
