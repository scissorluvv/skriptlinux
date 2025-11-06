#!/bin/bash
# See skript paigaldab MySQL serveri

set -e

# Kontroll, kas skript käivitatakse root kasutajana
if [ "$(id -u)" -ne 0 ]; then
    echo "Palun käivita see skript sudo või root kasutajana."
    exit 1
fi

apt update -y && apt upgrade -y

# Laadi alla MySQL repo pakett, kui puudub
mkdir -p /root/downloads/
if [ -e "/root/downloads/mysql-apt-config_0.8.36-1_all.deb" ]; then
    echo "MySQL .deb fail on juba olemas — jätan vahele."
else
    echo "MySQL .deb fail puudub, laen alla..."
    wget -O /root/downloads/mysql-apt-config_0.8.36-1_all.deb https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb
fi

service="mysql-server"

echo "Kontrollin, kas $service on paigaldatud..."

if dpkg -l | grep -q "^ii  mysql-server"; then
    echo "MySQL server on juba paigaldatud."
    systemctl status mysql --no-pager
else
    echo "MySQL pole paigaldatud. Paigaldan..."
    dpkg -i /root/downloads/mysql-apt-config_0.8.36-1_all.deb || apt install -f -y
    apt update -y
    apt install -y gnupg mysql-server

    systemctl enable mysql
    systemctl start mysql

    # Loo /root/.my.cnf
    cat <<EOF > /root/.my.cnf
[client]
host = localhost
user = root
password = qwerty
EOF
    chmod 600 /root/.my.cnf

    echo "MySQL server paigaldatud ja käivitatud."
fi
