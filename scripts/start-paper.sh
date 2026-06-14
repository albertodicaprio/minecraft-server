#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
JAVA_MEMORY="${JAVA_MEMORY:-12G}"
UPDATE_PLUGINS_ON_START="${UPDATE_PLUGINS_ON_START:-true}"
ENABLE_TELEGRAM_NOTIFY="${ENABLE_TELEGRAM_NOTIFY:-true}"
ENABLE_TELEGRAM_TO_MC="${ENABLE_TELEGRAM_TO_MC:-true}"

cd "$DATA_DIR"

/opt/minecraft/scripts/download-paper.sh

if [[ "$UPDATE_PLUGINS_ON_START" == "true" ]]; then
  /opt/minecraft/scripts/update-plugins.sh
fi

CURRENT_NAME="$(cat current_paper.txt)"

helper_pids=()
minecraft_pid=""
stopping=false
helper_stop_timeout="${HELPER_STOP_TIMEOUT_SECONDS:-10}"

start_helper() {
  local name="$1"
  shift

  echo "Starting $name..."
  setsid "$@" &
  helper_pids+=("$!")
}

terminate_process_group() {
  local pid="$1"

  if kill -0 "$pid" 2>/dev/null; then
    kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
  fi
}

kill_process_group() {
  local pid="$1"

  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL -- "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
  fi
}

stop_helpers() {
  local pid
  local deadline
  local running

  if (( ${#helper_pids[@]} == 0 )); then
    return
  fi

  for pid in "${helper_pids[@]}"; do
    terminate_process_group "$pid"
  done

  deadline=$((SECONDS + helper_stop_timeout))
  while (( SECONDS < deadline )); do
    running=false
    for pid in "${helper_pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        running=true
        break
      fi
    done

    if [[ "$running" == "false" ]]; then
      wait "${helper_pids[@]}" 2>/dev/null || true
      return
    fi

    sleep 1
  done

  for pid in "${helper_pids[@]}"; do
    kill_process_group "$pid"
  done

  wait "${helper_pids[@]}" 2>/dev/null || true
}

stop_all() {
  if [[ "$stopping" == "true" ]]; then
    return
  fi

  stopping=true
  echo "Stopping Minecraft server and background helpers..."

  if [[ -n "$minecraft_pid" ]] && kill -0 "$minecraft_pid" 2>/dev/null; then
    kill -TERM "$minecraft_pid" 2>/dev/null || true
  fi

  stop_helpers
}

trap stop_all TERM INT

if [[ "$ENABLE_TELEGRAM_NOTIFY" == "true" ]]; then
  start_helper "Telegram notifier" /opt/minecraft/scripts/start-notify.sh
fi

if [[ "$ENABLE_TELEGRAM_TO_MC" == "true" ]]; then
  start_helper "Telegram to Minecraft bridge" /opt/minecraft/scripts/telegram-to-mc.sh
fi

java ${JAVA_OPTS:-} -Xms"$JAVA_MEMORY" -Xmx"$JAVA_MEMORY" -jar "$CURRENT_NAME" --nogui &
minecraft_pid="$!"

set +e
wait "$minecraft_pid"
exit_code="$?"
set -e

stop_helpers

exit "$exit_code"
