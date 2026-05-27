{
  prev,
  gitOverride,
  final,
  ...
}:

let
  # Dynamically generate deps from source build.zig.zon.nix
  generateDeps =
    src:
    final.callPackage (src + "/build.zig.zon.nix") {
      name = "ghostty-git-zig-deps";
      inherit (final) zig_0_15;
    };
in
gitOverride {
  nyxKey = "ghostty_git";
  prev = prev.ghostty;

  versionNyxPath = "pkgs/ghostty-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ghostty-org";
    repo = "ghostty";
  };
  ref = "main";

  preOverride = _prevAttrs: {
    patches = [ ];
  };
  postOverride = prevAttrs: {
    doCheck = false;
    dontVersionCheck = true;
    deps = generateDeps prevAttrs.src;
    nativeBuildInputs = builtins.map (
      pkg: if pkg.pname or null == "zig" then final.zig_0_15 else pkg
    ) prevAttrs.nativeBuildInputs;

    # Use base appVersion from build.zig.zon instead of custom version-string
    # This avoids semantic version parsing errors for git builds
    zigBuildFlags = builtins.filter (
      flag: !final.lib.hasPrefix "-Dversion-string=" flag
    ) prevAttrs.zigBuildFlags;
  };
}
