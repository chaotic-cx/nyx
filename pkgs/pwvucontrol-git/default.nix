{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "pwvucontrol_git";
  prev = prev.pwvucontrol;

  newInputs = {
    wireplumber = final.wireplumber.overrideAttrs (_prevAttrs: {
      # https://github.com/NixOS/nixpkgs/pull/389740
      patches = [
        (final.fetchpatch {
          url = "https://gitlab.freedesktop.org/pipewire/wireplumber/-/commit/f4f495ee212c46611303dec9cd18996830d7f721.patch";
          hash = "sha256-dxVlXFGyNvWKZBrZniFatPPnK+38pFGig7LGAsc6Ydc=";
        })
      ];
    });
  };

  versionNyxPath = "pkgs/pwvucontrol-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "saivert";
    repo = "pwvucontrol";
  };
}
