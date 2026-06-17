{
  writeShellScript,
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
      mainFlavor = "-lto";
      flavors = [
        "-gcc"
        "-lto"
        #-znver4 (we're not creating the config-nix for this one)
      ];
    };
    hardened = {
      versionsFile = "versions-hardened.json";
      suffix = "-hardened";
      mainFlavor = "-hardened";
    };
    lts = {
      versionsFile = "versions-lts.json";
      suffix = "-lts";
      mainFlavor = "-lts";
    };
    rc = {
      versionsFile = "versions-rc.json";
      suffix = "-rc";
      mainFlavor = "-rc";
    };
    server = {
      versionsFile = "versions-server.json";
      suffix = "-server";
      mainFlavor = "-server";
    };
  };

  major = variants.${withUpdateScript} or (throw "Unsupported update-script for linux-cachyos");

in

with major;

writeShellScript "update-cachyos" ''
  set -euo pipefail
  PATH=${path}

  echo "USING LOCAL UPDATE SCRIPT"

  srcJson="pkgs/linux-cachyos/${versionsFile}"

  localVer=$(jq -r .linux.version < "$srcJson")
  localTagrel=$(jq -r '.linux.tagrel // -1' < "$srcJson")

  fetch_pkgbuild() {
    curl -fsSL \
      "https://raw.githubusercontent.com/CachyOS/linux-cachyos/master/linux-cachyos${suffix}/PKGBUILD"
  }

  parse_version() {
    awk -F= '
      /^[[:space:]]*_major[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        major=$2
      }
      /^[[:space:]]*_minor[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        minor=$2
      }
      /^[[:space:]]*_rcver[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        rcver=$2
      }
      /^[[:space:]]*_ltsver[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        ltsver=$2
      }
      END {
        if (rcver != "") {
          print major "-" rcver
        } else if (ltsver != "") {
          print major "." ltsver
        } else {
          print major "." minor
        }
      }
    '
  }

  parse_tagrel() {
    awk -F= '
      /^[[:space:]]*_tagrel[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        print $2
        exit
      }
    '
  }

  parse_srctag() {
    awk -F= '
      /^[[:space:]]*_major[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        major=$2
      }
      /^[[:space:]]*_minor[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        minor=$2
      }
      /^[[:space:]]*_rcver[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        rcver=$2
      }
      /^[[:space:]]*_ltsver[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        ltsver=$2
      }
      /^[[:space:]]*_tagrel[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        tagrel=$2
      }
      END {
        if (rcver != "") {
          print "cachyos-" major "-" rcver "-" tagrel
        } else if (ltsver != "") {
          print "cachyos-" major "." ltsver "-" tagrel
        } else {
          print "cachyos-" major "." minor "-" tagrel
        }
      }
    '
  }

  pkgbuild=$(fetch_pkgbuild)

  latestVer=$(printf "%s\n" "$pkgbuild" | parse_version)
  latestTagrel=$(printf "%s\n" "$pkgbuild" | parse_tagrel)
  srcTag=$(printf "%s\n" "$pkgbuild" | parse_srctag)
  srcUrl="https://github.com/CachyOS/linux/releases/download/''${srcTag}/''${srcTag}.tar.gz"

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

  printf "%s\n" "$pkgbuild" | grep '^:' | jq -Rn '
    [inputs
    | capture(":\\s*\"\\$\\{(?<key>[a-zA-Z0-9_]+):=(?<value>.*)\\}\"$") // empty]
    | reduce .[] as $i ({}; .[$i.key] = $i.value)
  ' > pkgs/linux-cachyos/config-vars/cachyos${mainFlavor}.json

  ${lib.strings.concatMapStrings (flavor: ''
    out=$(nix build \
      ".#legacyPackages.x86_64-linux.linuxPackages_cachyos${flavor}.kernel.kconfigToNix" \
      --no-link --print-out-paths 2>/dev/null) || true

    if [ -n "$out" ] && [ -f "$out" ]; then
      cat "$out" > pkgs/linux-cachyos/config-nix/cachyos${flavor}.x86_64-linux.nix
    fi
  '') (major.flavors or [ mainFlavor ])}

  git add pkgs/linux-cachyos
  git commit -m \
    "linux_cachyos${suffix}: $localVer-$localTagrel -> $latestVer-$latestTagrel"
''
