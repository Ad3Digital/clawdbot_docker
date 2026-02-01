#!/bin/bash
# Watchdog interno com auto-recuperação avançada

OPS_DIR="/root/clawd/ops-requests"
RESTART_FLAG="/root/.clawdbot/restart.flag"
SESSIONS_DIR="/root/.clawdbot/agents/main/sessions"
MAX_SESSION_SIZE_MB=10
LOCK_MAX_AGE_SECONDS=300
GATEWAY_HANG_THRESHOLD=600

echo "[WATCHDOG] Starting enhanced watchdog with auto-recovery..."

# Wait for gateway to start before monitoring
echo "[WATCHDOG] Waiting 30s for gateway to start..."
sleep 30

# Função para limpar locks órfãos
cleanup_orphan_locks() {
    local now=$(date +%s)
    find "$SESSIONS_DIR" -name "*.lock" 2>/dev/null | while read lock_file; do
        if [ -f "$lock_file" ]; then
            local lock_age=$((now - $(stat -c %Y "$lock_file" 2>/dev/null || echo $now)))
            if [ $lock_age -gt $LOCK_MAX_AGE_SECONDS ]; then
                local pid=$(jq -r '.pid // empty' "$lock_file" 2>/dev/null)
                if ! ps -p "$pid" > /dev/null 2>&1; then
                    echo "[WATCHDOG] Removing orphan lock: $lock_file (PID $pid is dead, age: ${lock_age}s)"
                    rm -f "$lock_file"
                fi
            fi
        fi
    done
}

# Função para arquivar sessões grandes
cleanup_large_sessions() {
    find "$SESSIONS_DIR" -name "*.jsonl" ! -name "*.old" 2>/dev/null | while read session_file; do
        local size_mb=$(du -m "$session_file" 2>/dev/null | cut -f1)
        if [ "$size_mb" -gt "$MAX_SESSION_SIZE_MB" ]; then
            echo "[WATCHDOG] Archiving large session: $session_file (${size_mb}MB)"
            mv "$session_file" "${session_file}.old"
        fi
    done
}

# Função para verificar se o gateway está travado
check_gateway_health() {
    local gateway_pid=$(pgrep -f "clawdbot-gateway" | head -1)
    if [ -n "$gateway_pid" ]; then
        # Verificar quanto tempo o processo está em state D (uninterruptible sleep) ou Z (zombie)
        local state=$(ps -p $gateway_pid -o state= 2>/dev/null | tr -d ' ')
        if [ "$state" = "D" ] || [ "$state" = "Z" ]; then
            echo "[WATCHDOG] Gateway is hung (state: $state), restarting..."
            pkill -9 -f "clawdbot-gateway"
            sleep 2
            return 1
        fi
    fi
    # Não tentar reiniciar se o gateway não existir (pode estar iniciando)
    return 0
}

while true; do
    # 1. Limpar locks órfãos a cada ciclo
    cleanup_orphan_locks

    # 2. Arquivar sessões grandes (a cada 5 ciclos = ~25s)
    if [ $((RANDOM % 5)) -eq 0 ]; then
        cleanup_large_sessions
    fi

    # 3. Verificar saúde do gateway (apenas monitorar, não reiniciar)
    check_gateway_health

    # 4. Check for restart flag
    if [ -f "$RESTART_FLAG" ]; then
        echo "[WATCHDOG] Restart flag detected, restarting Clawdbot..."
        rm -f "$RESTART_FLAG"
        pkill -TERM clawdbot
        sleep 2
        clawdbot gateway --bind lan &
    fi

    # 5. Process ops-requests
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
