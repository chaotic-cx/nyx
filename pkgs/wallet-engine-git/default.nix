{
  lib,
  callPackage,
  rustPlatform,
  fetchFromGitHub,
  fetchpatch,
  wallet-engine-bindgen_git,
}:
let
  current = lib.importJSON ./manifest.json;
  # Pinned to the revision Telegram's Dockerfile fetches.
  patchesRev = "aec474953ff7ee9b6e4cd9b8658288ea86d124f3";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wallet-engine";
  inherit (current) version;

  src = fetchFromGitHub {
    owner = "i582";
    repo = "wallet-engine";
    inherit (current) rev hash;
  };

  inherit (current) cargoHash;

  # Adds TonConnectSignDataCellDecoding, which wallet_session.cpp calls.
  patches = [
    (fetchpatch {
      name = "wallet-engine.patch";
      url = "https://raw.githubusercontent.com/desktop-app/patches/${patchesRev}/wallet-engine.patch";
      hash = current.patchHash;
    })
  ];

  buildPhase = ''
    runHook preBuild

    cargo rustc \
      --release \
      --lib \
      --crate-type staticlib --crate-type cdylib

    # Runs here: the generator dlopens the .so to read the UniFFI metadata.
    ${wallet-engine-bindgen_git}/bin/uniffi-bindgen-cpp \
      --library \
      --out-dir bindgen-out \
      target/release/libwallet_engine.so

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 target/release/libwallet_engine.a "$out/lib/libwallet_engine.a"

    install -Dm644 bindgen-out/wallet_engine.hpp \
      "$out/include/wallet_engine/wallet_engine.hpp"
    install -Dm644 bindgen-out/wallet_engine.cpp \
      "$out/include/wallet_engine/wallet_engine.cpp"
    install -Dm644 bindgen-out/wallet_engine_scaffolding.hpp \
      "$out/include/wallet_engine/wallet_engine_scaffolding.hpp"

    runHook postInstall
  '';

  doCheck = false;

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "wallet-engine_git";
    manifestPath = "pkgs/wallet-engine-git/manifest.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "dev" finalAttrs.src;
    gitUrl = finalAttrs.src.gitRepoUrl;
    hasCargo = true;
  };

  meta = {
    description = "TON wallet engine used by Telegram Desktop";
    homepage = "https://github.com/i582/wallet-engine";
    license = with lib.licenses; [
      mit
      asl20
    ];
    maintainers = with lib.maintainers; [ lonerOrz ];
  };
})
