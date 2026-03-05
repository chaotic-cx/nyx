{
  writeShellScript,
  curl,
  jq,
}:
ref:
{
  owner,
  repo,
  domain,
  ...
}:
writeShellScript "gitea-${repo}-${ref}-rev-fetcher" ''
  set -euo pipefail

  ${curl}/bin/curl \
    -sS \
    -L \
    --fail \
    --retry 3 \
    --retry-delay 2 \
    --retry-connrefused \
    "https://${domain}/api/v1/repos/${owner}/${repo}/commits?sha=${ref}&limit=1&stat=false&verification=false&files=false" \
  | ${jq}/bin/jq -er '.[0].sha'
''
