{
  coreutils,
  curl,
  diffutils,
  git,
  jq,
  nix,
  prefetch-npm-deps,
  writeShellApplication,
}:

writeShellApplication {
  name = "firefox-nightly-update";

  runtimeInputs = [
    coreutils
    curl
    diffutils
    git
    jq
    nix
    prefetch-npm-deps
  ];

  text = ''
    readonly manifest_json="''${MANIFEST_JSON:-pkgs/firefox-nightly/manifest.json}"
    readonly buildhub_url="https://buildhub.moz.tools/api/search"
    readonly hg_repo="https://hg.mozilla.org/mozilla-central"
    readonly github_repo="mozilla-firefox/firefox"

    fetch_json() {
      curl -fsSL "$@"
    }

    json_field() {
      jq -er "$1"
    }

    git_short() {
      printf '%.9s' "$1"
    }

    if [ ! -f "$manifest_json" ]; then
      echo "error: manifest not found: $manifest_json" >&2
      exit 1
    fi

    local_version=$(json_field '.version' <"$manifest_json")
    local_rev=$(json_field '.rev' <"$manifest_json")
    local_build_id=$(json_field '.buildId' <"$manifest_json")
    local_hash=$(json_field '.hash' <"$manifest_json")
    local_newtab_npm_deps_hash=$(json_field '.newtabNpmDepsHash' <"$manifest_json")

    buildhub_json=$(
      fetch_json \
        -H 'Content-Type: application/json' \
        --data-binary '{
          "size": 1,
          "_source": [
            "build.id",
            "source.revision",
            "target.version"
          ],
          "query": {
            "bool": {
              "filter": [
                {
                  "term": {
                    "source.product": "firefox"
                  }
                },
                {
                  "term": {
                    "target.channel": "nightly"
                  }
                },
                {
                  "term": {
                    "target.platform": "linux-x86_64"
                  }
                },
                {
                  "term": {
                    "target.locale": "en-US"
                  }
                },
                {
                  "term": {
                    "source.tree": "mozilla-central"
                  }
                }
              ]
            }
          },
          "sort": [
            {
              "build.id": {
                "order": "desc"
              }
            }
          ]
        }' \
        "$buildhub_url"
    )

    latest_version=$(
      printf '%s\n' "$buildhub_json" |
        json_field '.hits.hits[0]._source.target.version'
    )

    latest_build_id=$(
      printf '%s\n' "$buildhub_json" |
        json_field '.hits.hits[0]._source.build.id'
    )

    latest_hg_rev=$(
      printf '%s\n' "$buildhub_json" |
        json_field '.hits.hits[0]._source.source.revision'
    )

    pushlog_json=$(
      fetch_json "$hg_repo/json-pushes?changeset=$latest_hg_rev&version=2"
    )

    latest_rev=$(
      printf '%s\n' "$pushlog_json" |
        jq -er \
          --arg rev "$latest_hg_rev" \
          '
            [
              .pushes[]
              | . as $push
              | ($push.changesets | index($rev)) as $index
              | select($index != null)
              | $push.git_changesets[$index]
              | select(. != null)
            ]
            | unique
            | if length == 1 then
                .[0]
              elif length == 0 then
                error("no Git revision found for " + $rev)
              else
                error("multiple Git revisions found for " + $rev)
              end
          '
    )

    if [ "$local_version" = "$latest_version" ] \
      && [ "$local_rev" = "$latest_rev" ] \
      && [ "$local_build_id" = "$latest_build_id" ]; then
      echo "firefox-nightly is already up to date: $local_version-$local_build_id-$(git_short "$local_rev")"
      exit 0
    fi

    latest_url="https://codeload.github.com/$github_repo/tar.gz/$latest_rev"

    if [ "$local_rev" = "$latest_rev" ]; then
      latest_hash="$local_hash"
    else
      latest_hash=$(
        nix --extra-experimental-features nix-command \
          store prefetch-file \
          --json \
          --hash-type sha256 \
          --name "firefox.tar.gz" \
          "$latest_url" |
          json_field '.hash'
      )
    fi

    tmpdir=$(mktemp -d)
    tmp_manifest=""

    cleanup() {
      rm -rf -- "$tmpdir"

      if [ -n "$tmp_manifest" ]; then
        rm -f -- "$tmp_manifest"
      fi
    }

    trap cleanup EXIT

    latest_lock="$tmpdir/package-lock.json"
    local_lock="$tmpdir/local-package-lock.json"

    fetch_json \
      "https://raw.githubusercontent.com/$github_repo/$latest_rev/browser/extensions/newtab/package-lock.json" \
      >"$latest_lock"

    latest_newtab_npm_deps_hash=""

    if fetch_json \
      "https://raw.githubusercontent.com/$github_repo/$local_rev/browser/extensions/newtab/package-lock.json" \
      >"$local_lock" \
      && cmp -s "$local_lock" "$latest_lock"; then
      latest_newtab_npm_deps_hash="$local_newtab_npm_deps_hash"
    fi

    if [ -z "$latest_newtab_npm_deps_hash" ]; then
      latest_newtab_npm_deps_hash=$(
        prefetch-npm-deps "$latest_lock" |
          tail -n 1
      )
    fi

    if [[ ! "$latest_newtab_npm_deps_hash" =~ ^sha256-[A-Za-z0-9+/]+=*$ ]]; then
      echo "error: invalid newtab npm dependency hash: $latest_newtab_npm_deps_hash" >&2
      exit 1
    fi

    tmp_manifest=$(mktemp -- "$manifest_json.XXXXXX")

    jq \
      --arg version "$latest_version" \
      --arg rev "$latest_rev" \
      --arg build_id "$latest_build_id" \
      --arg hash "$latest_hash" \
      --arg newtab_npm_deps_hash "$latest_newtab_npm_deps_hash" \
      '
        .rev = $rev
        | .buildId = $build_id
        | .version = $version
        | .hash = $hash
        | .newtabNpmDepsHash = $newtab_npm_deps_hash
      ' \
      "$manifest_json" \
      >"$tmp_manifest"

    jq -e . "$tmp_manifest" >/dev/null
    chmod --reference="$manifest_json" -- "$tmp_manifest"

    mv -- "$tmp_manifest" "$manifest_json"
    tmp_manifest=""

    commit_message="firefox_nightly: $local_version-$local_build_id-$(git_short "$local_rev") -> $latest_version-$latest_build_id-$(git_short "$latest_rev")"

    git commit \
      --only \
      --message "$commit_message" \
      -- \
      "$manifest_json"
  '';
}
