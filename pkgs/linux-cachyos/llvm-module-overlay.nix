{ final, nyxUtils, ... }: kernel: prevModule:

nyxUtils.multiOverride prevModule { stdenv = stdenvLLVM; } (prevAttrs:
let
  inherit (final.lib.trivial) pipe;

  tmpPath = "/build/lto_kernel";
  fixKernelBuild = builtins.replaceStrings [ "${kernel.dev}" ] [ tmpPath ];
  mapFixKernelBuild = builtins.map fixKernelBuild;

  filteredMakeFlags = mapFixKernelBuild (prevAttrs.makeFlags or [ ]);

  fixAttrList = k: attrs:
    if prevAttrs ? "${k}"
    then attrs // { "${k}" = mapFixKernelBuild prevAttrs."${k}"; }
    else attrs;

  fixAttrString = k: attrs:
    if prevAttrs ? "${k}"
    then attrs // { "${k}" = fixKernelBuild prevAttrs."${k}"; }
    else attrs;

  baseFix = {
    patchPhase = ''
      cp -r ${kernel.dev} ${tmpPath}
      chmod -R +w ${tmpPath}
    '' + (prevAttrs.patchPhase or "");
    makeFlags = filteredMakeFlags ++ [ "LLVM=1" "LLVM_IAS=1" ];
  };
in
pipe baseFix
  [
    (fixAttrList "configureFlags")
    (fixAttrString "KERN_DIR")
  ]
)
