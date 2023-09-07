{ writeShellScript
, curl
, jq
  # parameters:
, src
, ref
}:

writeShellScript "github-${src.owner}-${src.repo}-${ref}-rev-fetcher" ''
  set -euo pipefail

  ${curl}/bin/curl -s 'https://api.github.com/repos/${src.owner}/${src.repo}/commits/${ref}' | ${jq}/bin/jq -r .sha
''

