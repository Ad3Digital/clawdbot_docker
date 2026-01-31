#!/bin/bash
set -e

echo "[ENTRYPOINT] Starting CLIProxyAPI in background..."

# Start CLIProxyAPI in background
if [ -f /app/cli-proxy-api ]; then
    /app/cli-proxy-api --config /app/config.yaml > /tmp/cliproxy.log 2>&1 &
    CLIPROXY_PID=$!
    echo "[ENTRYPOINT] CLIProxyAPI started (PID: $CLIPROXY_PID)"

    # Wait for CLIProxyAPI to be ready
    echo "[ENTRYPOINT] Waiting for CLIProxyAPI to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8317/v1/models > /dev/null 2>&1; then
            echo "[ENTRYPOINT] CLIProxyAPI is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "[ENTRYPOINT] WARNING: CLIProxyAPI not responding after 30s"
            echo "[ENTRYPOINT] CLIProxyAPI logs:"
            cat /tmp/cliproxy.log
        fi
        sleep 1
    done
else
    echo "[ENTRYPOINT] WARNING: cli-proxy-api binary not found!"
fi

echo "[ENTRYPOINT] Starting internal watchdog..."
if [ -f /app/watchdog.sh ]; then
    /app/watchdog.sh > /tmp/watchdog.log 2>&1 &
    WATCHDOG_PID=$!
    echo "[ENTRYPOINT] Watchdog started (PID: $WATCHDOG_PID)"
else
    echo "[ENTRYPOINT] WARNING: watchdog.sh not found!"
fi

echo "[ENTRYPOINT] Starting Clawdbot..."
exec "$@"
