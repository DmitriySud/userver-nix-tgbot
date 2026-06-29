{ pkgs, host ? null }:

let
  script = pkgs.writeShellApplication {
    name = "tgbot-set-webhook";
    runtimeInputs = [ pkgs.curl pkgs.jq ];
    text = ''
      set -euo pipefail

      SECDIST="''${TGBOT_SECDIST:-/run/secrets/tgbot-secdist}"
      CERT_PUB="''${TGBOT_CERT_PUB:-/run/secrets/tgbot-cert-pub}"
      HOST="''${TGBOT_HOST:-${if host == null then "" else host}}"
      PORT="''${TGBOT_PORT:-8443}"
      DRY_RUN="''${TGBOT_DRY_RUN:-0}"

      # also accept --dry-run as an argument
      for arg in "$@"; do
        case "$arg" in
          --dry-run|-n) DRY_RUN=1 ;;
        esac
      done

      if [ -z "$HOST" ]; then
        echo "error: set TGBOT_HOST (public IP or DNS the cert is issued for)" >&2
        exit 1
      fi
      if [ ! -r "$SECDIST" ]; then
        echo "error: cannot read secdist at $SECDIST" >&2
        exit 1
      fi
      if [ ! -r "$CERT_PUB" ]; then
        echo "error: cannot read public cert at $CERT_PUB" >&2
        exit 1
      fi

      TELEGRAM_BOT_TOKEN="$(jq -er '.telegram_bot_token' "$SECDIST")"
      SECRET_PATH="$(jq -er '.secret_path' "$SECDIST")"

      WEBHOOK_URL="https://''${HOST}:''${PORT}/webhook/''${SECRET_PATH}"
      API_URL="https://api.telegram.org/bot''${TELEGRAM_BOT_TOKEN}/setWebhook"

      # Build args once; reuse for both print and execute.
      curl_args=(
        -fsS
        -F "url=''${WEBHOOK_URL}"
        -F "certificate=@''${CERT_PUB}"
        -F "allowed_updates=[\"message\",\"callback_query\"]"
        "$API_URL"
      )

      if [ "$DRY_RUN" = "1" ]; then
        # Redacted, copy-pasteable command. Token replaced with a placeholder
        # so the printed line is safe to share; the URL secret_path is kept
        # since you need it to actually run.
        redacted_api="https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/setWebhook"
        printed=(curl)
        for a in "''${curl_args[@]}"; do
          if [ "$a" = "$API_URL" ]; then a="$redacted_api"; fi
          printed+=("$(printf '%q' "$a")")
        done
        echo "# dry-run: would execute (token redacted)" >&2
        echo "''${printed[*]}"
        echo "# also: getWebhookInfo" >&2
        echo "curl -fsS https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/getWebhookInfo | jq ."
        exit 0
      fi

      echo "Setting webhook -> $WEBHOOK_URL" >&2

      response="$(curl "''${curl_args[@]}")"
      echo "$response" | jq .

      if [ "$(echo "$response" | jq -r '.ok')" != "true" ]; then
        echo "setWebhook failed" >&2
        exit 1
      fi

      echo "--- current webhook info ---" >&2
      curl -fsS "https://api.telegram.org/bot''${TELEGRAM_BOT_TOKEN}/getWebhookInfo" | jq .
    '';
  };
in
script
