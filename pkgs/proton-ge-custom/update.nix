{ writeShellScript
, lib
, coreutils
, findutils
, gnugrep
, curl
, gnupg
, jq
, git
, nix
, nix-prefetch-git
, moreutils
, yq
}@p:
let
  path = lib.makeBinPath [
    coreutils
    curl
    findutils
    gnugrep
    jq
    moreutils
    git
    nix-prefetch-git
    nix
    yq
  ];
in
writeShellScript "update-proton-ge-custom" ''
  set -euo pipefail
  PATH=${path}

  srcJson=pkgs/proton-ge-custom/versions.json
  localBase=$(jq -r .base < $srcJson)
  localRelease=$(jq -r .release < $srcJson)

  latestVer=$(curl 'https://github.com/GloriousEggroll/proton-ge-custom/tags.atom' | xq -r '.feed.entry[0].link."@href"' | grep -Po '(?<=/)[^/]+$')

  if [ "GE-Proton''${localBase}-''${localRelease}" == "$latestVer" ]; then
    exit 0
  fi

  latestBase=$(echo $latestVer | grep -Po '(?<=GE-Proton)[^-]+')
  latestRelease=$(echo $latestVer | grep -Po '(?<=-)[^-]+$')
  latestSha256=$(nix-prefetch-url --type sha256 "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/''${latestVer}/''${latestVer}.tar.gz")
  latestHash=$(nix-hash --to-sri --type sha256 $latestSha256)

  jq \
    --arg latestBase "$latestBase" --arg latestRelease "$latestRelease" --arg latestHash "$latestHash" \
    '.base = $latestBase | .release = $latestRelease | .hash = $latestHash' \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "proton-ge-custom: ''${localBase}.''${localRelease} -> ''${latestBase}.''${latestRelease}"
''

