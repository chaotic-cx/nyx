{
  writeShellScript,
  lib,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  curl,
  jq,
  git,
  nix,
  nix-prefetch-git,
  moreutils,
  withUpdateScript,
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

  releaseSrcUrl = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-\${latestVer%.0}.tar.xz";

  major =
    if withUpdateScript == "stable" then
      {
        versionsFile = "versions.json";
        suffix = "";
        flavors = [
          "-gcc"
          "-lto"
          "-server"
        ];
        srcUrl = releaseSrcUrl;
      }
    else if withUpdateScript == "rc" then
      {
        versionsFile = "versions-rc.json";
        suffix = "-rc";
        flavors = [ "-rc" ];
        srcUrl = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-\${latestVer%.0}.tar.gz";
      }
    else if withUpdateScript == "hardened" then
      {
        versionsFile = "versions-hardened.json";
        suffix = "-hardened";
        flavors = [ "-hardened" ];
        srcUrl = releaseSrcUrl;
      }
    else if withUpdateScript == "lts" then
      {
        versionsFile = "versions-lts.json";
        suffix = "-lts";
        flavors = [ "-lts" ];
        srcUrl = releaseSrcUrl;
      }
    else
      throw "Unsupported update-script for linux-cachyos";
in
with major;
writeShellScript "update-cachyos" ''
  set -euo pipefail
  PATH=${path}

  srcJson=pkgs/linux-cachyos/${versionsFile}
  localVer=$(jq -r .linux.version < $srcJson)

  latestVer=$(curl 'https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos${suffix}/.SRCINFO' | grep -Po '(?<=pkgver = )(.+)$' | sed 's/\.rc/-rc/')

  if [ "$localVer" == "$latestVer" ]; then
    exit 0
  fi

  latestSha256=$(nix-prefetch-url --type sha256 "${srcUrl}")
  latestHash=$(nix-hash --to-sri --type sha256 $latestSha256)

  configRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/linux-cachyos.git')
  configRev=$(echo "$configRepo" | jq -r .rev)
  configHash=$(echo "$configRepo" | jq -r .hash)
  configPath=$(echo "$configRepo" | jq -r .path)

  patchesRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/kernel-patches.git')
  patchesRev=$(echo "$patchesRepo" | jq -r .rev)
  patchesHash=$(echo "$patchesRepo" | jq -r .hash)

  zfsRev=$(grep -Po '(?<=zfs.git#commit=)([^"]+)' $configPath/linux-cachyos${suffix}/PKGBUILD)
  zfsRepo=$(nix-prefetch-git --quiet 'https://github.com/CachyOS/zfs.git' --rev $zfsRev)
  zfsHash=$(echo "$zfsRepo" | jq -r .hash)

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

  ${lib.strings.concatMapStrings (flavor: ''
    cat "$(nix build '.#legacyPackages.x86_64-linux.linuxPackages_cachyos${flavor}.kernel.kconfigToNix' --no-link --print-out-paths)" \
    > pkgs/linux-cachyos/config-nix/cachyos${flavor}.x86_64-linux.nix || true
  '') flavors}

  git add pkgs/linux-cachyos
  git commit -m "linux_cachyos${suffix}: $localVer -> $latestVer"
''
