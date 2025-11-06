#!/usr/bin/env bash
# mysql-eemaldus.sh — eemaldab MySQL 8.4 täielikult ja puhastab süsteemi

set -euo pipefail
log(){ echo -e "[INFO] $*"; }

[[ $EUID -eq 0 ]] || { echo "Käivita rootina (sudo)."; exit 1; }

log "Peatan MySQL..."
systemctl stop mysql || true

log "Eemaldan MySQL ja konfiguratsioonid..."
apt-get remove --purge -y mysql-server mysql-client mysql-common mysql-apt-config || true
apt-get autoremove -y || true
apt-get autoclean || true

log "Kustutan jäänused..."
rm -rf /var/lib/mysql /etc/mysql /root/.my.cnf /var/log/mysql* || true

log "Uuendan pakettide nimekirja..."
apt-get update -y || true

log "✅ MySQL eemaldatud ja süsteem puhastatud."
