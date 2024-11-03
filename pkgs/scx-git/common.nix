{ lib, fetchFromGitHub, }:
let
  versionInfo = lib.importJSON ./version.json;
in
{
  inherit (versionInfo.scx) version;

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    inherit (versionInfo.scx) rev hash;
    fetchSubmodules = true;
  };
}
