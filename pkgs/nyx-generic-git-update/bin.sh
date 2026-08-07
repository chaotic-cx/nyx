#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

# Options
HAS_CARGO="${HAS_CARGO:-0}"
HAS_SUBMODULES="${HAS_SUBMODULES:-0}"
WITH_LAST_DATE="${WITH_LAST_DATE:-0}"
WITH_LAST_STAMP="${WITH_LAST_STAMP:-0}"
WITH_BUMP_STAMP="${WITH_BUMP_STAMP:-0}"
_PNAME="$1"
_NYX_KEY="$2"
_MANIFEST_JSON="$3"
_GIT_URL="$4"
_LATEST_REV="$5"

_LOCAL_REV=$(jq -r .rev "$_MANIFEST_JSON")
[ "$_LOCAL_REV" == "$_LATEST_REV" ] && exit 0
_LOCAL_VER=$(jq -r .version "$_MANIFEST_JSON")

_NYX_DIR="$PWD"
_PKG_DIR=$(dirname "$_MANIFEST_JSON")

_NIX_PREFETCH_ARGS=(--quiet)
if [ "$HAS_SUBMODULES" -eq 1 ]; then
  _NIX_PREFETCH_ARGS+=(--fetch-submodules)
fi

if [[ "$_GIT_URL" == "https://github.com"*".git" ]] && [ "$HAS_SUBMODULES" -eq 0 ]; then
  _URL="${_GIT_URL%.git}/archive/$_LATEST_REV.tar.gz"
  _LATEST_META=$(nix flake prefetch --refresh --json "$_URL")
  _LATEST_HASH=$(echo "$_LATEST_META" | jq -r .hash)
  _LATEST_DATE="@$(echo "$_LATEST_META" | jq -r .locked.lastModified)"
  _LATEST_PATH=$(echo "$_LATEST_META" | jq -r .storePath)
elif [[ "$_GIT_URL" == *".git" ]]; then
  _LATEST_META=$(nix-prefetch-git "${_NIX_PREFETCH_ARGS[@]}" --rev "$_LATEST_REV" "$_GIT_URL")
  _LATEST_HASH=$(echo "$_LATEST_META" | jq -r .hash)
  _LATEST_DATE=$(echo "$_LATEST_META" | jq -r .date)
  _LATEST_PATH=$(echo "$_LATEST_META" | jq -r .path)
else
  echo 'Unsupported URL schema'
  exit 9
fi

echo "From: $_GIT_URL"
echo "Got: hash $_LATEST_HASH, date $_LATEST_DATE, path $_LATEST_PATH."

_LATEST_DATE_YMDHMS=$(date -u --date="$_LATEST_DATE" '+%Y%m%d%H%M%S')
_LATEST_VERSION="unstable-${_LATEST_DATE_YMDHMS}-${_LATEST_REV:0:7}"

JQ_ARGS=(
  --arg version "$_LATEST_VERSION"
  --arg rev "$_LATEST_REV"
  --arg hash "$_LATEST_HASH"
)

JQ_OPS=(
  '.rev = $rev'
  '| .version = $version'
  '| .hash = $hash'
)

if [ "$WITH_LAST_DATE" -eq 1 ]; then
  JQ_ARGS+=(--arg date "$_LATEST_DATE_YMDHMS")
  JQ_OPS+=('| .lastModifiedDate = $date')
elif [ "$WITH_LAST_DATE" -eq 3339 ]; then
  _LATEST_3339=$(date -u -Isec --date="$_LATEST_DATE")
  JQ_ARGS+=(--arg date "$_LATEST_3339")
  JQ_OPS+=('| .lastModifiedDate = $date')
fi

if [ "$WITH_BUMP_STAMP" -eq 1 ]; then
  _BUMP_STAMP=$(date -u '+%s')
  JQ_ARGS+=(--arg bump "$_BUMP_STAMP")
  JQ_OPS+=('| .bump = $bump')
fi

if [ "$WITH_LAST_STAMP" -eq 1 ]; then
  _LATEST_STAMP=$(date -u --date="$_LATEST_DATE" '+%s')
  JQ_ARGS+=(--arg stamp "$_LATEST_STAMP")
  JQ_OPS+=('| .lastModified = $stamp')
fi

if [ "$HAS_CARGO" -eq 1 ]; then
  JQ_ARGS+=(--arg cargo 'sha256-2342234223422342234223422342234223422342069=')
  JQ_OPS+=('| .cargoHash = $cargo')
fi

jq "${JQ_ARGS[@]}" \
  "${JQ_OPS[*]}" \
  "$_MANIFEST_JSON" | sponge "$_MANIFEST_JSON"

if [ "$HAS_CARGO" -eq 1 ]; then
  _LATEST_CARGO_HASH=$(nix build .#"${_NYX_KEY}".cargoDeps 2>&1 | grep "got:" | awk '{print $2}' || true)
  jq --arg cargo "$_LATEST_CARGO_HASH" \
    '.cargoHash = $cargo' \
    "$_MANIFEST_JSON" | sponge "$_MANIFEST_JSON"
fi

git add "$_MANIFEST_JSON"

# shellcheck disable=SC1090
[ -n "${WITH_EXTRA:-}" ] && source "$WITH_EXTRA"

# Conditionally disable GPG signing via env var
_GIT_COMMIT_OPTS=()
if [[ "${NYX_NO_GPG_SIGN:-}" == "1" ]]; then
  _GIT_COMMIT_OPTS+=(--no-gpg-sign)
fi

git commit "${_GIT_COMMIT_OPTS[@]}" -m "${_NYX_KEY}: ${_LOCAL_VER:9} -> ${_LATEST_VERSION:9}"
