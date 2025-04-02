{
  writeShellScript,
  curl,
  jq,
}:
ref:
{ owner, repo, ... }:

writeShellScript "github-${owner}-${repo}-${ref}-rev-fetcher" ''
  set -euo pipefail

  ${curl}/bin/curl -s 'https://api.github.com/repos/${owner}/${repo}/commits/${ref}' | ${jq}/bin/jq -r .sha
''
