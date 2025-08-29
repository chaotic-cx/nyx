{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "river_git";
  prev = prev.river;

  newInputs = with final; {
    zig_0_14 = zig_0_15;
  };

  versionNyxPath = "pkgs/river-git/version.json";
  fetcher = "fetchFromGitea";
  fetcherData = {
    owner = "river";
    repo = "river";
    domain = "codeberg.org";
    fetchSubmodules = true;
  };
  ref = "0.3.x";

  withExtraUpdateCommands = final.writeShellScript "bump-zig-zon" ''
    pushd "$_LATEST_PATH"
    ${final.zon2nix}/bin/zon2nix > "$_NYX_DIR/$_PKG_DIR/build.zig.zon.nix"
    popd

    git add "$_PKG_DIR/build.zig.zon.nix"
  '';

  postOverride = _prevAttrs: {
    deps = final.callPackage ./build.zig.zon.nix { };
  };
}
