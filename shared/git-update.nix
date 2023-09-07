{ pname
, nyxKey
, versionPath
, hasCargo ? false
, hasSubmodules ? false
, gitUrl
, fetchLatestRev
  # from nyx:
, nyx-generic-git-update
  # from nixpkgs:
, writeShellScript
}:

writeShellScript "update-${pname}-git" ''
  set -euo pipefail

  _LATEST_REV=$(${fetchLatestRev})

  HAS_CARGO=${if hasCargo then "1" else "0"} \
  HAS_SUBMODULES=${if hasSubmodules then "1" else "0"} \
    exec "${nyx-generic-git-update}/bin/nyx-generic-update" \
    "${pname}" "${nyxKey}" "${versionPath}" \
    "${gitUrl}" "$_LATEST_REV"
''

