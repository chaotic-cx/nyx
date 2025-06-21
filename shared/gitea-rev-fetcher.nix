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

  ${curl}/bin/curl -s 'https://${domain}/api/v1/repos/${owner}/${repo}/commits?sha=${ref}&limit=1&stat=false&verification=false&files=false' | ${jq}/bin/jq -r .[0].sha
''
