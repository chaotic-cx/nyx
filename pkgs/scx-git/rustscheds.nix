{
  final,
  scx,
  scx-common,
  rustPlatform,
  protobuf,
  libseccomp,
}:

(scx.rustscheds.override {
  scx = final.scx_git;
}).overrideAttrs
  (prevAttrs: {
    inherit (scx-common) version src patches;
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (scx-common) src;
      hash = scx-common.cargoHash;
    };
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ protobuf ];
    buildInputs = prevAttrs.buildInputs ++ [ libseccomp ];
  })
