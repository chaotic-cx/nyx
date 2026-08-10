{
  flakes,
  nixpkgsConfig ? null,
}:
final: _prev:
let
  inherit (final) stdenv;
  inherit (stdenv.hostPlatform) system;

  isCross = stdenv.buildPlatform != stdenv.hostPlatform;

  # Since nixpkgs f13ff45, `flakeNixpkgs.config` is a deferredModuleWith whose
  # merged value is { imports = [...] }, not a plain config attrset. Evaluate
  # it into one, else the config would be silently dropped on re-import.
  config =
    if nixpkgsConfig == null then
      flakes.nixpkgs.legacyPackages.${system}.config
    else if builtins.isAttrs nixpkgsConfig && builtins.isList (nixpkgsConfig.imports or null) then
      (final.lib.evalModules {
        modules = nixpkgsConfig.imports;
        class = "nixpkgsConfig";
      }).config
    else
      nixpkgsConfig;

  prevPkgs =
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
flakes.self.utils.applyOverlay { pkgs = prevPkgs; }
