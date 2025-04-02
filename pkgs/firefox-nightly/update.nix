{
  writeShellScript,
  lib,
  coreutils,
  curl,
  git,
  jq,
  moreutils,
  nix,
}:
let
  path = lib.makeBinPath [
    coreutils
    curl
    git
    jq
    moreutils # sponge
    nix # nix-prefetch-url, nix-hash
  ];
in
writeShellScript "firefox-nightly-update" ''
  set -euo pipefail

  PATH=${path}
  VERSION_JSON="''${VERSION_JSON:-pkgs/firefox-nightly/version.json}"

  _LATEST_VER=$(curl -s 'https://product-details.mozilla.org/1.0/firefox_versions.json' | jq -r .FIREFOX_NIGHTLY)
  _LOCAL_VER=$(jq -r .version "$VERSION_JSON")
  _LOCAL_REV=$(jq -r .rev "$VERSION_JSON")
  _LATEST_REV=$(curl -s "https://archive.mozilla.org/pub/firefox/nightly/latest-mozilla-central/firefox-''${_LATEST_VER}.en-US.linux-x86_64.json" | jq -r .moz_source_stamp)
  [ "$_LOCAL_REV" == "$_LATEST_REV" ] && exit 0

  _LATEST_URL="https://hg.mozilla.org/mozilla-central/archive/''${_LATEST_REV}.zip";
  _LATEST_SHA256=$(nix-prefetch-url --type sha256 "$_LATEST_URL")
  _LATEST_HASH=$(nix-hash --to-sri --type sha256 $_LATEST_SHA256)

  JQ_ARGS=(
    --arg version "$_LATEST_VER"
    --arg rev "$_LATEST_REV"
    --arg hash "$_LATEST_HASH"
  )

  JQ_OPS=(
    '.rev = $rev'
    '| .version = $version'
    '| .hash = $hash'
  )

  jq "''${JQ_ARGS[@]}" \
    "''${JQ_OPS[*]}" \
    "$VERSION_JSON" | sponge "$VERSION_JSON"

  git add $VERSION_JSON
  git commit -m "firefox_nightly: $_LOCAL_VER-''${_LOCAL_REV::9} -> $_LATEST_VER-''${_LATEST_REV::9}"
''
