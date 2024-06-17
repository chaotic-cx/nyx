{ pname
, nyxKey
, versionPath
, hasCargo ? null
, hasSubmodules ? false
, withLastModifiedDate ? false
, withLastModified ? false
, withExtraCommands ? ""
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

  HAS_CARGO=${if hasCargo != null then hasCargo else "0"} \
  HAS_SUBMODULES=${if hasSubmodules then "1" else "0"} \
  WITH_LAST_DATE=${if withLastModifiedDate then "1" else "0"} \
  WITH_LAST_STAMP=${if withLastModified then "1" else "0"} \
  WITH_EXTRA=${withExtraCommands} \
    exec "${nyx-generic-git-update}/bin/nyx-generic-update" \
    "${pname}" "${nyxKey}" "${versionPath}" \
    "${gitUrl}" "$_LATEST_REV"
''

