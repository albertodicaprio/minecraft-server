#!/usr/bin/env bash
set -euo pipefail

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"
: "${RCON_PASSWORD:?RCON_PASSWORD is required}"

RCON_HOST="${RCON_HOST:-127.0.0.1}"
RCON_PORT="${RCON_PORT:-25575}"
MCRCON_BIN="${MCRCON_BIN:-mcrcon}"
OFFSET=0

while true; do
  if ! UPDATES="$(curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}")"; then
    echo "Could not fetch Telegram updates." >&2
    sleep 5
    continue
  fi

  IDS="$(echo "$UPDATES" | jq -r '.result[].update_id')"

  for ID in $IDS; do
    MESSAGE="$(echo "$UPDATES" | jq -r --argjson id "$ID" '
      .result[] | select(.update_id == $id) | .message.text // empty
    ')"

    OFFSET=$((ID + 1))

    if [[ -n "$MESSAGE" ]]; then
      echo "Server said: $MESSAGE"

      if ! "$MCRCON_BIN" -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" \
        "tellraw @a {\"text\":\"[Server] $MESSAGE\",\"color\":\"dark_red\"}"; then
        echo "Could not send Telegram message to Minecraft over RCON." >&2
      fi
    fi
  done

  sleep 2
done
