{
  writeShellScript,
  curl,
  jq,
}:
ref:
{ owner, repo, ... }:

writeShellScript "github-${owner}-${repo}-${ref}-rev-fetcher" ''
  set -euo pipefail

  # Use GITHUB_TOKEN if available to avoid rate limiting
  if [ -n "''${GITHUB_TOKEN:-}" ]; then
    AUTH_HEADER=(-H "Authorization: Bearer $GITHUB_TOKEN")
  else
    AUTH_HEADER=()
  fi

  ${curl}/bin/curl \
    -sS \
    -L \
    --fail \
    --retry 3 \
    --retry-delay 2 \
    --retry-connrefused \
    "''${AUTH_HEADER[@]}" \
    "https://api.github.com/repos/${owner}/${repo}/commits/${ref}" \
  | ${jq}/bin/jq -er '.sha'
''
