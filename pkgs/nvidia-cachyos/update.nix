{
  writeShellScript,
  lib,
  coreutils,
  findutils,
  curl,
  gnugrep,
  jq,
  nix,
  moreutils,
  variant,
}:

let
  path = lib.makeBinPath [
    coreutils
    findutils
    curl
    gnugrep
    jq
    moreutils
    nix
  ];

  suffix = if variant == "stable" then "" else "-${variant}";
in
writeShellScript "update-nvidia-cachyos-${variant}" ''
  set -euo pipefail
  PATH=${path}

  srcJson="pkgs/nvidia-cachyos/version${suffix}.json"
  localVer=$(jq -r .version < "$srcJson")

  pkgbuild=$(curl -fsSL "https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos${suffix}/PKGBUILD")
  latestVer=$(echo "$pkgbuild" | grep -Po '(?<=_nv_ver=)([^[:space:]]+)')

  if [[ "$localVer" == "$latestVer" ]]; then
    echo "NVIDIA CachyOS is already up to date ($localVer)"
    exit 0
  fi

  echo "Updating NVIDIA CachyOS from $localVer to $latestVer"

  fetch_hash() {
    nix-prefetch-url --type sha256 "$1" | xargs nix-hash --to-sri --type sha256
  }

  fetch_hash_unpack() {
    nix-prefetch-url --unpack --type sha256 "$1" | xargs nix-hash --to-sri --type sha256
  }

  mainHash=$(fetch_hash "https://download.nvidia.com/XFree86/Linux-x86_64/$latestVer/NVIDIA-Linux-x86_64-$latestVer.run")
  aarch64Hash=$(fetch_hash "https://download.nvidia.com/XFree86/Linux-aarch64/$latestVer/NVIDIA-Linux-aarch64-$latestVer.run")
  openHash=$(fetch_hash_unpack "https://github.com/NVIDIA/open-gpu-kernel-modules/archive/$latestVer.tar.gz")
  settingsHash=$(fetch_hash_unpack "https://github.com/NVIDIA/nvidia-settings/archive/$latestVer.tar.gz")
  persistencedHash=$(fetch_hash "https://download.nvidia.com/XFree86/nvidia-persistenced/nvidia-persistenced-$latestVer.tar.bz2")

  jq \
    --arg ver "$latestVer" \
    --arg main "$mainHash" \
    --arg aarch64 "$aarch64Hash" \
    --arg open "$openHash" \
    --arg settings "$settingsHash" \
    --arg persistenced "$persistencedHash" \
    '.version = $ver | .hash = $main | .aarch64Hash = $aarch64 | .openHash = $open | .settingsHash = $settings | .persistencedHash = $persistenced' \
    "$srcJson" | sponge "$srcJson"
''
