{ prev, final, gitOverride, ... }:

gitOverride {
  # newInputs = with final; { glib = glib_git; };

  nyxKey = "glibmm_git";
  prev = prev.glibmm_2_68;

  versionNyxPath = "pkgs/glibmm-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "glibmm";
  };
  ref = "master";

  postOverride = prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with final; [
      doxygen
      graphviz-nox
      libxslt
      (mm-common.overrideAttrs (_prevAttrs: {
        postInstall = ''
          patchShebangs $out/bin
        '';
      }))
      perl538
      perl538Packages.XMLParser
      python310
    ]);
    mesonFlags = [
      (final.lib.strings.mesonBool "maintainer-mode" true)
    ];
    preConfigure = ''
      patchShebangs tools
    '';
  };
}
