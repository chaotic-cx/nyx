{
  prev,
  gitOverride,
  final,
  ...
}:

let
  generateDeps = final.callPackage ./deps.nix {
    name = "ghostty_git-zig-deps";
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

  withExtraUpdateCommands = final.writeShellScript "bump-ghostty-zon" ''
    pushd "$_LATEST_PATH"
    cp deps/packages.nix "$_NYX_DIR/$_PKG_DIR/deps.nix"
    popd

    git add "$_PKG_DIR/deps.nix"
  '';

  preOverride = _prevAttrs: {
    patches = [ ];
  };
  postOverride = prevAttrs: {
    doCheck = false;
    dontVersionCheck = true;
    deps = generateDeps;
    nativeBuildInputs = map (
      pkg: if pkg.pname or null == "zig" then final.zig_0_17 else pkg
    ) prevAttrs.nativeBuildInputs;

    # git builds no longer ship libghostty-vt; make upstream cleanup idempotent
    postInstall =
      builtins.replaceStrings
        [
          "rm -r $out/include/ghostty/{vt.h,vt}"
          "rm $out/lib/libghostty-vt.*"
          "rm $out/share/pkgconfig/libghostty-vt*.pc"
        ]
        [
          "rm -rf $out/include/ghostty/vt.h $out/include/ghostty/vt"
          "rm -f $out/lib/libghostty-vt.*"
          "rm -f $out/share/pkgconfig/libghostty-vt*.pc"
        ]
        (prevAttrs.postInstall or "");

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
