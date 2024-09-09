{
  inputs = {
    chaotic.url = "../";
    compare-to.url = "https://flakehub.com/f/chaotic-cx/nix-empty-flake/=0.1.2.tar.gz";
    systems.url = "github:nix-systems/default-linux";
    yafas = {
      url = "github:UbiqueLambda/yafas";
      inputs.systems.follows = "systems";
      inputs.flake-schemas.follows = "chaotic/flake-schemas";
    };
  };
  outputs = { self, chaotic, compare-to, systems, yafas }:
    let
      inputs = chaotic.inputs // { self = final; inherit compare-to systems yafas; };
      final = chaotic // {
        schemas = import ./schemas { flakes = inputs; };
        devShells = import ./dev-shells { flakes = inputs; };
        _dev = import ./dev { flakes = inputs; inherit (chaotic) nixConfig utils; };
      };
    in
    final;
}
