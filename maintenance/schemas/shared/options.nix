{
  optionMap = k: v:
    {
      name = "chaotic.${k}";
      value = {
        what = "option";
        shortDescription =
          builtins.replaceStrings [ "\n" "\t" ] [ " " " " ] v.description;
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
