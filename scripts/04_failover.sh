#!/usr/bin/env bash
# Показывает релевантные сообщения из логов pg-1 (ENOSPC) и
# выполняет failover: промоутит pg-2 до основного узла.

set -euo pipefail
PGPASSWORD=secret123
export PGPASSWORD

echo "=== Последние строки лога pg-1 (ищем ENOSPC / could not write) ==="
docker logs --tail 80 rshd-lab-3-pg-1-1 2>&1 | grep -iE "no space|could not write|panic|fatal|wal|checkpoint" | tail -30 || true

echo
echo "=== Состояние pg-2 ДО промоута ==="
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" -c "SELECT pg_is_in_recovery();"

echo
echo "=== Промоут pg-2 ==="
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" -c "SELECT pg_promote(wait => true, wait_seconds => 30);"

echo
echo "=== Состояние pg-2 ПОСЛЕ промоута ==="
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" -c "SELECT pg_is_in_recovery();"
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" -c "\dt"
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" \
     -c "SELECT 'before-failover', (SELECT count(*) FROM users) u, (SELECT count(*) FROM orders) o;"

echo
echo "=== Пишем на новый master (pg-2:5433) ==="
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" <<'SQL'
BEGIN;
INSERT INTO users(name,email,address,password)
VALUES ('after-failover','after@e.com','addr-after',md5('after')::text);
COMMIT;
SQL
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" \
     -c "SELECT count(*) AS users_after_failover FROM users;"
