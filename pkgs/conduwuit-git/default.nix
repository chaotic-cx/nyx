{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  bzip2,
  zstd,
  stdenv,
  rocksdb,
  callPackage,
  testers,
  autoPatchelfHook,
  libgcc,
  nyxUtils,
  # upstream conduwuit enables jemalloc by default, so we follow suit (except when using Fenix)
  enableJemalloc ? true,
  rust-jemalloc-sys,
  enableLiburing ? stdenv.hostPlatform.isLinux,
  liburing,
}:
let
  rust-jemalloc-sys' = rust-jemalloc-sys.override {
    unprefixed = !stdenv.hostPlatform.isDarwin;
  };
  rocksdb' = rocksdb.override {
    inherit enableLiburing;
    # rocksdb does not support prefixed jemalloc, which is required on darwin
    enableJemalloc = enableJemalloc && !stdenv.hostPlatform.isDarwin;
    jemalloc = rust-jemalloc-sys';
  };
  current = lib.importJSON ./version.json;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "conduwuit";
  inherit (current) version cargoHash;

  src = fetchFromGitHub {
    owner = "girlbossceo";
    repo = "conduwuit";
    inherit (current) rev hash;
  };

  useFetchCargoVendor = true;

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ] ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  buildInputs =
    [
      bzip2
      zstd
      rocksdb
    ]
    ++ lib.optional stdenv.hostPlatform.isLinux libgcc.libgcc
    ++ lib.optional enableJemalloc rust-jemalloc-sys'
    ++ lib.optional enableLiburing liburing;

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
    ROCKSDB_INCLUDE_DIR = "${rocksdb'}/include";
    ROCKSDB_LIB_DIR = "${rocksdb'}/lib";
    CONDUWUIT_VERSION_EXTRA = "${nyxUtils.shorter current.rev}+nyx";
  };

  # See https://github.com/girlbossceo/conduwuit/blob/main/src/main/Cargo.toml
  # for available features.
  # We enable all default features except jemalloc and io_uring, which
  # we guard behind our own (default-enabled) flags.
  # We need blurhashing, sentry requires opt-in during runtime (set `sentry = true` in your config)
  buildNoDefaultFeatures = false;
  cargoBuildNoDefaultFeatures = false;
  cargoCheckNoDefaultFeatures = false;
  buildFeatures = [
    "blurhashing"
    "sentry_telemetry"
  ];
  cargoBuildFeatures = [
    "blurhashing"
    "sentry_telemetry"
  ];
  cargoCheckFeatures = [
    "blurhashing"
    "sentry_telemetry"
  ];

  passthru.tests = {
    version = testers.testVersion {
      inherit (finalAttrs) version;
      package = finalAttrs.finalPackage;
    };
  };

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "conduwuit_git";
    versionPath = "pkgs/conduwuit-git/version.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "master" finalAttrs.src;
    prefetchUrl = finalAttrs.src.url;
  };

  meta = {
    description = "Matrix homeserver written in Rust, forked from conduit";
    homepage = "https://conduwuit.puppyirl.gay/";
    changelog = "https://github.com/girlbossceo/conduwuit/releases";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ pedrohlc ];
    mainProgram = "conduwuit";
  };
})
