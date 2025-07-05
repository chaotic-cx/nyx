# TODO: maybe deduplicate with other firedragon update script
{
  coreutils,
  curl,
  findutils,
  git,
  gnugrep,
  gnused,
  jq,
  lib,
  moreutils,
  nix,
  nix-prefetch-git,
  writeShellScript,
  ...
}:
let
  path = lib.makeBinPath [
    coreutils
    curl
    findutils
    git
    gnugrep
    gnused
    jq
    moreutils
    nix
    nix-prefetch-git
  ];
in
writeShellScript "update-firedragon-beta" ''
  set -euo pipefail
  PATH=${path}

  srcJson=pkgs/firedragon-beta/version.json
  localVer=$(jq -r .firedragonSource.version <$srcJson)

  latestVer=$(curl -s https://gitlab.com/api/v4/projects/69949446/releases/ | jq '.[0].tag_name' -r | sed 's/v//g')

  if [ "$localVer" == "$latestVer" ]; then
    exit 0
  fi

  # FireDragon doesn't expose this information, instead writing its own version to this file
  firefoxVersion=$(curl -s https://raw.githubusercontent.com/Floorp-Projects/Floorp/ESR128/browser/config/version.txt)

  latestSha256=$(nix-prefetch-url --type sha256 "https://gitlab.com/garuda-linux/firedragon/firedragon12/-/releases/v$latestVer/downloads/firedragon-source.tar.zst")
  latestHash=$(nix-hash --to-sri --type sha256 "$latestSha256")

  firedragonRepo=$(nix-prefetch-git --fetch-submodules --quiet 'https://gitlab.com/garuda-linux/firedragon/settings.git')
  firedragonRev=$(echo "$firedragonRepo" | jq -r .rev)
  firedragonHash=$(echo "$firedragonRepo" | jq -r .hash)

  jq \
    --arg firefoxVersion "$firefoxVersion" \
    --arg latestVer "$latestVer" --arg latestHash "$latestHash" \
    --arg firedragonRev "$firedragonRev" --arg firedragonHash "$firedragonHash" \
    ".firefoxVersion = \$firefoxVersion |\
    .firedragonSource.version = \$latestVer | .firedragonSource.hash = \$latestHash |\
    .firedragonSettings.rev = \$firedragonRev | .firedragonSettings.hash = \$firedragonHash" \
    "$srcJson" | sponge $srcJson

  git add $srcJson
  git commit -m "firedragon: $localVer -> $latestVer"
''
