#!/usr/bin/env bash
# Восстановление этап 2: возврат к исходной конфигурации — pg-1 снова master,
# pg-2 снова standby. Делается «контролируемый» switchover:
#  1. CHECKPOINT на pg-2 (мастере) и его остановка.
#  2. promote pg-1.
#  3. Пересоздание pg-2 как standby pg-1 через pg_basebackup.

set -euo pipefail

cd "$(dirname "$0")/.."
export PGPASSWORD=secret123

echo "[+] CHECKPOINT на текущем мастере pg-2..."
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" -c "CHECKPOINT;"

echo "[+] Жду пока pg-1 догонит LSN..."
MASTER_LSN=$(psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" -tAc "SELECT pg_current_wal_lsn();")
echo "    master LSN = $MASTER_LSN"
for _ in $(seq 1 30); do
    REPLAY=$(psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" -tAc "SELECT pg_last_wal_replay_lsn();")
    echo "    pg-1 replay = $REPLAY"
    if [ "$REPLAY" = "$MASTER_LSN" ]; then break; fi
    sleep 1
done

echo "[+] Останавливаю pg-2..."
docker compose stop pg-2

echo "[+] Промоут pg-1..."
psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" -c "SELECT pg_promote(wait => true, wait_seconds => 30);"
psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" -c "SELECT pg_is_in_recovery();"

echo "[+] Пересобираю pg-2 как standby pg-1..."
sudo rm -rf ./pgdata/pg2/*
docker run --rm --network pg-net \
  -v "$PWD/pgdata/pg2:/var/lib/postgresql/data" \
  -e PGPASSWORD=replpass \
  postgres:16 \
  bash -c "
    pg_basebackup \
      -h rshd-lab-3-pg-1-1 \
      -p 5432 \
      -U replicator \
      -D /var/lib/postgresql/data \
      -Fp -Xs -P -R
  "
sudo chown -R 999:999 ./pgdata/pg2

echo "[+] Запускаю pg-2..."
docker compose up -d pg-2

sleep 5
echo
echo "=== Финальное состояние ==="
psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" -c "SELECT 'pg-1', pg_is_in_recovery();"
psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" -c "SELECT 'pg-2', pg_is_in_recovery();"
psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" \
  -c "SELECT application_name,state,sync_state FROM pg_stat_replication;"
psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" \
  -c "SELECT (SELECT count(*) FROM users) u, (SELECT count(*) FROM orders) o;"
