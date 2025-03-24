{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "river_git";
  prev = prev.river;

  newInputs = {
    zig_0_14 = final.zig_0_13;
  };

  versionNyxPath = "pkgs/river-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "riverwm";
    repo = "river";
    fetchSubmodules = true;
  };
  ref = "master";

  withExtraUpdateCommands = final.writeShellScript "bump-zig-zon" ''
    pushd "$_LATEST_PATH"
    ${final.zon2nix_zig_0_13}/bin/zon2nix > "$_NYX_DIR/$_PKG_DIR/build.zig.zon.nix"
    popd

    git add "$_PKG_DIR/build.zig.zon.nix"
  '';

  postOverride = _prevAttrs: {
    deps = final.callPackage ./build.zig.zon.nix { };
  };
}
