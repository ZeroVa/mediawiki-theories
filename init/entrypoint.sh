#!/usr/bin/env bash
set -euo pipefail

CONFIG_SRC="/var/www/html/LocalSettings.php"
CONFIG_DEST="/data/LocalSettings.php"

: "${MW_SITENAME:=Consciousness Wiki}"
: "${MW_ADMIN_USER:=admin}"
: "${MW_ADMIN_PASS:=adminpass}"
: "${MW_DB_NAME:=mediawiki}"
: "${MW_DB_USER:=wikiuser}"
: "${MW_DB_PASSWORD:=example}"
: "${MW_DB_HOST:=database}"
: "${MW_SITE_SERVER:=http://localhost:8080}"

echo ">> Ensuring database is reachable at ${MW_DB_HOST} ..."
until php -r '
    $h = getenv("MW_DB_HOST");
    $u = getenv("MW_DB_USER");
    $p = getenv("MW_DB_PASSWORD");
    $d = getenv("MW_DB_NAME");
    $mysqli = @new mysqli($h, $u, $p, $d);
    if ($mysqli->connect_errno) { exit(1); }
  ' >/dev/null 2>&1; do
  echo "   Waiting for database ..."
  sleep 2
done

if [ ! -f "$CONFIG_DEST" ]; then
  echo ">> No LocalSettings found; running MediaWiki installer ..."
  php /var/www/html/maintenance/install.php \
    --confpath /var/www/html \
    --dbname "$MW_DB_NAME" \
    --dbuser "$MW_DB_USER" \
    --dbpass "$MW_DB_PASSWORD" \
    --dbserver "$MW_DB_HOST" \
    --server "$MW_SITE_SERVER" \
    --scriptpath "" \
    --lang en \
    --pass "$MW_ADMIN_PASS" \
    "$MW_SITENAME" \
    "$MW_ADMIN_USER"

  if ! grep -q "consciousness-theme.php" "$CONFIG_SRC"; then
    echo 'require_once "$IP/localsettings.d/consciousness-theme.php";' >> "$CONFIG_SRC"
  fi

  mkdir -p /data
  cp "$CONFIG_SRC" "$CONFIG_DEST"
fi

ln -sf "$CONFIG_DEST" "$CONFIG_SRC"

echo ">> LocalSettings ready; starting Apache ..."
exec "$@"
