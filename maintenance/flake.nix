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
  };
  outputs =
    {
      chaotic,
      compare-to,
      systems,
      yafas,
      ...
    }:
    let
      inputs = chaotic.inputs // {
        self = final;
        inherit compare-to systems yafas;
      };
      final = chaotic // {
        schemas = import ./schemas { flakes = inputs; };
        devShells = import ./dev-shells { flakes = inputs; };
        _dev = import ./dev {
          flakes = inputs;
          inherit (chaotic) nixConfig utils;
        };
      };
    in
    final;
}
