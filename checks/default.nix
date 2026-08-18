flakes: system: {
  all-in-one = import ./all-in-one.nix {
    inherit (flakes) nixpkgs;
    inherit system;
    chaotic = flakes.self;
  };
}
