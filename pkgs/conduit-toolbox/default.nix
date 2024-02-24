{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, fetchpatch2
, llvmPackages
, rocksdb_7_10
, zstd
, pkg-config
}:

let rocksdb = rocksdb_7_10; in
rustPlatform.buildRustPackage rec {
  pname = "conduit-toolbox";
  version = "unstable-2023-07-25";

  src = fetchFromGitHub {
    owner = "ShadowJonathan";
    repo = "conduit_toolbox";
    rev = "82c4c82b4351838a245781d3eb688c63886a96d7";
    hash = "sha256-8QRXwLKYjtjmLpH75AW23/liPUhoSDmCOhX90BAWEV8=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
     "heed-0.10.6" = "sha256-rm02pJ6wGYN4SsAbp85jBVHDQ5ITjZZd+79EC2ubRsY=";
    };
  };

  patches = [
    (fetchpatch2 {
      url = "https://github.com/ShadowJonathan/conduit_toolbox/commit/4a48ab3b503461d13bf4d7bf613381dfe1a36d4e.patch";
      hash = "sha256-BhvI0ilZwusB9kJYQD0aSwXF3jE2NppYFlVEj02NDe4=";
      revert = true;
    })
    ./update-rocksdb.diff
  ];

  postPatch = ''
    rm -r tools/sled_to_sqlite
    rm Cargo.lock
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  buildType = "debug";
  buildPackages = [ "conduit_migrate" ];

  buildInputs = [ zstd ];

  # needed for librocksdb-sys
  nativeBuildInputs = [ rustPlatform.bindgenHook pkg-config ];

  # link rocksdb dynamically
  ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
  ROCKSDB_LIB_DIR = "${rocksdb}/lib";
  # zstd issues
  ZSTD_SYS_USE_PKG_CONFIG = true;

  meta.license = lib.licenses.free;
}
