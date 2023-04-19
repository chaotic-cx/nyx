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
      recursive =
        namespace: n: v:
        (if (builtins.tryEval v).success then
          (if lib.attrsets.isDerivation v then
            (if (v.meta.broken or true) then
              warnFn n v "broken"
            else if (v.meta.unfree or true) then
              warnFn n v "unfree"
            else
              mapFn (join namespace n) v
            )
          else if builtins.isAttrs v then
            lib.attrsets.mapAttrsToList (recursive (join namespace n)) v
          else
            warnFn n v "unrelated"
          )
        else
          warnFn n v "not evaluating"
        )
      ;
    in
    recursive "" "" root;

  evalToString = mapFn: root:
    let
      warnFn = k: _: message:
        "# ${message}: ${k}";
    in
    lib.strings.concatStringsSep "\n"
      (lib.lists.flatten (eval warnFn mapFn root));
}
