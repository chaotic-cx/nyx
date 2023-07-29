{ lib, callPackage }:
rec {
  # When `removeByBaseName` and `removeByURL` can't help, use this to drop patches.
  dropN = n: list: lib.lists.take (builtins.length list - n) list;

  # Helps when batch-overriding.
  dropAttrsUpdateScript = builtins.mapAttrs (_: v:
    if (v.passthru.updateScript or null) != null then
      v.overrideAttrs dropUpdateScript
    else v
  );

  # Helps when overriding.
  dropUpdateScript = pa:
    { passthru = pa.passthru // { updateScript = null; }; };

  # NOTE: Don't use in your system's configuration, this helps in the repo's infra.
  # Checks if a derivation is in a list.
  drvElem = x: xs:
    builtins.elem x.drvPath (builtins.map (xsx: xsx.drvPath) xs);

  # NOTE: Don't use in your system's configuration, this helps in the repo's infra
  # Get's the hash of a derivation.
  drvHash = drv:
    builtins.substring 0 32 (builtins.baseNameOf (builtins.unsafeDiscardStringContext drv.drvPath));


  # NOTE: Don't use in your system's configuration, this helps in the repo's infra.
  # Finds dependencies in a derivation that are also present in a attrset filled with derivations.
  internalDeps = packages: drv:
    let
      allDeps = lib.strings.concatStringsSep " "
        (builtins.attrNames (builtins.getContext (builtins.toJSON drv.drvAttrs)));
    in
    builtins.filter (x: lib.strings.hasInfix (builtins.unsafeDiscardStringContext x.drvPath) allDeps) packages;

  # Helps when converting flakes to src.
  gitToVersion = src: "unstable-${src.lastModifiedDate}-${src.shortRev}";

  # Helps when converting flakes to src.
  gitOverride = src: drv:
    drv.overrideAttrs (_: {
      version = gitToVersion src;
      inherit src;
    });

  # Helps when overriding both inputs and outputs attrs.
  multiOverride = prev: newInputs: outputMap:
    (prev.override newInputs).overrideAttrs outputMap;

  # Helps when overriding both inputs and outputs attrs, multiple times.
  multiOverrides = prev: newInputs: outputMaps:
    lib.lists.foldl
      (accu: item: accu.overrideAttrs item)
      (prev.override newInputs)
      outputMaps;

  # Helps when overriding.
  overrideDescription = descriptionMap: pa:
    { meta = pa.meta // { description = descriptionMap pa.meta.description; }; };

  # Helps when dropping patches.
  removeByBaseName = baseName:
    builtins.filter (x: builtins.baseNameOf x != baseName);

  # Helps when dropping patches.
  removeByURL = url: builtins.filter (x:
    !(lib.attrsets.isDerivation x) || (x.url or null) != url
  );

  # Like `lib.fakeHash`, but beautier.
  unreachableHash = "sha256-2342234223422342234223422342234223422342069=";

  # We don't want builders playing around here.
  recurseForDerivations = false;
}
