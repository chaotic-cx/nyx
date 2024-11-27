{ final
, scx
, scx-common
,
}:

(scx.rustscheds.override {
  scx = final.scx_git;
}).overrideAttrs {
  inherit (scx-common) src version cargoHash;
}
