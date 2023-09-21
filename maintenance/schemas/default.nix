{ flakes
, flake-schemas ? flakes.flake-schemas
, nixpkgs ? flakes.nixpkgs
}:
{
  inherit (flake-schemas.schemas) devShells overlays schemas;
  packages = {
    version = 1;
    doc = ''
      The `packages` flake output contains packages that can be added to a shell using `nix shell`.
    '';
    inventory = import ./packages/inventory.nix { inherit nixpkgs; };
  };
  _dev = {
    version = 1;
    doc = ''
      Pre-prepared values for CI/CD.
    '';
    inventory = _output: { what = "stuff for CI/CD"; };
  };
}
