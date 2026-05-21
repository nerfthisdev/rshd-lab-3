#!/usr/bin/env bash
# Поднимает несколько клиентских сессий к pg-1 и pg-2 в фоновом режиме.
# Каждая сессия пишет в stdout логи в scripts/sessions/*.log.
#
# Сессия 1 (W): циклически INSERT в orders на pg-1.
# Сессия 2 (W): циклически INSERT в users на pg-1 внутри транзакции.
# Сессия 3 (R): циклический SELECT count(*) с pg-1.
# Сессия 4 (R): циклический SELECT count(*) с pg-2 (hot standby).

set -euo pipefail

cd "$(dirname "$0")"
mkdir -p sessions
PGPASSWORD=secret123

stop_existing() {
    if [ -f sessions/pids ]; then
        while read -r pid; do
            kill "$pid" 2>/dev/null && echo "killed $pid" || true
        done < sessions/pids
        rm -f sessions/pids
    else
        echo "сессий не запущено"
    fi
}

if [ "${1:-}" = "--stop" ] || [ "${1:-}" = "stop" ]; then
    stop_existing
    exit 0
fi

stop_existing
> sessions/pids

# Сессия 1: писатель orders на pg-1
(
    while true; do
        psql "host=127.0.0.1 port=5432 user=postgres password=$PGPASSWORD dbname=mydb" \
             -c "INSERT INTO orders(user_id, sku, price) SELECT user_id, (random()*1e9)::bigint, random()*100 FROM users ORDER BY random() LIMIT 1;" 2>&1
        sleep 1
    done
) > sessions/01-pg1-writer-orders.log 2>&1 &
echo $! >> sessions/pids

# Сессия 2: писатель users в транзакции на pg-1
(
    while true; do
        psql "host=127.0.0.1 port=5432 user=postgres password=$PGPASSWORD dbname=mydb" <<'SQL' 2>&1
BEGIN;
INSERT INTO users(name,email,address,password)
VALUES ('client-'||md5(random()::text),
        md5(random()::text)||'@e.com',
        'addr-'||md5(random()::text),
        md5(random()::text));
COMMIT;
SQL
        sleep 2
    done
) > sessions/02-pg1-writer-users.log 2>&1 &
echo $! >> sessions/pids

# Сессия 3: читатель на pg-1
(
    while true; do
        psql "host=127.0.0.1 port=5432 user=postgres password=$PGPASSWORD dbname=mydb" \
             -c "SELECT now(),'pg-1', (SELECT count(*) FROM users) AS users, (SELECT count(*) FROM orders) AS orders;" 2>&1
        sleep 3
    done
) > sessions/03-pg1-reader.log 2>&1 &
echo $! >> sessions/pids

# Сессия 4: читатель на pg-2 (hot standby)
(
    while true; do
        psql "host=127.0.0.1 port=5433 user=postgres password=$PGPASSWORD dbname=mydb" \
             -c "SELECT now(),'pg-2', (SELECT count(*) FROM users) AS users, (SELECT count(*) FROM orders) AS orders, pg_is_in_recovery();" 2>&1
        sleep 3
    done
) > sessions/04-pg2-reader.log 2>&1 &
echo $! >> sessions/pids

echo "[+] Запущено 4 сессии. PIDs:"
cat sessions/pids
echo
echo "Логи: $(pwd)/sessions/"
echo "Остановить: $(basename "$0") --stop"
