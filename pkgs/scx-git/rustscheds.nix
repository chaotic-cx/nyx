{ final
, scx
, scx-common
, rustPlatform
}:

(scx.rustscheds.override {
  scx = final.scx_git;
}).overrideAttrs {
  inherit (scx-common) version src patches;
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (scx-common) src;
    hash = scx-common.cargoHash;
  };
}
