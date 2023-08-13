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
, ...
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
  ];
in
writeShellScript "update-firedragon" ''
  set -euo pipefail
  PATH=${path}

  srcJson=pkgs/firedragon/src.json
  localVer=$(jq -r .packageVersion < $srcJson)

  latestVer=$(curl 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=firedragon' | grep -Po '(?<=pkgver=)(.+)$')

  if [ "$localVer" == "$latestVer" ]; then
    exit 0
  fi

  latestSha256=$(nix-prefetch-url --type sha256 "https://ftp.mozilla.org/pub/firefox/releases/''${latestVer}/source/firefox-''${latestVer}.source.tar.xz")
  latestHash=$(nix-hash --to-sri --type sha256 $latestSha256)

  sourceRepo=$(nix-prefetch-git --fetch-submodules --quiet 'https://gitlab.com/librewolf-community/browser/source.git')
  sourceRev=$(echo "$sourceRepo" | jq -r .rev)
  sourceHash=$(echo "$sourceRepo" | jq -r .hash)

  firedragonRepo=$(nix-prefetch-git --fetch-submodules --quiet 'https://gitlab.com/dr460nf1r3/settings.git')
  firedragonRev=$(echo "$firedragonRepo" | jq -r .rev)
  firedragonHash=$(echo "$firedragonRepo" | jq -r .hash)

  jq \
    --arg latestVer "$latestVer" --arg latestHash "$latestHash" \
    --arg sourceRev "$sourceRev" --arg sourceHash "$sourceHash" \
    --arg firedragonRev "$firedragonRev" --arg firedragonHash "$firedragonHash" \
    --arg firefoxRev "$latestSha256" --arg firefoxHash "$latestHash" \
    --arg packageVersion "$latestVer" \
    ".packageVersion = \$latestVer | \
    .firefox.version = \$latestVer | .firefox.hash = \$latestHash |\
     .source.rev = \$sourceRev | .source.hash = \$sourceHash |\
     .firedragon.rev = \$firedragonRev | .firedragon.hash = \$firedragonHash" \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "firedragon: $localVer -> $latestVer"
''

