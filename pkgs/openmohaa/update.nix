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
    nix-prefetch-git
    nix
  ];
in
writeShellScript "update-openmohaa" ''
  set -euo pipefail

  PATH=${path}

  srcJson=pkgs/openmohaa/version.json

  localVersion=$(jq -r .version "$srcJson")
  latestTag=$(curl -s https://api.github.com/repos/openmoh/openmohaa/releases/latest | jq .tag_name -r)

  [ "v$localVersion" == "$latestTag" ] && exit 0

  latestVersion=''${latestTag#v}

  latestHash=$(nix-prefetch-git --quiet \
      --rev "$latestTag" \
      "https://github.com/openmoh/openmohaa.git" |\
    jq -r .hash \
  )

  jq --arg version "$latestVersion" \
    --arg hash "$latestHash" \
    '.version = $version | .hash = $hash' \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "openmohaa: $localVersion -> $latestVersion"
''

