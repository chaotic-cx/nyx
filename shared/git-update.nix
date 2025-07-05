{
  pname,
  nyxKey,
  versionPath,
  hasCargo ? false,
  hasSubmodules ? false,
  withLastModifiedDate ? false,
  withLastModified ? false,
  withBump ? false,
  withExtraCommands ? "",
  gitUrl,
  fetchLatestRev,
  # from nyx:
  nyx-generic-git-update,
  # from nixpkgs:
  writeShellScript,
}:

let
  moreThanABoolean =
    default: x:
    if x == null || x == false then
      "0"
    else if x == true then
      default
    else
      x;
in
writeShellScript "update-${pname}-git" ''
  set -euo pipefail

  _LATEST_REV=$(${fetchLatestRev})

  HAS_CARGO=${if hasCargo then "1" else "0"} \
  HAS_SUBMODULES=${if hasSubmodules then "1" else "0"} \
  WITH_LAST_DATE=${moreThanABoolean "1" withLastModifiedDate} \
  WITH_LAST_STAMP=${if withLastModified then "1" else "0"} \
  WITH_BUMP_STAMP=${if withBump then "1" else "0"} \
  WITH_EXTRA=${withExtraCommands} \
    exec "${nyx-generic-git-update}/bin/nyx-generic-update" \
    "${pname}" "${nyxKey}" "${versionPath}" \
    "${gitUrl}" "$_LATEST_REV"
''
