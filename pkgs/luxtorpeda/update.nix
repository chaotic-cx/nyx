{ writeShellScript
, lib
, coreutils
, findutils
, gnugrep
, curl
, jq
, git
, nix
, moreutils
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

  srcJson=pkgs/luxtorpeda/version.json

  localVersion=$(jq -r .version "$srcJson")
  latestRelease=$(curl -s https://api.github.com/repos/luxtorpeda-dev/luxtorpeda/releases/latest)
  latestTag=$(jq .tag_name -r <<< $latestRelease)
  latestUrl=$(jq .assets[0].browser_download_url -r <<< $latestRelease)

  [ "v$localVersion" == "$latestTag" ] && exit 0

  latestVersion=''${latestTag#v}

  latestSha256=$(nix-prefetch-url --type sha256 "$latestUrl")
  latestHash=$(nix-hash --to-sri --type sha256 $latestSha256)

  jq --arg version "$latestVersion" \
    --arg hash "$latestHash" \
    --arg url "$latestUrl" \
    '.version = $version | .hash = $hash | .url = $url' \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "luxtorpeda: $localVersion -> $latestVersion"
''

