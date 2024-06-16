{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "river_git";
  prev = prev.river;

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
    ${final.zon2nix}/bin/zon2nix > "$_NYX_DIR/$_PKG_DIR/build.zig.zon.nix"
    popd

    git add "$_PKG_DIR/build.zig.zon.nix"
  '';

  postOverride = _prevAttrs: {
    deps = final.callPackage ./build.zig.zon.nix { };
  };
}
