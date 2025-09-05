{
  writeShellScript,
  lib,
  coreutils,
  findutils,
  gnugrep,
  curl,
  jq,
  git,
  nix,
  nix-prefetch-git,
  moreutils,
  yq,
  packageToUpdate,
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
  id="${packageToUpdate.id}"
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

  localVersion=$(jq -r ".\"$id\".version" "$srcJson")
  localRev=$(jq -r ".\"$id\".rev" "$srcJson")
  badTag=$(jq -r ".\"$id\".badTag" "$srcJson")
  localTag=''${localRev//#\{version\}/$localVersion}

  latestTag=$(curl "https://github.com/$repo/tags.atom" | xq -r '.feed.entry[0].link."@href"' | grep -Po '(?<=/)[^/]+$')

  if [ "$localTag" == "$latestTag" ]; then
    exit 0
  elif [ "$latestTag" == "$badTag" ]; then
    exit 0
  elif [[ "$latestTag" =~ snapshot-(.+) ]]; then
    exit 0
  elif [[ "$latestTag" =~ oxr-exp-(.+) ]]; then
    exit 0
  elif [[ "$latestTag" =~ ^vulkan-sdk-(.+) ]]; then
    ARGS+=('--arg' 'version' "''${BASH_REMATCH[1]}")
    REPLACES+=(".\"$id\".rev = \"vulkan-sdk-#{version}\"")
  elif [[ "$latestTag" =~ ^v(.+) ]]; then
    ARGS+=('--arg' 'version' "''${BASH_REMATCH[1]}")
    REPLACES+=(".\"$id\".rev = \"v#{version}\"")
  elif [[ "$latestTag" =~ ^sdk-(.+) ]]; then
    ARGS+=('--arg' 'version' "''${BASH_REMATCH[1]}")
    REPLACES+=(".\"$id\".rev = \"sdk-#{version}\"")
  elif [[ "$latestTag" =~ [^-]+ ]]; then
    ARGS+=('--arg' 'version' "$latestTag")
    REPLACES+=(".\"$id\".rev = \"#{version}\"")
  else
    echo "Unrecognized version in tag $latestTag" > /dev/stderr
    exit 1
  fi
  REPLACES+=(".\"$id\".version = \$version")

  latestHash=$(nix-prefetch-git --quiet \
      --rev "$latestTag" \
      "https://github.com/$repo.git" \
      ${if packageToUpdate.fetchSubmodules then "--fetch-submodules" else ""} |\
    jq -r '.hash' \
  )

  ARGS+=('--arg' 'hash' "$latestHash")
  REPLACES+=(".\"$id\".hash = \$hash")

  jq "''${ARGS[@]}" \
    "$(join_by ' | ' "''${REPLACES[@]}")" \
    "$srcJson" | sponge "$srcJson"
  git add $srcJson

  git commit -m "vulkanPackages_latest.$key: $localTag -> $latestTag"
''
