{ lib }:
rec {
  # For viewing in our documentation page.
  _description = "Pack of functions that are useful for Chaotic-Nyx and might become useful for you too";

  # When `removeByBaseName` and `removeByURL` can't help, use this to drop patches.
  dropN = n: list: lib.lists.take (builtins.length list - n) list;

  # Helps when batch-overriding.
  dropAttrsUpdateScript = builtins.mapAttrs (_: v:
    if (v.passthru.updateScript or null) != null then
      v.overrideAttrs dropUpdateScript
    else v
  );

  # Helps when overriding.
  dropUpdateScript = prevAttrs:
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
  multiOverride = prev: newInputs: (prev.override newInputs).overrideAttrs;

  # Helps when overriding both inputs and outputs attrs, multiple times.
  multiOverrides = prev: newInputs: lib.lists.foldl
    (accu: accu.overrideAttrs)
    (prev.override newInputs);

  # Helps when overriding.
  overrideDescription = descriptionMap: prevAttrs: {
    meta = (rejectAttr "longDescription" pa.meta) // {
      description = descriptionMap pa.meta.description;
    };
  };

  # Helps removing attrs.
  rejectAttr = x: lib.attrsets.filterAttrs (n: _: n != x);

  # Helps when dropping patches.
  removeByBaseName = baseName:
    builtins.filter (x: builtins.baseNameOf x != baseName);

  # Helps when dropping patches.
  removeByURL = url: builtins.filter (x:
    !(lib.attrsets.isDerivation x) || (x.url or null) != url
  );

  # Helps updating flags
  replaceStartingWith = prefix: newSuffix: builtins.map (x:
    if lib.strings.hasPrefix prefix x then
      prefix + newSuffix
    else
      x
  );

  # Like `lib.fakeHash`, but beautier.
  unreachableHash = "sha256-2342234223422342234223422342234223422342069=";

  # We don't want builders playing around here.
  recurseForDerivations = false;
}
