{ writeShellScriptBin
, lib
, coreutils
, findutils
, curl
, gawk
, jq
, git
, nix
, nix-prefetch-git
, moreutils
, nyxUtils
}:
let
  path = lib.makeBinPath [
    gawk
    coreutils
    curl
    findutils
    jq
    moreutils
    git
    nix-prefetch-git
    nix
  ];
in
(writeShellScriptBin "nyx-generic-update" ''
  set -euo pipefail

  PATH=${path}

  # Options
  HAS_CARGO="''${HAS_CARGO:-0}"
  HAS_SUBMODULES="''${HAS_SUBMODULES:-0}"
  WITH_LAST_DATE="''${WITH_LAST_DATE:-0}"
  WITH_LAST_STAMP="''${WITH_LAST_STAMP:-0}"
  _PNAME="$1"
  _NYX_KEY="$2"
  _VERSION_JSON="$3"
  _GIT_URL="$4"
  _LATEST_REV="$5"

  _LOCAL_REV=$(jq -r .rev "$_VERSION_JSON")
  [ "$_LOCAL_REV" == "$_LATEST_REV" ] && exit 0
  _LOCAL_VER=$(jq -r .version "$_VERSION_JSON")

  _PKG_DIR=$(dirname "$_VERSION_JSON")

  _NIX_PREFETCH_ARGS=(--quiet)
  if [ $HAS_SUBMODULES -eq 1 ]; then
    _NIX_PREFETCH_ARGS+=(--fetch-submodules)
  fi

  _LATEST_GIT=$(nix-prefetch-git "''${_NIX_PREFETCH_ARGS[@]}" --rev "$_LATEST_REV" "$_GIT_URL")

  _LATEST_HASH=$(echo $_LATEST_GIT | jq -r .hash)
  _LATEST_DATE=$(date -u --date=$(echo $_LATEST_GIT | jq -r .date) '+%Y%m%d%H%M%S')
  _LATEST_VERSION="unstable-''${_LATEST_DATE}-''${_LATEST_REV:0:7}"
  _LATEST_PATH=$(echo $_LATEST_GIT | jq -r .path)

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

  if [ $WITH_LAST_DATE -eq 1 ]; then
    JQ_ARGS+=(--arg date "$_LATEST_DATE")
    JQ_OPS+=('| .lastModifiedDate = $date')
  fi

  if [ $WITH_LAST_STAMP -eq 1 ]; then
    _LATEST_STAMP=$(date -u --date=$(echo $_LATEST_GIT | jq -r .date) '+%s')
    JQ_ARGS+=(--arg stamp "$_LATEST_STAMP")
    JQ_OPS+=('| .lastModified = $stamp')
  fi

  if [ $HAS_CARGO == 'rec' ]; then
    JQ_ARGS+=(--arg cargo '${nyxUtils.unreachableHash}')
    JQ_OPS+=('| .cargoHash = $cargo')
  fi

  jq "''${JQ_ARGS[@]}" \
    "''${JQ_OPS[*]}" \
    "$_VERSION_JSON" | sponge "$_VERSION_JSON"

  if [ $HAS_CARGO == 'rec' ]; then
    _LATEST_CARGO_HASH=$((nix build .#''${_NYX_KEY} 2>&1 || true) | awk '/got/{print $2}')
    jq --arg cargo "$_LATEST_CARGO_HASH" \
      '.cargoHash = $cargo' \
      "$_VERSION_JSON" | sponge "$_VERSION_JSON"
  elif [ $HAS_CARGO == 'lock' ]; then
    cp "$_LATEST_PATH/Cargo.lock" "$_PKG_DIR/"
    git add "$_PKG_DIR/Cargo.lock"
  fi

  git add $_VERSION_JSON

  [ -n "''${WITH_EXTRA:-}" ] && source "$WITH_EXTRA"

  git commit -m "''${_NYX_KEY}: ''${_LOCAL_VER:9} -> ''${_LATEST_VERSION:9}"
'').overrideAttrs (_prevAttrs: {
  meta = _prevAttrs.meta // { description = "Generic update-script for bleeding-edge GIT Nix derivations."; };
})

