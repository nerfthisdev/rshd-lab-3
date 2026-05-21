#!/usr/bin/env bash
# Эмулирует переполнение раздела с PGDATA pg-1 "мусорными" файлами.
# Создаёт файлы внутри контейнера, в /var/lib/postgresql/data.
# После выполнения постгрес перестанет писать (ENOSPC).

set -euo pipefail

CONT=rshd-lab-3-pg-1-1

echo "[+] До:"
docker exec "$CONT" df -h /var/lib/postgresql/data

echo "[+] Заполняю раздел PGDATA pg-1..."
# Идём по 50MB пока ФС не скажет "no space left on device".
docker exec "$CONT" bash -c '
  i=0
  while dd if=/dev/zero of=/var/lib/postgresql/data/garbage_$i.bin bs=1M count=50 2>/dev/null; do
    i=$((i+1))
  done
  # дозабиваем хвост маленькими блоками
  dd if=/dev/zero of=/var/lib/postgresql/data/garbage_tail.bin bs=4k 2>/dev/null || true
'

echo "[+] После:"
docker exec "$CONT" df -h /var/lib/postgresql/data
docker exec "$CONT" ls -lh /var/lib/postgresql/data/garbage_* 2>/dev/null | tail -5 || true
