{ lib
, writeShellScript
, curl
, jq
  # parameters:
, src
, ref
}:

let
  inherit (src) group owner repo;
  slug = lib.concatStringsSep "/" ((lib.optional (group != null) group) ++ [ owner repo ]);
  escapedSlug = lib.replaceStrings [ "." "/" ] [ "%2E" "%2F" ] slug;
in
writeShellScript "gitlab-${repo}-${ref}-rev-fetcher" ''
  set -euo pipefail

  ${curl}/bin/curl -s 'https://${src.domain or "gitlab.com"}/api/v4/projects/${escapedSlug}/repository/commits?ref_name=${ref}' | ${jq}/bin/jq -r .[0].id
''

