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
    lockFileContents = builtins.readFile lockFile;
    outputHashes = conduwuitPins;
  };

  postOverride = prevAttrs: {
    preBuild = "";
    pname = "conduwuit";
    env = prevAttrs.env // {
      ROCKSDB_INCLUDE_DIR = "${rocksdb_fixed}/include";
      ROCKSDB_LIB_DIR = "${rocksdb_fixed}/lib";
    };
  };
}
