{ lib, system }:
let
  parsedSystem = lib.systems.parse.mkSystemFromString system;
in
rec {
  join = namespace: current: if namespace != "" then "${namespace}.${current}" else current;

  # limit: integer | "explicit"
  # warnFn: k -> v -> message -> result
  # mapFn: k -> v -> result
  # root: attrset | derivation
  derivationsLimited =
    limit: warnFn: mapFn: root:
    let
      recursive =
        level: namespace: key: v:
        let
          fullKey = join namespace key;
        in
        if (builtins.tryEval v).success then
          (
            if lib.attrsets.isDerivation v then
              (
                if (v.meta.broken or true) then
                  warnFn fullKey v "marked broken"
                else if !(builtins.tryEval v.outPath).success then
                  warnFn fullKey v "out eval broken"
                else if
                  (
                    (v.meta.platforms or [ ]) != [ ]
                    && !(
                      builtins.elem system v.meta.platforms
                      || lib.systems.inspect.matchAnyAttrs (builtins.filter builtins.isAttrs v.meta.platforms) parsedSystem
                    )
                  )
                then
                  warnFn fullKey v "not marked compatible"
                else if
                  (
                    (v.meta.badPlatforms or [ ]) != [ ]
                    && (
                      builtins.elem system v.meta.badPlatforms
                      || lib.systems.inspect.matchAnyAttrs (builtins.filter builtins.isAttrs v.meta.badPlatforms) parsedSystem
                    )
                  )
                then
                  warnFn fullKey v "marked incompatible"
                else if
                  (
                    v.meta.unfree or true
                    && !(v.meta.nyx.bypassLicense or false)
                    && v.meta.license != lib.licenses.unfreeRedistributable
                  )
                then
                  warnFn fullKey v "unfree"
                else
                  mapFn fullKey v
              )
            else if
              (limit == null || limit == "explicit" || level < limit)
              && builtins.isAttrs v
              && (v.recurseForDerivations or (limit != "explicit" || level == 0))
            then
              lib.attrsets.mapAttrsToList (recursive (level + 1) fullKey) v
            else
              warnFn fullKey v "not a derivation"
          )
        else
          warnFn fullKey v "eval broken";
    in
    recursive 0 "" "" root;

  derivations = derivationsLimited null;

  # warnFn: k -> v -> message -> result
  # mapFn: k -> v -> result
  # root: module.options
  options =
    warnFn: mapFn: root:
    let
      recursive =
        namespace: key: v:
        let
          fullKey = join namespace key;
        in
        if lib.options.isOption v then
          mapFn fullKey v
        else if builtins.isAttrs v && (v.recurseForDerivations or true) then
          lib.attrsets.mapAttrsToList (recursive fullKey) v
        else
          warnFn fullKey v "not an option";
    in
    recursive "" "" root;
}
