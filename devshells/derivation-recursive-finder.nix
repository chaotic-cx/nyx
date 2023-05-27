{ lib }:
rec {
  join = namespace: n:
    if namespace != "" then
      "${namespace}.${n}"
    else
      n
  ;

  # warnFn: k -> v -> message -> result
  # mapFn: k -> v -> result
  # root: attrset | derivation
  eval = warnFn: mapFn: root:
    let
      recursive = namespace: key: v:
        let
          fullKey = join namespace key;
        in
        if (builtins.tryEval v).success then
          (if lib.attrsets.isDerivation v then
            [
              (if (v.meta.broken or true) then
                warnFn fullKey v "broken"
              else if (v.meta.unfree or true) then
                warnFn fullKey v "unfree"
              else
                mapFn fullKey v
              )
            ] ++
            [ (lib.attrsets.mapAttrsToList (recursive fullKey) (v.passthru or { })) ]
          else if builtins.isAttrs v && (v.recurseForDerivations or true) then
            lib.attrsets.mapAttrsToList (recursive fullKey) v
          else
            warnFn fullKey v "unrelated"
          )
        else
          warnFn fullKey v "not evaluating"
      ;
    in
    recursive "" "" root;
}
