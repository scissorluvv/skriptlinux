#!/usr/bin/env bash
# mysql-tervis.sh — kontrollib MySQL teenust ja ühendust

set -euo pipefail

echo "== Teenuse staatus =="
systemctl --no-pager status mysql | head -n 10 || true
echo

echo "== MySQL versioon =="
mysql --version || { echo "mysql pole paigaldatud"; exit 1; }
echo

echo "== Ühenduse test =="
if ! mysql -e "SELECT VERSION() AS version, NOW() AS now\G" >/dev/null 2>&1; then
  echo "[X] Ei saa ühendust — kontrollin UNIX-sokliga..."
  sudo mysql -e "SELECT VERSION(), NOW();" || echo "Ka sudo mysql ei õnnestunud."
else
  mysql -e "SELECT VERSION() AS version, NOW() AS now\G"
fi
echo

echo "== Kasutajate ülevaade =="
mysql -e "SELECT user, host, plugin FROM mysql.user;" 2>/dev/null || true
echo

echo "== Tervisekontroll tehtud. ✅ =="
