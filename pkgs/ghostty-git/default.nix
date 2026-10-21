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
      inherit (final) zig_0_17;
    };
in
gitOverride {
  nyxKey = "ghostty_git";
  prev = prev.ghostty;

  manifestPath = "pkgs/ghostty-git/manifest.json";
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
    nativeBuildInputs = map (
      pkg: if pkg.pname or null == "zig" then final.zig_0_17 else pkg
    ) prevAttrs.nativeBuildInputs;

    postFixup =
      builtins.replaceStrings
        [
          "\nsubstituteInPlace $out/share/applications/com.mitchellh.ghostty.desktop \\\n  --replace-fail \"Exec=$out/bin/ghostty\" \"Exec=ghostty\"\n"
        ]
        [ "" ]
        (prevAttrs.postFixup or "");

    # Use base appVersion from build.zig.zon instead of custom version-string
    # This avoids semantic version parsing errors for git builds
    zigBuildFlags = builtins.filter (
      flag: !final.lib.hasPrefix "-Dversion-string=" flag
    ) prevAttrs.zigBuildFlags;
  };
}
