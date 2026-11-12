{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "river_git";
  prev = prev.river-classic;

  manifestPath = "pkgs/river-git/manifest.json";
  fetcher = "fetchFromGitea";
  newInputs = {
    zig_0_16 = final.zig_0_17;
  };
  fetcherData = {
    owner = "river";
    repo = "river-classic";
    domain = "codeberg.org";
    fetchSubmodules = true;
  };

  withExtraUpdateCommands = final.writeShellScript "bump-zig-zon" ''
    pushd "$_LATEST_PATH"
    ${final.zon2nix}/bin/zon2nix > "$_NYX_DIR/$_PKG_DIR/build.zig.zon.nix"
    # strip zon2nix "?ref=" from fetchgit urls
    sed -i -E '/fetchgit \{/,/\};/ s#(url = "[^"]*)\?ref=[^"]*(")#\1\2#' -- "$_NYX_DIR/$_PKG_DIR/build.zig.zon.nix"
    popd

    git add "$_PKG_DIR/build.zig.zon.nix"
  '';

  postOverride = _prevAttrs: {
    deps = final.callPackage ./build.zig.zon.nix { };
    patches = [ ];
    # river outputs its own dev version (e.g. "0.3.16-dev") from the zig build,
    # which never matches the Nix-side "unstable-YYYYMMDD-rev" format.
    doInstallCheck = false;
  };
}
