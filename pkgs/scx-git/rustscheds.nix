{
  final,
  scx,
  scx-common,
  rustPlatform,
}:

(scx.rustscheds.override {
  scx = final.scx_git;
}).overrideAttrs
  (_prevAttrs: {
    inherit (scx-common) version src patches;
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (scx-common) src;
      hash = scx-common.cargoHash;
    };
    # Cherry-picks nixpkgs#424862
    postPatch = ''
      mkdir libbpf
      cp -r ${final.scx_git.cscheds.dev}/libbpf/* libbpf/
    '';
  })
