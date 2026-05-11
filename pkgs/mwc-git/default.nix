{
  final,
  gitOverride,
  ...
}:

let
  pkgsWithOverlay = final.extend (
    self: super: {

      wlroots_0_18 = super.wlroots_0_18.overrideAttrs (old: {
        mesonFlags = (old.mesonFlags or [ ]) ++ [
          "-Dwerror=false"
        ];
      });

      scenefx_0_2 = super.scenefx.overrideAttrs (old: {
        version = "0.2.1";

        src = super.fetchFromGitHub {
          owner = "wlrfx";
          repo = "scenefx";
          rev = "0.2.1";
          hash = "sha256-BLIADMQwPJUtl6hFBhh5/xyYwLFDnNQz0RtgWO/Ua8s=";
        };

        buildInputs = (old.buildInputs or [ ]) ++ [
          self.wlroots_0_18
        ];
      });

    }
  );

  stable = pkgsWithOverlay.callPackage ./package.nix { };
in
gitOverride {
  nyxKey = "mwc_git";
  prev = stable;

  versionNyxPath = "pkgs/mwc-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "dqrk0jeste";
    repo = "mwc";
    fetchSubmodules = true;
  };

  extraPassthru = {
    inherit stable;
  };
}
