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
  inherit (lib.strings) escapeShellArgs;

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
    export cleanVersion="''${BASH_REMATCH[1]}"
    REPLACES+=(".\"$id\".rev = \"vulkan-sdk-#{version}\"")
  elif [[ "$latestTag" =~ ^v(.+) ]]; then
    export cleanVersion="''${BASH_REMATCH[1]}"
    REPLACES+=(".\"$id\".rev = \"v#{version}\"")
  elif [[ "$latestTag" =~ ^sdk-(.+) ]]; then
    export cleanVersion="''${BASH_REMATCH[1]}"
    REPLACES+=(".\"$id\".rev = \"sdk-#{version}\"")
  elif [[ "$latestTag" =~ [^-]+ ]]; then
    export cleanVersion="$latestTag"
    REPLACES+=(".\"$id\".rev = \"#{version}\"")
  else
    echo "Unrecognized version in tag $latestTag" > /dev/stderr
    exit 1
  fi
  ARGS+=('--arg' 'version' "$cleanVersion")
  REPLACES+=(".\"$id\".version = \$version")

  prefetch=$(
    nix-prefetch-git --quiet \
      --rev "$latestTag" \
      "https://github.com/$repo.git" \
      ${if packageToUpdate.fetchSubmodules then "--fetch-submodules" else ""} \
  )
  latestHash=$(echo "$prefetch" |\
    jq -r '.hash' \
  )

  ARGS+=('--arg' 'hash' "$latestHash")
  REPLACES+=(".\"$id\".hash = \$hash")

  jq "''${ARGS[@]}" \
    "$(join_by ' | ' "''${REPLACES[@]}")" \
    "$srcJson" | sponge "$srcJson"
  git add $srcJson

  knownGoods=(${
    if packageToUpdate.knownGoods != null then escapeShellArgs packageToUpdate.knownGoods else ""
  })
  if [[ ''${#knownGoods[@]} > 0 ]]; then
    path=$(echo "$prefetch" | jq -r .path)
    knownGood="$path/scripts/known_good.json"
    for sub in "''${knownGoods[@]}"; do
      subUrl=$(jq -r ".repos[] | select(.name == \""$sub"\") | .url" "$knownGood")
      subRev=$(jq -r ".repos[] | select(.name == \""$sub"\") | .commit" "$knownGood")
      subHash=$(
        nix-prefetch-git --quiet \
          --rev "$subRev" \
          "$subUrl" | \
          jq -r '.hash' \
      )
      jq --arg 'version' "$cleanVersion-unstable" --arg 'rev' "$subRev" --arg 'hash' "$subHash" \
        ".\"$sub\".version = \$version | .\"$sub\".rev = \$rev | .\"$sub\".hash = \$hash" \
        "$srcJson" | sponge "$srcJson"
      git add $srcJson
    done
  fi

  git commit -m "vulkanPackages_latest.$key: $localTag -> $cleanVersion"
''
