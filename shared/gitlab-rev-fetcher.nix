{ writeShellScript
, curl
, jq
  # parameters:
, src
, ref
}:

writeShellScript "gitlab-${src.owner}-${src.repo}-${ref}-rev-fetcher" ''
  set -euo pipefail

  ${curl}/bin/curl -s 'https://${src.domain or "gitlab.com"}/api/v4/projects/${src.owner}%2F${src.repo}/repository/commits?ref_name=${ref}' | ${jq}/bin/jq -r .[0].id
''

