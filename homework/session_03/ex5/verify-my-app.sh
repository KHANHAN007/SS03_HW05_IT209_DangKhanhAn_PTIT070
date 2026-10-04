#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="/opt/my-app"
INDEX_FILE="$APP_ROOT/html/index.html"
LOG_DIR="$APP_ROOT/logs"
OUTPUT_FILE="$SCRIPT_DIR/verification-output.txt"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Vui lòng chạy bằng sudo: sudo ./verify-my-app.sh" >&2
    exit 1
fi

{
    echo "Thời điểm kiểm tra: $(date --iso-8601=seconds)"
    echo
    echo "=== Trạng thái phân quyền ==="
    ls -la "$APP_ROOT"
    ls -la "$APP_ROOT/html"
    ls -la "$LOG_DIR"

    echo
    echo "=== devops cập nhật website ==="
    sudo -u devops -- sh -c "echo 'Update Test' >> '$INDEX_FILE'"
    echo "devops ghi index.html: PASS"

    echo
    echo "=== Quyền của tiến trình Nginx ==="
    sudo -u www-data -- test -r "$INDEX_FILE"
    sudo -u www-data -- test -w "$LOG_DIR"
    echo "www-data đọc HTML và ghi thư mục logs: PASS"

    echo
    echo "=== HTTP và access log ==="
    curl --fail --silent --show-error --head http://localhost
    sleep 1
    tail -n 5 "$LOG_DIR/access.log"
} | tee "$OUTPUT_FILE"

echo "Đã lưu kết quả thật tại $OUTPUT_FILE"
