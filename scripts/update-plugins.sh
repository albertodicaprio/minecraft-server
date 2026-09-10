#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
PLUGINS_DIR="$DATA_DIR/plugins"
OLD_DIR="$PLUGINS_DIR/old"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$PLUGINS_DIR" "$OLD_DIR"

TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
BACKUP_DIR="$OLD_DIR/$TIMESTAMP"

download_plugin() {
  local name="$1"
  local url="$2"

  local target="$PLUGINS_DIR/$name"
  local tmpfile="$TMP_DIR/$name"

  echo "Downloading $name..."
  curl -fsSL -o "$tmpfile" "$url"

  if [[ ! -f "$target" ]]; then
    echo "Installing new plugin: $name"
    mv "$tmpfile" "$target"
    return
  fi

  local old_hash
  local new_hash

  old_hash="$(sha256sum "$target" | awk '{print $1}')"
  new_hash="$(sha256sum "$tmpfile" | awk '{print $1}')"

  if [[ "$old_hash" == "$new_hash" ]]; then
    echo "$name is already up to date."
    rm -f "$tmpfile"
    return
  fi

  mkdir -p "$BACKUP_DIR"

  echo "Updating $name"
  echo "Backing up old version to $BACKUP_DIR"

  mv "$target" "$BACKUP_DIR/"
  mv "$tmpfile" "$target"
}

download_plugin \
  "Geyser-Spigot.jar" \
  "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot"

download_plugin \
  "floodgate-spigot.jar" \
  "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot"

echo "Plugin update complete."
