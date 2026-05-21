#!/usr/bin/env bash
# Восстановление этап 1: освобождаем раздел pg-1, делаем pg-1 standby для pg-2.
# Это «накатывает» все изменения, которые были выполнены на этапе 2.3.

set -euo pipefail

cd "$(dirname "$0")/.."

CONT=rshd-lab-3-pg-1-1
PG1_VOL=./pgdata/pg1-mnt   # см. 01_setup_limited_volume.sh

echo "[+] Останавливаю pg-1..."
docker compose stop pg-1 || true

echo "[+] Удаляю мусорные файлы и старый PGDATA (на limited volume)..."
sudo rm -f  "$PG1_VOL"/garbage_*.bin
sudo rm -rf "$PG1_VOL"/*

echo "[+] Делаю pg_basebackup с нового мастера (pg-2)..."
docker run --rm --network pg-net \
  -v "$PWD/$(basename $PG1_VOL):/var/lib/postgresql/data" \
  -e PGPASSWORD=replpass \
  postgres:16 \
  bash -c "
    pg_basebackup \
      -h rshd-lab-3-pg-2-1 \
      -p 5432 \
      -U replicator \
      -D /var/lib/postgresql/data \
      -Fp -Xs -P -R
  "
# -R уже создаёт standby.signal и пишет primary_conninfo в postgresql.auto.conf

echo "[+] Чиню владельца..."
sudo chown -R 999:999 "$PG1_VOL"

echo "[+] Запускаю pg-1 как standby..."
docker compose up -d pg-1

sleep 5
echo "=== Состояние ==="
PGPASSWORD=secret123 psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" -c "SELECT pg_is_in_recovery();"
PGPASSWORD=secret123 psql "host=127.0.0.1 port=5433 user=postgres dbname=mydb" \
  -c "SELECT application_name,state,sync_state,client_addr FROM pg_stat_replication;"
echo "[+] pg-1 должен показать pg_is_in_recovery=t и стримить с pg-2"
