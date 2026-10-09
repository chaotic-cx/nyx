{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  newInputs = with final; {
    # I hope I don't go to robot-hell bc of this:
    callPackage =
      file: args:
      let
        realCall = callPackage file args;
      in
      if baseNameOf file == "tg_owt.nix" then tg-owt_git else realCall;
  };

  nyxKey = "telegram-desktop-unwrapped_git";
  prev = prev.telegram-desktop.unwrapped;

  manifestPath = "pkgs/telegram-desktop-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "telegramdesktop";
    repo = "tdesktop";
    fetchSubmodules = true;
  };
  ref = "dev";

  postOverride =
    prevAttrs:
    let
      edgesType = "Iv${"::"}Markdown${"::"}MarkdownArticleBubbleEdges";
    in
    {
      postPatch = (prevAttrs.postPatch or "") + ''
        substituteInPlace Telegram/SourceFiles/history/view/history_view_message.cpp \
          --replace-fail \
          '${"\t"}const auto bubble = drawBubble();${"\n"}${"\t"}return {' \
          '${"\t"}const auto bubble = drawBubble();${"\n"}${"\t"}return ${edgesType}{'
      '';

      # AssertIsDebug() is only available in _DEBUG builds, define it away
      env = (prevAttrs.env or { }) // {
        NIX_CFLAGS_COMPILE = (prevAttrs.env.NIX_CFLAGS_COMPILE or "") + " -DAssertIsDebug(...)=;";
      };

      buildInputs =
        prevAttrs.buildInputs
        ++ (with final; [
          tde2e_git
          tlottie_git
          wallet-engine_git

          minizip
          pango
          libsysprof-capture
        ]);
    };
}
