{
  writeShellScriptBin,
  lib,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  gawk,
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
    gawk
    jq
    moreutils
    git
    nix-prefetch-git
    nix
  ];

  variants = {
    stable = {
      versionsFile = "versions.json";
      suffix = "";
      flavors = [
        "-gcc"
        "-lto"
        "-server"
      ];
    };
    rc = {
      versionsFile = "versions-rc.json";
      suffix = "-rc";
      flavors = [ "-rc" ];
    };
    hardened = {
      versionsFile = "versions-hardened.json";
      suffix = "-hardened";
      flavors = [ "-hardened" ];
    };
    lts = {
      versionsFile = "versions-lts.json";
      suffix = "-lts";
      flavors = [ "-lts" ];
    };
  };

  major = variants.${withUpdateScript} or (throw "Unsupported update-script for linux-cachyos");

in

with major;

writeShellScriptBin "update-cachyos" ''
  set -euo pipefail
  PATH=${path}

  echo "USING LOCAL UPDATE SCRIPT"

  srcJson="pkgs/linux-cachyos/${versionsFile}"

  localVer=$(jq -r .linux.version < "$srcJson")
  localTagrel=$(jq -r '.linux.tagrel // -1' < "$srcJson")

  fetch_srcinfo() {
    curl -fsSL \
      "https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos${suffix}/.SRCINFO"
  }

  parse_version() {
    awk -F= '
      /^[[:space:]]*pkgver[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        v=$2
      }
      END {
        gsub(/\.rc/, "-rc", v)
        print v
      }
    '
  }

  # parse_source_url() {
  #   awk '
  #     /^[[:space:]]*source = https:\/\/github.com\/CachyOS\/linux\/releases\/download/ {
  #       print $3; exit
  #     }
  #   '
  # }

  parse_source_url() {
    grep -m1 -E 'source = https://github.com/CachyOS/linux/releases/download/' \
    | sed -E 's/^[[:space:]]*source = //'
  }

  parse_tagrel_from_url() {
    filename="''${1##*/}"
    filename="''${filename%.tar.gz}"
    filename="''${filename%.tar.xz}"
    tagrel="''${filename##*-}"

    [[ "$tagrel" =~ ^[0-9]+$ ]] || {
      echo "Invalid tagrel: $tagrel"
      exit 1
    }

    echo "$tagrel"
  }

  srcinfo=$(fetch_srcinfo)

  latestVer=$(printf "%s\n" "$srcinfo" | parse_version)
  srcUrl=$(printf "%s\n" "$srcinfo" | parse_source_url)

  [[ -n "$srcUrl" ]] || {
    echo "Failed to parse source URL"
    exit 1
  }

  latestTagrel=$(parse_tagrel_from_url "$srcUrl")

  if [[ "$localVer" == "$latestVer" && "$localTagrel" == "$latestTagrel" ]]; then
    exit 0
  fi

  latestHash=$(nix-prefetch-url --type sha256 "$srcUrl" \
    | xargs nix-hash --to-sri --type sha256)

  prefetch_git() {
    nix-prefetch-git --quiet "$@" | jq -r '.rev + " " + .hash'
  }

  read rev hash < <(prefetch_git https://github.com/CachyOS/linux-cachyos.git)
  configRev=$rev
  configHash=$hash

  configPath=$(nix-prefetch-git --quiet https://github.com/CachyOS/linux-cachyos.git | jq -r .path)

  read rev hash < <(prefetch_git https://github.com/CachyOS/kernel-patches.git)
  patchesRev=$rev
  patchesHash=$hash

  zfsRev=$(grep -Po '(?<=zfs.git#commit=)([^"]+)' \
    "$configPath/linux-cachyos${suffix}/PKGBUILD")

  read _ zfsHash < <(prefetch_git https://github.com/CachyOS/zfs.git --rev "$zfsRev")

  jq \
    --arg latestVer "$latestVer" \
    --arg latestHash "$latestHash" \
    --argjson latestTagrel "$latestTagrel" \
    --arg configRev "$configRev" \
    --arg configHash "$configHash" \
    --arg patchesRev "$patchesRev" \
    --arg patchesHash "$patchesHash" \
    --arg zfsRev "$zfsRev" \
    --arg zfsHash "$zfsHash" \
    '
      .linux.version = $latestVer |
      .linux.hash = $latestHash |
      .linux.tagrel = $latestTagrel |
      .config.rev = $configRev |
      .config.hash = $configHash |
      .patches.rev = $patchesRev |
      .patches.hash = $patchesHash |
      .zfs.rev = $zfsRev |
      .zfs.hash = $zfsHash
    ' "$srcJson" | sponge "$srcJson"

  ${lib.strings.concatMapStrings (flavor: ''
    out=$(nix build \
      ".#legacyPackages.x86_64-linux.linuxPackages_cachyos${flavor}.kernel.kconfigToNix" \
      --no-link --print-out-paths 2>/dev/null) || true

    if [ -n "$out" ] && [ -f "$out" ]; then
      cat "$out" > pkgs/linux-cachyos/config-nix/cachyos${flavor}.x86_64-linux.nix
    fi
  '') flavors}

  git add pkgs/linux-cachyos
  git commit -m \
    "linux_cachyos${suffix}: $localVer-$localTagrel -> $latestVer-$latestTagrel"
''
