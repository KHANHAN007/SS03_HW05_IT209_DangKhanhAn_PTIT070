#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="/opt/my-app"
HTML_DIR="$APP_ROOT/html"
LOG_DIR="$APP_ROOT/logs"
NGINX_AVAILABLE="/etc/nginx/sites-available/my-app.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/my-app.conf"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Vui lòng chạy bằng sudo: sudo ./setup-my-app.sh" >&2
    exit 1
fi

id devops >/dev/null 2>&1 || { echo "Không tìm thấy user devops" >&2; exit 1; }
getent group www-data >/dev/null 2>&1 || { echo "Không tìm thấy group www-data" >&2; exit 1; }

install -d "$HTML_DIR" "$LOG_DIR"
install -m 0640 "$SCRIPT_DIR/index.html" "$HTML_DIR/index.html"
touch "$LOG_DIR/access.log" "$LOG_DIR/error.log"

chown -R devops:www-data "$APP_ROOT"

# Mã nguồn: devops ghi, www-data chỉ đọc và đi xuyên thư mục.
chmod 2750 "$APP_ROOT"
find "$HTML_DIR" -type d -exec chmod 2750 {} +
find "$HTML_DIR" -type f -exec chmod 0640 {} +

# Logs: devops và www-data đều được ghi; nội dung mới kế thừa group www-data.
chmod 2770 "$LOG_DIR"
find "$LOG_DIR" -type f -exec chmod 0660 {} +

install -o root -g root -m 0644 "$SCRIPT_DIR/my-app.conf" "$NGINX_AVAILABLE"
ln -sfn "$NGINX_AVAILABLE" "$NGINX_ENABLED"

nginx -t
systemctl reload nginx

find "$APP_ROOT" -maxdepth 2 -printf '%M %u:%g %p\n'
