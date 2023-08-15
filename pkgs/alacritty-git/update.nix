{ writeShellScript
, lib
, coreutils
, findutils
, curl
, gawk
, gnupg
, jq
, git
, nix
, nix-prefetch-git
, moreutils
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
writeShellScript "update-alacritty" ''
  set -euo pipefail

  PATH=${path}

  srcJson=pkgs/alacritty-git/version.json

  localRev=$(jq -r .rev "$srcJson")
  localVersion=$(jq -r .version "$srcJson")
  latestRev=$(curl -s https://api.github.com/repos/alacritty/alacritty/commits/master | jq -r .sha)

  [ "$localRev" == "$latestRev" ] && exit 0

  latestGit=$(nix-prefetch-git --quiet \
      --rev "$latestRev" \
      "https://github.com/alacritty/alacritty.git")

  latestDate=$(date -u --date=$(echo $latestGit | jq -r .date) '+%Y%m%d%H%M%S')
  latestHash=$(echo $latestGit | jq -r .hash)
  latestVersion="unstable-''${latestDate}-''${latestRev:0:7}"

  jq --arg version "$latestVersion" \
    --arg cargo 'sha256-2342234223422342234223422342234223422342069=' \
    --arg rev "$latestRev" --arg hash "$latestHash" \
    '.rev = $rev | .version = $version | .hash = $hash | .cargoHash = $cargo' \
    "$srcJson" | sponge "$srcJson"

  latestCargoHash=$((nix build .#alacritty_git.cargoDeps 2>&1 || true) | awk '/got/{print $2}')
  jq --arg cargo "$latestCargoHash" '.cargoHash = $cargo' "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "alacritty_git: ''${localVersion:9} -> ''${latestVersion:9}"
''

