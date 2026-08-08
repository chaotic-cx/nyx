# Extracted from https://github.com/NixOS/nixpkgs/blob/b7c2ada94fe99c15b0dbcf4d11fd7850b957a436/pkgs/development/libraries/mesa/default.nix#L136
{
  lib,
  fetchCrate,
  runCommand,
  rustDeps ? lib.importJSON ./wraps.json,
}:
let
  fetchDep =
    dep:
    fetchCrate {
      inherit (dep) pname version hash;
      unpack = false;
    };

  toCommand = dep: "ln -s ${dep} $out/${dep.pname}-${dep.version}.tar.gz";

  packageCacheCommand = lib.pipe rustDeps [
    (map fetchDep)
    (map toCommand)
    (lib.concatStringsSep "\n")
  ];
in
runCommand "mesa-package-cache-dir" { } ''
  mkdir -p $out
  ${packageCacheCommand}
''
