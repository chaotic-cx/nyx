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
  pname = "tlottie";
  inherit (current) version;

  src = fetchFromGitHub {
    owner = "dkaraush";
    repo = "tlottie";
    inherit (current) rev hash;
  };

  inherit (current) cargoHash;

  buildNoDefaultFeatures = true;
  buildFeatures = [ "c-api" ];

  buildPhase = ''
    runHook preBuild

    cargo rustc \
      --release \
      --features c-api \
      --lib \
      --crate-type staticlib

    runHook postBuild
  '';

  doCheck = false;

  installPhase = ''
    runHook preInstall

    install -Dm644 \
      target/release/libtlottie.a \
      "$out/lib/libtlottie.a"

    install -Dm644 \
      include/tlottie.h \
      "$out/include/tlottie/tlottie.h"

    runHook postInstall
  '';

  runChecks = false;

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "tlottie_git";
    manifestPath = "pkgs/tlottie-git/manifest.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "dev" finalAttrs.src;
    gitUrl = finalAttrs.src.gitRepoUrl;
    hasCargo = true;
  };
})
