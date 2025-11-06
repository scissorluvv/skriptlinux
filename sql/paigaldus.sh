#!/usr/bin/env bash
# mysql-paigaldus.sh — MySQL 8.4 paigaldus ja seadistus Debian 12 jaoks
# Kasutab caching_sha2_password pluginat (MySQL 8.4 standard)

set -euo pipefail
MYSQL_APT_URL="https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb"
MYSQL_APT_DEB="/tmp/mysql-apt-config_0.8.36-1_all.deb"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-Parool1!}"
LOG="/var/log/mysql-install.log"

log() { echo -e "[\e[32mINFO\e[0m] $*" | tee -a "$LOG"; }
warn(){ echo -e "[\e[33mWARN\e[0m] $*" | tee -a "$LOG"; }
err() { echo -e "[\e[31mERR \e[0m] $*" | tee -a "$LOG" >&2; }

require_root() {
  [[ $EUID -eq 0 ]] || { err "Käivita rootina (sudo)."; exit 1; }
}

preclean_conflicts() {
  if dpkg -l | grep -qE 'mariadb-server|mariadb-client'; then
    log "Eemaldan MariaDB konfliktid..."
    apt-get remove --purge -y "mariadb-*" || true
    apt-get autoremove -y
  fi
}

install_prereqs() {
  log "Paigaldan sõltuvused..."
  apt-get update -y
  apt-get install -y gnupg lsb-release curl wget ca-certificates apt-transport-https
}

add_mysql_repo() {
  if ! dpkg -l | grep -q mysql-apt-config; then
    log "Laen alla ja paigaldan MySQL repositooriumi..."
    wget -O "$MYSQL_APT_DEB" "$MYSQL_APT_URL"
    DEBIAN_FRONTEND=noninteractive dpkg -i "$MYSQL_APT_DEB" || true
    apt-get update -y
  else
    log "MySQL repo juba olemas."
  fi
}

install_mysql() {
  log "Paigaldan MySQL serveri..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
  systemctl enable mysql
  systemctl restart mysql
  systemctl --no-pager status mysql | head -n 12 || true
}

configure_root() {
  log "Seadistan root kasutaja (caching_sha2_password)..."
  set +e
  mysql -uroot -e "SELECT 1;" >/dev/null 2>&1
  STATUS=$?
  set -e

  if [[ $STATUS -ne 0 ]]; then
    log "Käivitan ajutiselt MySQL ilma grant-tabeliteta..."
    systemctl stop mysql
    nohup mysqld_safe --skip-grant-tables --skip-networking >/dev/null 2>&1 &
    sleep 5
    mysql -uroot <<SQL
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
    pkill mysqld || true
    systemctl start mysql
    log "Root kasutaja seadistatud parooliga ${MYSQL_ROOT_PASSWORD}."
  else
    log "Root on juba seadistatud — jätan muutmata."
  fi

  # Mugav .my.cnf fail
  cat > /root/.my.cnf <<CFG
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
host=localhost
CFG
  chmod 600 /root/.my.cnf
}

smoke_test() {
  log "Teen ühenduse testi..."
  mysql --version | tee -a "$LOG"
  mysql -e "SELECT VERSION() AS version, NOW() AS now\G" | tee -a "$LOG"
  mysql -e "CREATE DATABASE IF NOT EXISTS sanity_test;"
  mysql -e "SHOW DATABASES LIKE 'sanity_test';"
  log "Kõik töötab!"
}

main() {
  require_root
  preclean_conflicts
  install_prereqs
  add_mysql_repo
  install_mysql
  configure_root
  smoke_test
  log "✅ Paigaldus ja seadistus valmis!"
}

main "$@"
