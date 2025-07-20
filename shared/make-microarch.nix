{
  nixpkgs,
  final,
  selfOverlay,
  nixpkgsExtraConfig,
}:
cpuType: arch:
with final;
import "${nixpkgs}" {
  config = final.config // nixpkgsExtraConfig;
  overlays = [
    selfOverlay
    (_final': prev': {
      libuv = prev'.libuv.overrideAttrs (_prevattrs: {
        doCheck = false;
      });
    })
    (_final': prev': {
      "pkgs${builtins.replaceStrings [ "-" ] [ "_" ] arch}" = prev';
    })
  ]
  ++
    lib.optionals
      (builtins.elem arch [
        "x86-64-v4"
        "znver4"
      ])
      [
        (_final': prev': {
          coreutils = prev'.coreutils.overrideAttrs (_prevattrs: {
            doCheck = false;
          });
          ltrace = prev'.ltrace.overrideAttrs (_prevattrs: {
            doCheck = false;
          });
        })
      ]
  ++ overlays;
  ${if stdenv.hostPlatform == stdenv.buildPlatform then "localSystem" else "crossSystem"} = {
    config = lib.systems.parse.tripleFromSystem (
      stdenv.hostPlatform.parsed
      // {
        cpu = lib.systems.parse.cpuTypes."${cpuType}";
      }
    );
    gcc = stdenv.hostPlatform.gcc // {
      inherit arch;
    };
  };
}
// {
  recurseForDerivations = false;
  _description = "Nixpkgs + Chaotic-Nyx packages built for the ${arch} microarchitecture.";
}
