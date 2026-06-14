#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"

cd "$DATA_DIR"

echo "Checking for Paper updates..."
PAPER_VERSIONS="$(curl -fsS -H "accept: application/json" "https://fill.papermc.io/v3/projects/paper")"
LATEST_PAPER="$(echo "$PAPER_VERSIONS" | jq -r '
  .versions
  | to_entries
  | map(.value[])
  | flatten
  | map(select(test("-(rc|pre|beta|alpha)"; "i") | not))
  | .[0]
')"

LATEST_BUILD_INFO="$(curl -fsS -H "accept: application/json" "https://fill.papermc.io/v3/projects/paper/versions/${LATEST_PAPER}/builds/latest")"
LATEST_NAME="$(echo "$LATEST_BUILD_INFO" | jq -r '.downloads."server:default".name')"
LATEST_URL="$(echo "$LATEST_BUILD_INFO" | jq -r '.downloads."server:default".url')"
LATEST_SHA256="$(echo "$LATEST_BUILD_INFO" | jq -r '.downloads."server:default".checksums.sha256')"

echo "URL : $LATEST_URL"
echo "NAME: $LATEST_NAME"
echo "SHA : $LATEST_SHA256"

CURRENT_NAME="$(cat current_paper.txt 2>/dev/null || true)"

if [[ -z "$LATEST_NAME" || "$LATEST_NAME" == "null" ]]; then
  if [[ -n "$CURRENT_NAME" && -f "$CURRENT_NAME" ]]; then
    echo "Failed getting latest version. Keeping previous version: $CURRENT_NAME"
    exit 0
  fi

  echo "Failed getting latest version and no local Paper jar exists." >&2
  exit 1
fi

if [[ "$CURRENT_NAME" == "$LATEST_NAME" && -f "$CURRENT_NAME" ]]; then
  echo "Already at latest Paper: $CURRENT_NAME"
  exit 0
fi

echo "Downloading $LATEST_URL"
curl -fsSLo "$LATEST_NAME" "$LATEST_URL"

echo "$LATEST_SHA256 *$LATEST_NAME" > check.sum
if sha256sum -c check.sum; then
  echo "$LATEST_NAME" > current_paper.txt
  CURRENT_NAME="$LATEST_NAME"
else
  rm -f "$LATEST_NAME" check.sum
  echo "Checksum failed. Keeping previous version." >&2
  exit 1
fi
rm -f check.sum

old_versions="$(find . -maxdepth 1 -name 'paper-*.jar' -printf '%T@ %p\n' | sort -nr | awk 'NR > 2 {print $2}')"
if [[ -n "$old_versions" ]]; then
  echo "$old_versions" | xargs -r rm --
fi
