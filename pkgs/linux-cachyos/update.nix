{ writeShellScript
, lib
, coreutils
, findutils
, gawk
, gnugrep
, gnused
, curl
, jq
, git
, nix
, nix-prefetch-git
, moreutils
, withUpdateScript
}:
let
  path = lib.makeBinPath [
    coreutils
    curl
    findutils
    gawk
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

  update_kernel () {
    local ver=$1
    local url=$2

    local hash_sha256=$(nix-prefetch-url --type sha256 $url)
    local hash_sri=$(nix-hash --to-sri --type sha256 $hash_sha256)
    echo $hash_sri
  }

  if [[ "${withUpdateScript}" == "rc" ]]; then
    localVer=$(jq -r .linuxRc.version < $srcJson)
    latestVer=$(curl 'https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos-rc/.SRCINFO' | grep -Po '(?<=pkgver = )(.+)$' | sed 's/\.rc/-rc/')
    if [[ "$localVer" == "$latestVer" ]]; then
      exit 0
    fi

    localSuffix=$(echo $localVer | awk -F'-' '{print $2}')
    latestSuffix=$(echo $latestVer | awk -F'-' '{print $2}')
    sed -i "s/-$localSuffix/-$latestSuffix/g" pkgs/linux-cachyos/0001-Add-extra-version-CachyOS-rc.patch

    url="https://git.kernel.org/torvalds/t/linux-''${latestVer%.0}.tar.gz"
    latestHash=$(update_kernel $latestVer $url)

    jq \
    --arg latestRcVer "$latestVer" --arg latestRcHash "$latestHash" \
    ".linuxRc.version = \$latestRcVer | .linuxRc.hash = \$latestRcHash " \
    "$srcJson" | sponge "$srcJson"

    cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-rc.kernel.kconfigToNix' --no-link --print-out-paths)" \
    > pkgs/linux-cachyos/config-nix/cachyos-rc.x86_64-linux.nix

    message="linux_cachyos-rc: $localVer -> $latestVer"
  elif [[ "${withUpdateScript}" == "stable" ]]; then
    localVer=$(jq -r .linux.version < $srcJson)
    latestVer=$(curl 'https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos/.SRCINFO' | grep -Po '(?<=pkgver = )(.+)$')
    if [[ "$localVer" == "$latestVer" ]]; then
      exit 0
    fi
    
    url="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-''${latestVer%.0}.tar.xz"
    latestHash=$(update_kernel $latestVer $url)

  jq \
    --arg latestVer "$latestVer" --arg latestHash "$latestHash" \
    ".linux.version = \$latestVer | .linux.hash = \$latestHash " \
    "$srcJson" | sponge "$srcJson"

    cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos.kernel.kconfigToNix' --no-link --print-out-paths)" \
      > pkgs/linux-cachyos/config-nix/cachyos.x86_64-linux.nix

    cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-lto.kernel.kconfigToNix' --no-link --print-out-paths)" \
      > pkgs/linux-cachyos/config-nix/cachyos-lto.x86_64-linux.nix

    cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-server.kernel.kconfigToNix' --no-link --print-out-paths)" \
      > pkgs/linux-cachyos/config-nix/cachyos-server.x86_64-linux.nix

    cat "$(nix build '.#packages.x86_64-linux.linuxPackages_cachyos-hardened.kernel.kconfigToNix' --no-link --print-out-paths)" \
      > pkgs/linux-cachyos/config-nix/cachyos-hardened.x86_64-linux.nix

    message="linux_cachyos: $localVer -> $latestVer"
  else
    echo "Error, wrong kernel selected, please either update linux_cachyos or linux_cachyos-rc"
    exit 1
  fi

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
    --arg configRev "$configRev" --arg configHash "$configHash" \
    --arg patchesRev "$patchesRev" --arg patchesHash "$patchesHash" \
    --arg zfsRev "$zfsRev" --arg zfsHash "$zfsHash" \
      ".config.rev = \$configRev | .config.hash = \$configHash |\
      .patches.rev = \$patchesRev | .patches.hash = \$patchesHash |\
      .zfs.rev = \$zfsRev | .zfs.hash = \$zfsHash" \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson pkgs/linux-cachyos/config-*.nix
  git commit -m "$message"
''
