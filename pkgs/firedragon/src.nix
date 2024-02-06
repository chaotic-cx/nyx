{ fetchFromGitHub
, fetchFromGitLab
,
}:
let
  src = builtins.fromJSON (builtins.readFile ./src.json);
in
{
  inherit (src) packageVersion;
  firedragon-common = fetchFromGitLab {
    owner = "garuda-linux/firedragon";
    repo = "common";
    fetchSubmodules = false;
    inherit (src.common-firedragon) rev hash;
  };
  firedragon-settings = fetchFromGitLab {
    owner = "garuda-linux/firedragon";
    repo = "settings";
    fetchSubmodules = false;
    inherit (src.settings-firedragon) rev hash;
  };
  floorp = fetchFromGitHub {
    owner = "Floorp-Projects";
    repo = "Floorp";
    fetchSubmodules = true;
    inherit (src.floorp) rev hash;
  };
}
