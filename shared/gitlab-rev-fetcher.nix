{
  lib,
  writeShellScript,
  curl,
  jq,
}:
ref:
{
  owner,
  repo,
  group ? null,
  domain ? "gitlab.com",
  ...
}:

let
  slug = lib.concatStringsSep "/" (
    (lib.optional (group != null) group)
    ++ [
      owner
      repo
    ]
  );
  escapedSlug = lib.replaceStrings [ "." "/" ] [ "%2E" "%2F" ] slug;
in
writeShellScript "gitlab-${repo}-${ref}-rev-fetcher" ''
  set -euo pipefail

  ${curl}/bin/curl -s 'https://${domain}/api/v4/projects/${escapedSlug}/repository/commits?ref_name=${ref}' | ${jq}/bin/jq -r .[0].id
''
