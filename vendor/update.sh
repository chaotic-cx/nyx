#!/usr/bin/env bash
set -euo pipefail

function eachFlake() {
  # Define your target file
  FILE="vendor/flakes/$1/manifest.json"

  # Extract the base URL
  BASE_URL=$(jq -r '.url' "$FILE")
  OLD_LOCK=$(jq -r '.lock' "$FILE")

  TRACK_FILE="vendor/flakes/$1/track"
  if [ -e "$TRACK_FILE" ]; then
    if ! TRACK=$(cat "$TRACK_FILE") || [[ "$TRACK" != latest-tag || "$BASE_URL" != github:* ]]; then
      printf '%s: track must contain latest-tag and url must start with github:\n' "$1" >&2
      return 0
    fi

    if ! TAG=$(git -c versionsort.suffix=- ls-remote --tags --refs --sort=-version:refname \
      "https://github.com/${BASE_URL#github:}" 'refs/tags/v[0-9]*' | awk 'NR == 1 { print $2 }') || [ -z "$TAG" ]; then
      printf '%s: could not resolve latest version tag for %s\n' "$1" "$BASE_URL" >&2
      return 0
    fi
    BASE_URL="$BASE_URL?ref=$TAG"
  fi

  # Fetch the fresh metadata
  NEW_METADATA=$(nix flake metadata --json "$BASE_URL")

  # Get the new full URL from metadata
  NEW_LOCK=$(printf "%s\n" "$NEW_METADATA" | jq -r '.url')

  # Skip the rest when already up-to-date
  if [ "$NEW_LOCK" = "$OLD_LOCK" ]; then
    return 0
  fi

  # Fetch the old metadata
  OLD_METADATA=$(nix flake metadata --json "$OLD_LOCK")

  # Update the JSON file
  OLD_FILE=$(cat "$FILE")
  printf "%s\n" "$OLD_FILE" | jq --arg lock "$NEW_LOCK" '.lock = $lock' >"$FILE"

  # Commit
  git add "$FILE"
  git commit -m "$1: $(printf "%s\n" "$OLD_METADATA" | jq -r '.lastModified') -> $(printf "%s\n" "$NEW_METADATA" | jq -r '.lastModified')"
}

if [ -n "${1:-}" ]; then
  eachFlake "$@"
else
  for f in vendor/flakes/*; do
    [ "$f" = 'vendor/flakes/*' ] && continue
    [ -e "$f/pin" ] && continue
    eachFlake "$(basename "$f")"
  done
fi

exit 0
