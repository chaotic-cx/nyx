{ final, prev, gitOverride, conduwuitPins, ... }:
let
  rocksdb_fixed = with final; rocksdb.override {
    jemalloc = rust-jemalloc-sys-unprefixed;
  };
in
gitOverride {
  nyxKey = "conduwuit_git";
  prev = prev.matrix-conduit;

  newInputs = with final; {
    rust-jemalloc-sys = rust-jemalloc-sys-unprefixed;
    rocksdb = rocksdb_fixed;
  };

  versionNyxPath = "pkgs/conduwuit-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "girlbossceo";
    repo = "conduwuit";
  };

  withCargoDeps = lockFile: final.rustPlatform.importCargoLock {
    inherit lockFile;
    outputHashes = conduwuitPins;
  };

  withExtraUpdateCommands = final.writeShellScript "patch-cargo" ''
    pushd "$_PKG_DIR"
    ${final.patch}/bin/patch -p1 --batch < ${./cargo-lock.diff}
    git add Cargo.lock
    popd
  '';

  postOverride = prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ ./cargo-lock.diff ./cargo-toml.diff ];
    preBuild = "";
    pname = "conduwuit";
    env = prevAttrs.env // {
      ROCKSDB_INCLUDE_DIR = "${rocksdb_fixed}/include";
      ROCKSDB_LIB_DIR = "${rocksdb_fixed}/lib";
    };
  };
}
