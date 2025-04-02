{ final, prev, ... }:
prev.fetchgit.override {
  git =
    with final;
    writeShellScriptBin "git" ''
      set -eu
      _TOR_PORT=$(($(($$ % 64511)) + 1024))
      _TOR_LOG="/build/fetchtorgit-''${_TOR_PORT}.log"

      ${tor}/bin/tor --SocksPort $_TOR_PORT 2>&1 >"$_TOR_LOG" &
      _TOR_PID=$!

      echo "Waiting bootstrap" >&2
      _START_TIME=$(date +%s)
      _TIMEOUT_TIME=$(($_START_TIME + 60))
      while true; do
        grep -q 'Bootstrapped 100% (done): Done' "$_TOR_LOG" && break
        if [ "$(date +%s)" -ge "$_TIMEOUT_TIME" ]; then
          echo "Bootstrap took too long." >&2
          exit 69
        fi
        sleep 2
      done
      echo "Bootstrap done" >&2

      _GIT_STATUS=0
      '${git}/bin/git' -c http.proxy=socks5h://127.0.0.1:$_TOR_PORT "$@" || _GIT_STATUS=$?

      kill $_TOR_PID || true
      exit ''$_GIT_STATUS
    '';
}
