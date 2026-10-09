{
  lib,
  callPackage,
  rustPlatform,
  fetchFromGitHub,
}:
let
  current = lib.importJSON ./manifest.json;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wallet-engine-bindgen";
  inherit (current) version;

  src = fetchFromGitHub {
    owner = "i582";
    repo = "wallet-engine";
    inherit (current) rev hash;
  };

  inherit (current) cargoHash;

  # bindgen/cpp is excluded from the root workspace and carries its own lock.
  sourceRoot = "${finalAttrs.src.name}/bindgen/cpp";

  buildPhase = ''
    runHook preBuild
    cargo build --release --bin uniffi-bindgen-cpp
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 target/release/uniffi-bindgen-cpp "$out/bin/uniffi-bindgen-cpp"
    runHook postInstall
  '';

  doCheck = false;

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "wallet-engine-bindgen_git";
    manifestPath = "pkgs/wallet-engine-bindgen-git/manifest.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "dev" finalAttrs.src;
    gitUrl = finalAttrs.src.gitRepoUrl;
    hasCargo = true;
  };

  meta = {
    description = "UniFFI C++ binding generator for wallet-engine";
    homepage = "https://github.com/i582/wallet-engine";
    license = with lib.licenses; [
      mit
      asl20
    ];
    maintainers = with lib.maintainers; [ lonerOrz ];
    mainProgram = "uniffi-bindgen-cpp";
  };
})
