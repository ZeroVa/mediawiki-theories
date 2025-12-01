#!/usr/bin/env bash
set -euo pipefail

CONFIG_SRC="/var/www/html/LocalSettings.php"
CONFIG_DEST="/data/LocalSettings.php"

: "${PORT:=80}"

# Allow Railway's MYSQL_URL connection string to populate individual fields.
if [ -n "${MYSQL_URL:-}" ]; then
  eval "$(python - <<'PY'
import os
from urllib.parse import urlparse

url = os.environ.get("MYSQL_URL", "")
parsed = urlparse(url)

def emit(key, value):
    if value:
        print(f'export {key}="{value}"')

emit("MYSQLUSER", parsed.username or "")
emit("MYSQLPASSWORD", parsed.password or "")
emit("MYSQLHOST", parsed.hostname or "")
if parsed.port:
    emit("MYSQLPORT", parsed.port)
path = parsed.path[1:] if parsed.path.startswith("/") else parsed.path
emit("MYSQLDATABASE", path)
PY
)"
fi

: "${PORT:=80}"
: "${MW_DB_TYPE:=mysql}"
: "${MW_SITENAME:=Consciousness Wiki}"
: "${MW_ADMIN_USER:=admin}"
: "${MW_ADMIN_PASS:=adminpass}"
: "${MW_DB_NAME:=${MYSQLDATABASE:-mediawiki}}"
: "${MW_DB_USER:=${MYSQLUSER:-wikiuser}}"
: "${MW_DB_PASSWORD:=${MYSQLPASSWORD:-example}}"
: "${MW_DB_HOST:=${MYSQLHOST:-database}}"
: "${MW_DB_PORT:=${MYSQLPORT:-${MYSQL_PORT:-}}}"

if [[ "$MW_DB_HOST" == *:* ]]; then
  host_part="${MW_DB_HOST%%:*}"
  port_part="${MW_DB_HOST##*:}"
  MW_DB_HOST="$host_part"
  MW_DB_PORT="${MW_DB_PORT:-$port_part}"
fi

: "${MW_DB_PORT:=3306}"

if [ -z "${MW_SITE_SERVER:-}" ]; then
  if [ -n "${RAILWAY_STATIC_URL:-}" ]; then
    MW_SITE_SERVER="https://${RAILWAY_STATIC_URL}"
  elif [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    MW_SITE_SERVER="https://${RAILWAY_PUBLIC_DOMAIN}"
  elif [ "$PORT" = "80" ]; then
    MW_SITE_SERVER="http://localhost"
  else
    MW_SITE_SERVER="http://localhost:${PORT}"
  fi
fi

export PORT MW_DB_TYPE MW_SITENAME MW_ADMIN_USER MW_ADMIN_PASS MW_DB_NAME MW_DB_USER MW_DB_PASSWORD MW_DB_HOST MW_DB_PORT MW_SITE_SERVER
echo ">> MW_SITE_SERVER set to ${MW_SITE_SERVER}"

if [ "$PORT" != "80" ]; then
  cat > /etc/apache2/ports.conf <<EOF
Listen ${PORT}
EOF
  sed -i -E "s/:([0-9]+)>/:${PORT}>/g" /etc/apache2/sites-available/000-default.conf
fi

DB_SERVER="$MW_DB_HOST:$MW_DB_PORT"

echo ">> Ensuring database is reachable at ${MW_DB_HOST}:${MW_DB_PORT} ..."
until php -r '
    $h = getenv("MW_DB_HOST");
    $port = getenv("MW_DB_PORT");
    $u = getenv("MW_DB_USER");
    $p = getenv("MW_DB_PASSWORD");
    $d = getenv("MW_DB_NAME");
    $mysqli = @new mysqli($h, $u, $p, $d, (int)$port);
    if ($mysqli->connect_errno) { exit(1); }
  ' >/dev/null 2>&1; do
  echo "   Waiting for database ..."
  sleep 2
done

if [ ! -f "$CONFIG_DEST" ]; then
  echo ">> No LocalSettings found; running MediaWiki installer ..."
  php /var/www/html/maintenance/install.php \
    --confpath /var/www/html \
    --dbtype "$MW_DB_TYPE" \
    --dbname "$MW_DB_NAME" \
    --dbuser "$MW_DB_USER" \
    --dbpass "$MW_DB_PASSWORD" \
    --dbserver "$DB_SERVER" \
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
