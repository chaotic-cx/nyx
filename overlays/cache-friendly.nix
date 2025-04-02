{
  flakes,
  nixpkgsConfig ? null,
}:
userFinal: _userPrev:
let
  inherit (userFinal) stdenv;
  inherit (stdenv.hostPlatform) system;

  isCross = stdenv.buildPlatform != stdenv.hostPlatform;

  config =
    if nixpkgsConfig == null then flakes.nixpkgs.legacyPackages.${system}.config else nixpkgsConfig;

  prev =
    if isCross then
      import "${flakes.nixpkgs}" {
        inherit config;
        localSystem = stdenv.buildPlatform;
        crossSystem = stdenv.hostPlatform;
      }
    else
      import "${flakes.nixpkgs}" {
        inherit config;
        localSystem = flakes.nixpkgs.legacyPackages."${system}".stdenv.hostPlatform;
      };
in
flakes.self.utils.applyOverlay { pkgs = prev; }
