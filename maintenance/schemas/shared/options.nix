{
  optionMap = k: v:
    {
      name = "chaotic.${k}";
      value = {
        what = "option";
        shortDescription =
          if (v.visible or true)
          then builtins.replaceStrings [ "\n" "\t" ] [ " " " " ] v.description
          else "RENAMED or REMOVED";
        #evalChecks.isDerivation = false;
      };
    };

  optionWarn = k: v: message:
    {
      name = "chaotic.${k}";
      value = {
        what = message;
        shortDescription =
          if v ? description
          then builtins.replaceStrings [ "\n" "\t" ] [ " " " " ] v.description
          else "N/A";
        #value.evalChecks.isDerivation = false;
      };
    };
}
