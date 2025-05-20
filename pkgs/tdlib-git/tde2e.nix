{ final, ... }:

final.tdlib_git.overrideAttrs (prevAttrs: {
  pname = "tde2e";
  cmakeFlags = (prevAttrs.cmakeFlags or [ ]) ++ [
    (final.lib.cmakeBool "TD_E2E_ONLY" true)
  ];
})
