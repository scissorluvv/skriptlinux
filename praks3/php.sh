#! /bin/bash
# Paigaldab PHP teenuse koos Apache toe ja abipakettidega ning loob PHP testilehe.

# Kontroll, kas skript käivitatakse root kasutajana
if [ "$(id -u)" -ne 0 ]; then
	echo "Palun käivita see skript root kasutajana (kasuta sudo)."
	exit 1
fi

teenus="php"
paketid="php libapache2-mod-php php-mysql php-cli php-curl php-gd php-xml php-mbstring"

echo "Kontrollin, kas $teenus on paigaldatud..."

# Kontrollime, kas PHP on juba olemas
if command -v php >/dev/null 2>&1; then
  echo "$teenus pakett on juba paigaldatud."
else
  echo "$teenus ei ole paigaldatud."
  echo "Paigaldan teenuse ja vajalikud abipaketid"
  apt update -y
  apt install -y $paketid

  if [ $? -eq 0 ]; then
    echo "$teenus ja seotud paketid on edukalt paigaldatud!"
  else
    echo "Paigaldamine ebaõnnestus."
    exit 1
  fi
fi

# --- Konfiguratsiooniosa (Apache tugi PHP jaoks) ---
if systemctl list-unit-files | grep -q apache2.service; then
  echo ""
  echo "Tuvastasin, et Apache on paigaldatud – seadistan PHP toe..."

  PHP_CONF="/etc/apache2/mods-enabled/dir.conf"

  # Lisame index.php prioriteediks
  if grep -q "index.php" "$PHP_CONF"; then
    echo "Fail $PHP_CONF on juba seadistatud PHP failide teenindamiseks."
  else
    echo "Lisame index.php prioriteedina $PHP_CONF faili..."
    sed -i 's/index.html/index.php index.html/' "$PHP_CONF"
  fi

  # Eemaldame Apache vaikelehe, kui see on olemas
  if [ -f /var/www/html/index.html ]; then
    echo "Eemaldan Apache vaikelehe (index.html)..."
    rm /var/www/html/index.html
  fi

  # Loome PHP testilehe
  echo "Loon PHP testilehe (info.php)..."
  echo "<?php phpinfo(); ?>" > /var/www/html/info.php
  chown www-data:www-data /var/www/html/info.php
  chmod 644 /var/www/html/info.php

  # Taaskäivitame Apache teenuse
  echo "Taaskäivitan Apache teenuse..."
  systemctl restart apache2

  echo ""
  echo "PHP testileht on loodud: /var/www/html/info.php"
  echo "Ava veebibrauseris: http://localhost/info.php"
  echo ""
else
  echo "Apache teenust ei leitud – PHP töötab ainult käsurealt (CLI režiimis)."
fi

# --- Tulemus ---
echo ""
echo "Paigaldatud PHP versioon:"
php -v

if systemctl list-unit-files | grep -q apache2.service; then
  echo ""
  echo "Apache teenuse staatus:"
  systemctl status apache2 --no-pager
fi
