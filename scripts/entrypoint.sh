#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
SERVER_PROPERTIES_DEFAULT="${SERVER_PROPERTIES_DEFAULT:-/defaults/server.properties}"

mkdir -p "$DATA_DIR/plugins" "$DATA_DIR/config" "$DATA_DIR/logs"

if [[ -f "$SERVER_PROPERTIES_DEFAULT" ]]; then
  cp "$SERVER_PROPERTIES_DEFAULT" "$DATA_DIR/server.properties"
fi

set_property() {
  local key="$1"
  local value="$2"
  local file="$DATA_DIR/server.properties"

  [[ -f "$file" ]] || return 0

  if grep -q "^${key}=" "$file"; then
    tmp="$(mktemp)"
    sed "s|^${key}=.*|${key}=${value}|" "$file" > "$tmp"
    cat "$tmp" > "$file"
    rm -f "$tmp"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

if [[ -n "${RCON_PASSWORD:-}" ]]; then
  set_property "rcon.password" "$RCON_PASSWORD"
fi

if [[ -n "${MANAGEMENT_SERVER_SECRET:-}" ]]; then
  set_property "management-server-secret" "$MANAGEMENT_SERVER_SECRET"
fi

exec "$@"
