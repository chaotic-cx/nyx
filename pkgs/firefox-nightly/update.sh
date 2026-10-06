#!/usr/bin/env bash
set -euo pipefail

readonly buildhub_url="https://buildhub.moz.tools/api/search"
readonly hg_repo="https://hg.mozilla.org/mozilla-central"
readonly github_repo="mozilla-firefox/firefox"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

fetch_json() {
  curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry 3 \
    --retry-all-errors \
    --retry-delay 1 \
    "$@"
}

json_field() {
  jq -er "$1"
}

validate_build_id() {
  local label="$1"
  local value="$2"

  [[ "${value}" =~ ^[0-9]{14}$ ]] ||
    die "${label} must be a 14-digit Mozilla build ID (got: ${value})"
}

validate_revision() {
  local label="$1"
  local value="$2"

  [[ "${value}" =~ ^[0-9a-fA-F]{40}$ ]] ||
    die "${label} must be a 40-character hexadecimal revision: ${value}"
}

validate_sha256() {
  local label="$1"
  local value="$2"

  [[ "${value}" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]] ||
    die "${label} must be a SHA-256 SRI hash: ${value}"
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) ||
  die "not inside a Git repository"

repo_root=$(realpath -e -- "${repo_root}") ||
  die "failed to resolve Git repository root"

readonly repo_root

if [[ -v MANIFEST_JSON ]] && [[ -n "${MANIFEST_JSON}" ]]; then
  manifest_json=$(realpath -e -- "${MANIFEST_JSON}") ||
    die "manifest not found: ${MANIFEST_JSON}"
else
  manifest_json=$(realpath -e -- "${repo_root}/pkgs/firefox-nightly/manifest.json") ||
    die "manifest not found: ${repo_root}/pkgs/firefox-nightly/manifest.json"
fi

readonly manifest_json

manifest_rel=$(realpath --relative-to="${repo_root}" -- "${manifest_json}") ||
  die "failed to resolve manifest path relative to repository"

readonly manifest_rel

if [[ "${manifest_rel}" == ".." || "${manifest_rel}" == ../* ]]; then
  die "manifest must be inside the Git repository: ${manifest_json}"
fi

git -C "${repo_root}" \
  ls-files --error-unmatch -- "${manifest_rel}" \
  >/dev/null 2>&1 ||
  die "manifest is not tracked by Git: ${manifest_rel}"

if ! git -C "${repo_root}" diff --quiet -- "${manifest_rel}" ||
  ! git -C "${repo_root}" diff --cached --quiet -- "${manifest_rel}"; then
  die "manifest has uncommitted changes: ${manifest_rel}"
fi

local_version=$(json_field '.version' <"${manifest_json}")
local_rev=$(json_field '.rev' <"${manifest_json}")
local_build_id=$(json_field '.buildId' <"${manifest_json}")
local_hash=$(json_field '.hash' <"${manifest_json}")

validate_revision "manifest rev" "${local_rev}"
validate_build_id "manifest buildId" "${local_build_id}"
validate_sha256 "manifest hash" "${local_hash}"

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
    "${buildhub_url}"
)

latest_version=$(
  printf '%s\n' "${buildhub_json}" |
    json_field '.hits.hits[0]._source.target.version'
)

latest_build_id=$(
  printf '%s\n' "${buildhub_json}" |
    json_field '.hits.hits[0]._source.build.id'
)

latest_hg_rev=$(
  printf '%s\n' "${buildhub_json}" |
    json_field '.hits.hits[0]._source.source.revision'
)

validate_build_id "Buildhub build ID" "${latest_build_id}"
validate_revision "Buildhub Mercurial revision" "${latest_hg_rev}"

pushlog_json=$(
  fetch_json "${hg_repo}/json-pushes?changeset=${latest_hg_rev}&version=2"
)

latest_rev=$(
  printf '%s\n' "${pushlog_json}" |
    jq -er \
      --arg rev "${latest_hg_rev}" \
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

validate_revision "Mozilla Git revision" "${latest_rev}"

if [[ "${local_build_id}" = "${latest_build_id}" ]]; then
  if [[ "${local_version}" != "${latest_version}" ]] ||
    [[ "${local_rev}" != "${latest_rev}" ]]; then
    die "Buildhub metadata conflicts with local manifest for build ID ${local_build_id}"
  fi

  echo "firefox-nightly is already up to date: ${local_version}-${local_build_id}-${local_rev:0:9}"
  exit 0
fi

if [[ "${latest_build_id}" < "${local_build_id}" ]]; then
  die "Buildhub returned older build ${latest_build_id}; refusing to downgrade from ${local_build_id}"
fi

latest_hash="${local_hash}"

tmp_manifest=""

cleanup() {
  if [[ -n "${tmp_manifest}" ]]; then
    rm -f -- "${tmp_manifest}"
  fi
}

trap cleanup EXIT

if [[ "${local_rev}" != "${latest_rev}" ]]; then
  latest_url="https://github.com/${github_repo}/archive/${latest_rev}.tar.gz"

  latest_hash=$(
    nix --extra-experimental-features nix-command \
      store prefetch-file \
      --json \
      --hash-type sha256 \
      --unpack \
      "${latest_url}" |
      json_field '.hash'
  )

  validate_sha256 "prefetched Firefox source hash" "${latest_hash}"
fi

tmp_manifest=$(mktemp -- "${manifest_json}.XXXXXX")

jq \
  --arg version "${latest_version}" \
  --arg rev "${latest_rev}" \
  --arg build_id "${latest_build_id}" \
  --arg hash "${latest_hash}" \
  '
    .rev = $rev
    | .buildId = $build_id
    | .version = $version
    | .hash = $hash
  ' \
  "${manifest_json}" \
  >"${tmp_manifest}"

jq -e . "${tmp_manifest}" >/dev/null
chmod --reference="${manifest_json}" -- "${tmp_manifest}"

mv -- "${tmp_manifest}" "${manifest_json}"
tmp_manifest=""

if git -C "${repo_root}" diff --quiet -- "${manifest_rel}"; then
  die "manifest did not change despite a newer Buildhub build"
fi

commit_message="firefox_nightly: ${local_version}-${local_build_id}-${local_rev:0:9} -> ${latest_version}-${latest_build_id}-${latest_rev:0:9}"

git -C "${repo_root}" commit \
  --only \
  --message "${commit_message}" \
  -- \
  "${manifest_rel}"
