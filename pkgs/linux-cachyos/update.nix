{ writeShellScript
, lib
, coreutils
, findutils
, gnugrep
, gnused
, curl
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
    gnused
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
  localRcVer=$(jq -r .linuxRc.version < $srcJson)

  latestVer=$(curl 'https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos/.SRCINFO' | grep -Po '(?<=pkgver = )(.+)$')
  latestRcVer=$(curl 'https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos-rc/.SRCINFO' | grep -Po '(?<=pkgver = )(.+)$' | sed 's/\.rc/-rc/')

  if [[ "$localVer" == "$latestVer" && "$localVer" == "$latestRcVer" ]]; then
    exit 0
  fi

  latestSha256=$(nix-prefetch-url --type sha256 "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-''${latestVer%.0}.tar.xz")
  latestHash=$(nix-hash --to-sri --type sha256 $latestSha256)

  latestRcSha256=$(nix-prefetch-url --type sha256 "https://git.kernel.org/torvalds/t/linux-''${latestRcVer%.0}.tar.gz")
  latestRcHash=$(nix-hash --to-sri --type sha256 $latestRcSha256)

  configRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/linux-cachyos.git')
  configRev=$(echo "$configRepo" | jq -r .rev)
  configHash=$(echo "$configRepo" | jq -r .hash)
  configPath=$(echo "$configRepo" | jq -r .path)

  patchesRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/kernel-patches.git')
  patchesRev=$(echo "$patchesRepo" | jq -r .rev)
  patchesHash=$(echo "$patchesRepo" | jq -r .hash)

  zfsRev=$(grep -Po '(?<=zfs.git#commit=)([^"]+)' $configPath/linux-cachyos/PKGBUILD)
  zfsRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/zfs.git' --rev $zfsRev)
  zfsHash=$(echo "$zfsRepo" | jq -r .hash)

  jq \
    --arg latestVer "$latestVer" --arg latestHash "$latestHash" \
    --arg latestRcVer "$latestRcVer" --arg latestRcHash "$latestRcHash" \
    --arg configRev "$configRev" --arg configHash "$configHash" \
    --arg patchesRev "$patchesRev" --arg patchesHash "$patchesHash" \
    --arg zfsRev "$zfsRev" --arg zfsHash "$zfsHash" \
    ".linux.version = \$latestVer | .linux.hash = \$latestHash |\
    .linuxRc.version = \$latestRcVer | .linuxRc.hash = \$latestRcHash |\
      .config.rev = \$configRev | .config.hash = \$configHash |\
      .patches.rev = \$patchesRev | .patches.hash = \$patchesHash |\
      .zfs.rev = \$zfsRev | .zfs.hash = \$zfsHash" \
    "$srcJson" | sponge "$srcJson"

  cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos.kernel.kconfigToNix' --no-link --print-out-paths)" \
    > pkgs/linux-cachyos/config-nix/cachyos.x86_64-linux.nix

  cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-rc.kernel.kconfigToNix' --no-link --print-out-paths)" \
    > pkgs/linux-cachyos/config-nix/cachyos-rc.x86_64-linux.nix

  cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-lto.kernel.kconfigToNix' --no-link --print-out-paths)" \
    > pkgs/linux-cachyos/config-nix/cachyos-lto.x86_64-linux.nix

  cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-server.kernel.kconfigToNix' --no-link --print-out-paths)" \
    > pkgs/linux-cachyos/config-nix/cachyos-server.x86_64-linux.nix

  cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-hardened.kernel.kconfigToNix' --no-link --print-out-paths)" \
    > pkgs/linux-cachyos/config-nix/cachyos-hardened.x86_64-linux.nix

  git add $srcJson pkgs/linux-cachyos/config-*.nix
  if [ "$localVer" != "$latestVer" ]; then
    git commit -m "linux_cachyos: $localVer -> $latestVer"
  else
    git commit -m "linux_cachyos-rc: $localRcVer -> $latestRcVer"
  fi
''

