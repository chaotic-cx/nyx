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
writeShellScript "update-cachyos" ''
  set -euo pipefail
  PATH=${path}

  srcJson=pkgs/linux-cachyos/versions.json
  localVer=$(jq -r .linux.version < $srcJson)

  latestVer=$(curl 'https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos/.SRCINFO' | grep -Po '(?<=pkgver = )(.+)$')

  if [ "$localVer" == "$latestVer" ]; then
    exit 0
  fi

  latestSha256=$(nix-prefetch-url --type sha256 "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-''${latestVer}.tar.xz")
  latestHash=$(nix-hash --to-sri --type sha256 $latestSha256)

  configRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/linux-cachyos.git')
  configRev=$(echo "$configRepo" | jq -r .rev)
  configHash=$(echo "$configRepo" | jq -r .sha256 | xargs nix-hash --to-sri --type sha256)
  configPath=$(echo "$configRepo" | jq -r .path)

  patchesRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/kernel-patches.git')
  patchesRev=$(echo "$patchesRepo" | jq -r .rev)
  patchesHash=$(echo "$patchesRepo" | jq -r .sha256 | xargs nix-hash --to-sri --type sha256)

  zfsRev=$(grep -Po '(?<=zfs.git#commit=)([^"]+)' $configPath/linux-cachyos/PKGBUILD)
  zfsRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/zfs.git' --rev $zfsRev)
  zfsHash=$(echo "$zfsRepo" | jq -r .sha256 | xargs nix-hash --to-sri --type sha256)

  jq \
    --arg latestVer "$latestVer" --arg latestHash "$latestHash" \
    --arg configRev "$configRev" --arg configHash "$configHash" \
    --arg patchesRev "$patchesRev" --arg patchesHash "$patchesHash" \
    --arg zfsRev "$zfsRev" --arg zfsHash "$zfsHash" \
    ".linux.version = \$latestVer | .linux.hash = \$latestHash |\
     .config.rev = \$configRev | .config.hash = \$configHash |\
     .patches.rev = \$patchesRev | .patches.hash = \$patchesHash |\
     .zfs.rev = \$zfsRev | .zfs.hash = \$zfsHash" \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "linux_cachyos: $localVer -> $latestVer"
''

