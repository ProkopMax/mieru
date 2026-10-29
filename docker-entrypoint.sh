#!/bin/sh
# Запускает mita или mieru в foreground, в фоне применяет JSON-конфиг
# через RPC (mita/mieru apply config). RPC становится доступен
# через 1-2 секунды после старта daemon — отсюда retry-цикл.

set -eu

MODE="${MIERU_MODE:-mita}"
CONFIG_FILE="${MIERU_CONFIG:-/srv/config.json}"

case "$MODE" in
    mita)  BIN=mita ;;
    mieru) BIN=mieru ;;
    *) echo "[entrypoint] FATAL: MIERU_MODE='$MODE' (ожидается mita или mieru)"; exit 1 ;;
esac

apply_config_and_start() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[entrypoint] WARN: $CONFIG_FILE не найден, конфиг не применяется"
        return 0
    fi
    i=0
    while [ "$i" -lt 30 ]; do
        i=$((i+1))
        sleep 1
        if "$BIN" apply config "$CONFIG_FILE" >/tmp/apply.out 2>&1; then
            echo "[entrypoint] config применён ($CONFIG_FILE)"
            # после apply config daemon в IDLE — нужен start, чтобы открыть сокеты
            if "$BIN" start >/tmp/start.out 2>&1; then
                echo "[entrypoint] $BIN start: OK"
            else
                echo "[entrypoint] WARN: $BIN start failed:"
                cat /tmp/start.out 2>/dev/null || true
            fi
            return 0
        fi
    done
    echo "[entrypoint] WARN: не удалось применить config за 30s, последний вывод:"
    cat /tmp/apply.out 2>/dev/null || true
}

apply_config_and_start &

echo "[entrypoint] запуск $BIN run"
exec "$BIN" run
