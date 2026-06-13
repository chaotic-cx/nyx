{
  description = "private inputs";

  inputs = {
    # Sadly the base for everything
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixpkgs-unstable";

    # Third-party republished repositories
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-github-actions.follows = ""; # https://github.com/NixOS/nix/issues/7807
      };
    };

    # Used by "schemas" output (for FlakeHub and "nix show", pinned)
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/=0.1.5.tar.gz";

    # Newer rustc
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to the version we're using (sorry to forward this to your locks, we need it cached)
    niks3 = {
      url = "github:Mic92/niks3/c74d275536d9a38ff279b498612fae0fd68cfe85";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = ""; # https://github.com/NixOS/nix/issues/7807
      };
    };
  };

  outputs = _inputs: { };
}
