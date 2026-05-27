{
  inputs = {
    chaotic.url = "../";
    compare-to.url = "../";
    systems.url = "github:nix-systems/default";
    yafas = {
      url = "github:UbiqueLambda/yafas";
      inputs.systems.follows = "systems";
      inputs.flake-schemas.follows = "chaotic/flake-schemas";
    };
    niks3 = {
      url = "github:Mic92/niks3/v1.6.0";
      inputs.nixpkgs.follows = "chaotic/nixpkgs";
    };
  };
  outputs =
    {
      chaotic,
      compare-to,
      systems,
      yafas,
      niks3,
      ...
    }:
    let
      inputs = chaotic.inputs // {
        self = final;
        inherit compare-to systems yafas;
      };
      final = chaotic // {
        schemas = import ./schemas { flakes = inputs; };
        legacyPackages = import ./dev-pkgs chaotic.legacyPackages {
          flakes = inputs;
          inherit niks3;
        };
        _dev = import ./dev {
          flakes = inputs;
          inherit (chaotic) nixConfig utils;
        };
      };
    in
    final;
}
