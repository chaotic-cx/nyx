{
  writeShellScript,
  lib,
  coreutils,
  findutils,
  gnugrep,
  curl,
  jq,
  git,
  nix,
  moreutils,
}:
let
  path = lib.makeBinPath [
    coreutils
    curl
    findutils
    gnugrep
    jq
    moreutils
    git
    nix
  ];
in
writeShellScript "update-luxtorpeda" ''
  set -euo pipefail

  PATH=${path}

  srcJson=pkgs/luxtorpeda/manifest.json

  localVersion=$(jq -r .version "$srcJson")
  latestRelease=$(curl -fsSL 'https://codeberg.org/api/v1/repos/luxtorpeda/luxtorpeda/releases?pre-release=false&limit=10' | jq -er '[.[] | select(.prerelease == false and .draft == false)][0] // error("no stable release")')
  latestTag=$(jq -er .tag_name <<< "$latestRelease")

  [ "v$localVersion" == "$latestTag" ] && exit 0

  latestVersion=''${latestTag#v}
  latestUrl=$(jq -er --arg tag "$latestTag" '.assets[] | select(.name == ("luxtorpeda-" + $tag + ".tar.xz")) | .browser_download_url' <<< "$latestRelease")

  latestSha256=$(nix-prefetch-url --unpack --type sha256 "$latestUrl")
  latestHash=$(nix-hash --to-sri --type sha256 $latestSha256)

  jq --arg version "$latestVersion" \
    --arg hash "$latestHash" \
    --arg url "$latestUrl" \
    '.version = $version | .hash = $hash | .url = $url' \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "luxtorpeda: $localVersion -> $latestVersion"
''
