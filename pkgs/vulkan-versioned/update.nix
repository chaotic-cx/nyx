{ writeShellScript
, lib
, coreutils
, findutils
, gnugrep
, curl
, jq
, git
, nix
, nix-prefetch-git
, moreutils
, yq
, packageToUpdate
}:
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
    yq
  ];
in
writeShellScript "update-vulkan-package" ''
  set -euo pipefail

  key="${packageToUpdate.key}"
  repo="${packageToUpdate.owner}/${packageToUpdate.repo}"

  PATH=${path}

  srcJson=pkgs/vulkan-versioned/latest.json

  function join_by { # https://stackoverflow.com/a/17841619
    local d=''${1-} f=''${2-}
    if shift 2; then
      printf %s "$f" "''${@/#/$d}"
    fi
  }

  ARGS=()
  REPLACES=()

  localVersion=$(jq -r .$key.version "$srcJson")
  localRev=$(jq -r .$key.rev "$srcJson")
  badTag=$(jq -r .$key.badTag "$srcJson")
  localTag=''${localRev//#\{version\}/$localVersion}

  latestTag=$(curl "https://github.com/$repo/tags.atom" | xq -r '.feed.entry[0].link."@href"' | grep -Po '(?<=/)[^/]+$')

  if [ "$localTag" == "$latestTag" ]; then
    exit 0
  elif [ "$latestTag" == "$badTag" ]; then
    exit 0
  elif [ "$latestTag" =~ snapshot-(.+) ]; then
    exit 0
  elif [[ "$latestTag" =~ vulkan-sdk-(.+) ]]; then
    ARGS+=('--arg' "''${key}Version" "''${BASH_REMATCH[1]}")
    REPLACES+=(".$key.rev = \"vulkan-sdk-#{version}\"")
  elif [[ "$latestTag" =~ v(.+) ]]; then
    ARGS+=('--arg' "''${key}Version" "''${BASH_REMATCH[1]}")
    REPLACES+=(".$key.rev = \"v#{version}\"")
  elif [[ "$latestTag" =~ sdk-(.+) ]]; then
    ARGS+=('--arg' "''${key}Version" "''${BASH_REMATCH[1]}")
    REPLACES+=(".$key.rev = \"sdk-#{version}\"")
  elif [[ "$latestTag" =~ [^-]+ ]]; then
    ARGS+=('--arg' "''${key}Version" "$latestTag")
    REPLACES+=(".$key.rev = \"#{version}\"")
  else
    echo "Unrecognized version in tag $latestTag" > /dev/stderr
    exit 1
  fi
  REPLACES+=(".$key.version = \$''${key}Version")

  latestHash=$(nix-prefetch-git --quiet \
      --rev "$latestTag" \
      "https://github.com/$repo.git" \
      ${if packageToUpdate.fetchSubmodules then "--fetch-submodules" else ""} |\
    jq -r .hash \
  )

  ARGS+=('--arg' "''${key}Hash" "$latestHash")
  REPLACES+=(".$key.hash = \$''${key}Hash")

  jq "''${ARGS[@]}" \
    "$(join_by ' | ' "''${REPLACES[@]}")" \
    "$srcJson" | sponge "$srcJson"

  git add $srcJson
  git commit -m "vulkanPackages_latest.$key: $localTag -> $latestTag"
''

