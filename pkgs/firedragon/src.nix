{ fetchurl
, fetchFromGitLab
,
}:
let
  src = builtins.fromJSON (builtins.readFile ./src.json);
in
{
  inherit (src) packageVersion;
  source = fetchFromGitLab {
    owner = "librewolf-community/browser";
    repo = "source";
    fetchSubmodules = true;
    inherit (src.source) rev hash;
  };
  source-firedragon = fetchFromGitLab {
    owner = "dr460nf1r3";
    repo = "settings";
    fetchSubmodules = true;
    inherit (src.firedragon) rev hash;
  };
  firefox = fetchurl {
    url = "mirror://mozilla/firefox/releases/${src.firefox.version}/source/firefox-${src.firefox.version}.source.tar.xz";
    inherit (src.firefox) hash;
  };
}
