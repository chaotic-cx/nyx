{ final
, inputs
, nyxUtils
, prev
, ...
}:

final.swaylock.overrideAttrs (pa: {
  pname = "swaylock-plugin";
  version = nyxUtils.gitToVersion inputs.swaylock-plugin-git-src;
  src = inputs.swaylock-plugin-git-src;
})
