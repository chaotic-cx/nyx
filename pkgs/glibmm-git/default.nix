{ prev, final, gitOverride, ... }:

let
  srcMeta = {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "glibmm";
  };
in
gitOverride {
  newInputs = with final; { glib = glib_git; };
  nyxKey = "glibmm_git";
  versionNyxPath = "pkgs/glibmm-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.glibmm_2_68;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitLab (srcMeta // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/gitlab-rev-fetcher.nix { src = src // srcMeta; ref = "master"; };

  postOverrides = [
    (prevAttrs: rec {
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
    })
  ];
}
