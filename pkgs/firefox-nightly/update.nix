{
  writeShellScript,
  lib,
  coreutils,
  curl,
  git,
  jq,
  moreutils,
  nix,
  git-cinnabar,
}:

let
  path = lib.makeBinPath [
    coreutils
    curl
    git
    jq
    moreutils # sponge
    nix # nix store prefetch-file
    git-cinnabar
  ];
in
writeShellScript "firefox-nightly-update" ''
  set -euo pipefail

  export PATH=${path}

  manifest_json="''${MANIFEST_JSON:-pkgs/firefox-nightly/manifest.json}"
  mozilla_versions_url="https://product-details.mozilla.org/1.0/firefox_versions.json"
  github_repo_slug="mozilla-firefox/firefox"
  github_repo_url="https://github.com/$github_repo_slug"
  hg_repo="https://hg-edge.mozilla.org/mozilla-central"

  fetch_json() {
    curl -fsSL "$1"
  }

  json_field() {
    jq -er "$1"
  }

  git_short() {
    printf '%s' "$1" | cut -c1-9
  }

  latest_version=$(
    fetch_json "$mozilla_versions_url" |
      json_field '.FIREFOX_NIGHTLY'
  )

  local_version=$(jq -er '.version' "$manifest_json")
  local_rev=$(jq -er '.rev' "$manifest_json")
  local_build_id=$(jq -er '.buildId' "$manifest_json")

  nightly_metadata_url="https://archive.mozilla.org/pub/firefox/nightly/latest-mozilla-central/firefox-$latest_version.en-US.linux-x86_64.json"
  nightly_metadata_json=$(fetch_json "$nightly_metadata_url")

  latest_hg_rev=$(
    printf '%s\n' "$nightly_metadata_json" |
      json_field '.moz_source_stamp'
  )

  latest_build_id=$(
    printf '%s\n' "$nightly_metadata_json" |
      json_field '.buildid'
  )

  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  map_dir="$tmpdir/ff-map"

  git init --quiet "$map_dir"

  git -C "$map_dir" \
    -c cinnabar.graft="$github_repo_url" \
    cinnabar fetch \
    "hg::$hg_repo" \
    "$latest_hg_rev"

  latest_rev=$(
    git -C "$map_dir" cinnabar hg2git "$latest_hg_rev"
  )

  if [ "$local_version" = "$latest_version" ] \
    && [ "$local_rev" = "$latest_rev" ] \
    && [ "$local_build_id" = "$latest_build_id" ]; then
    echo "firefox-nightly is already up to date: $local_version-$local_build_id-$(git_short "$local_rev")"
    exit 0
  fi

  latest_url="https://codeload.github.com/$github_repo_slug/tar.gz/$latest_rev"

  latest_hash=$(
    nix --extra-experimental-features nix-command \
      store prefetch-file \
      --json \
      --hash-type sha256 \
      --name "firefox.tar.gz" \
      "$latest_url" |
      jq -er '.hash'
  )

  jq \
    --arg version "$latest_version" \
    --arg rev "$latest_rev" \
    --arg build_id "$latest_build_id" \
    --arg hash "$latest_hash" \
    '
      .rev = $rev
      | .buildId = $build_id
      | .version = $version
      | .hash = $hash
    ' \
    "$manifest_json" |
    sponge "$manifest_json"

  git add "$manifest_json"

  git commit -m "firefox_nightly: $local_version-$local_build_id-$(git_short "$local_rev") -> $latest_version-$latest_build_id-$(git_short "$latest_rev")"
''
