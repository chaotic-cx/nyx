{ scx
, scx-common
,
}:

scx.cscheds.overrideAttrs {
  inherit (scx-common) src version;
}
