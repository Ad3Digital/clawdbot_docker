#!/bin/bash
# Watchdog interno para processar ops-requests e restart flags

OPS_DIR="/root/clawd/ops-requests"
RESTART_FLAG="/root/.clawdbot/restart.flag"

echo "[WATCHDOG] Starting internal watchdog..."

while true; do
    # Check for restart flag
    if [ -f "$RESTART_FLAG" ]; then
        echo "[WATCHDOG] Restart flag detected, restarting Clawdbot..."
        rm -f "$RESTART_FLAG"
        pkill -TERM clawdbot
        sleep 2
        clawdbot gateway --bind lan &
    fi

    # Process ops-requests
    for req in "$OPS_DIR"/req-*.json; do
        if [ -f "$req" ]; then
            echo "[WATCHDOG] Processing request: $req"
            ACTION=$(jq -r '.action // empty' "$req" 2>/dev/null)

            case "$ACTION" in
                restart)
                    echo "[WATCHDOG] Executing restart..."
                    mv "$req" "$OPS_DIR/done/"
                    pkill -TERM clawdbot
                    sleep 2
                    clawdbot gateway --bind lan &
                    ;;
                set_model)
                    MODEL=$(jq -r '.model // empty' "$req" 2>/dev/null)
                    echo "[WATCHDOG] Setting model to: $MODEL"
                    # Implementar set_model se necessário
                    mv "$req" "$OPS_DIR/done/"
                    ;;
                set_timezone)
                    TZ=$(jq -r '.timezone // empty' "$req" 2>/dev/null)
                    echo "[WATCHDOG] Setting timezone to: $TZ"
                    export TZ
                    mv "$req" "$OPS_DIR/done/"
                    ;;
                *)
                    echo "[WATCHDOG] Unknown action: $ACTION"
                    mv "$req" "$OPS_DIR/error/"
                    ;;
            esac
        fi
    done

    sleep 5
done
