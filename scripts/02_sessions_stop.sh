#!/usr/bin/env bash
# Останавливает фоновые сессии, запущенные 02_sessions.sh
cd "$(dirname "$0")"
if [ -f sessions/pids ]; then
    while read -r pid; do
        kill "$pid" 2>/dev/null && echo "killed $pid" || true
    done < sessions/pids
    rm -f sessions/pids
else
    echo "сессий не запущено"
fi
