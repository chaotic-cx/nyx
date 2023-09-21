{ flakes
, flake-schemas ? flakes.flake-schemas
}:
{
  inherit (flake-schemas.schemas) devShells overlays schemas;
  packages = {
    version = 1;
    doc = ''
      The `packages` flake output contains packages that can be added to a shell using `nix shell`.
    '';
    inventory = _output: { what = "whatever"; };
  };
  _dev = {
    version = 1;
    doc = ''
      Pre-prepared values for CI/CD.
    '';
    inventory = _output: { what = "whatever"; };
  };
}
