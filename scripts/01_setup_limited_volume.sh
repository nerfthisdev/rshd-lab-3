#!/usr/bin/env bash
# Создаёт loop-mounted ext4 раздел ~500MB для pg-1, чтобы можно было
# реалистично заполнить PGDATA до 100% без риска забить хост-диск.
# Переключает volume pg-1 в docker-compose.yml на новый mount и запускает контейнер.
#
# Запускать ОДИН РАЗ. Требует sudo.

set -euo pipefail

cd "$(dirname "$0")/.."

IMG=./pgdata/pg1-disk.img
MNT=./pgdata/pg1-mnt
SIZE_MB=500
COMPOSE=docker-compose.yml

if [ -f "$IMG" ] && mountpoint -q "$MNT"; then
    echo "[!] Уже настроено: $IMG смонтирован в $MNT"
    df -h "$MNT"
    exit 0
fi

echo "[+] Останавливаю pg-1..."
docker compose stop pg-1 || true

echo "[+] Создаю образ диска ${SIZE_MB}MB..."
[ -f "$IMG" ] || fallocate -l ${SIZE_MB}M "$IMG"
sudo mkfs.ext4 -F -q "$IMG"

echo "[+] Готовлю точку монтирования..."
mkdir -p "$MNT"
mountpoint -q "$MNT" || sudo mount -o loop "$IMG" "$MNT"

echo "[+] Переношу содержимое PGDATA pg-1 на limited volume..."
sudo cp -a ./pgdata/pg1/. "$MNT"/
sudo chown -R 999:999 "$MNT"

echo "[+] Переключаю volume pg-1 в docker-compose.yml..."
sed -i 's|\./pgdata/pg1:/var/lib/postgresql/data|./pgdata/pg1-mnt:/var/lib/postgresql/data|' "$COMPOSE"

echo "[+] Запускаю pg-1..."
docker compose up -d pg-1
sleep 4

echo
echo "[+] Готово."
df -h "$MNT"
PGPASSWORD=secret123 psql "host=127.0.0.1 port=5432 user=postgres dbname=mydb" -c "SELECT pg_is_in_recovery(), now();" || true
