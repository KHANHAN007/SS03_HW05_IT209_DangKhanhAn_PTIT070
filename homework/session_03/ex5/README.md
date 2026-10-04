# Bài 5 - Thư mục Web an toàn tại `/opt`

**Sinh viên:** Đặng Khánh An  
**Mã sinh viên:** PTIT070  
**Môn học:** IT209

## Cấu trúc triển khai

```text
/opt/my-app/
├── html/
│   └── index.html
└── logs/
    ├── access.log
    └── error.log
```

Nginx Server Block sử dụng:

```nginx
root /opt/my-app/html;
access_log /opt/my-app/logs/access.log;
error_log /opt/my-app/logs/error.log warn;
```

## Phân quyền

| Đối tượng | Owner:Group | Mode | Ý nghĩa |
|---|---|---:|---|
| `/opt/my-app` | `devops:www-data` | `2750` | devops toàn quyền, Nginx được đọc/traverse |
| `html/` | `devops:www-data` | `2750` | group chỉ đọc/traverse mã nguồn |
| File HTML | `devops:www-data` | `0640` | devops đọc/ghi, Nginx chỉ đọc |
| `logs/` | `devops:www-data` | `2770` | devops và Nginx đều có thể ghi log |
| File log | `devops:www-data` | `0660` | owner và group đọc/ghi |

Bit setgid (`2`) trên các thư mục giúp nội dung mới kế thừa group `www-data`. Không cấp quyền cho `other`, nhờ đó mã nguồn và log được cô lập tốt hơn so với mode `755/644`.

## Cài đặt

```bash
cd homework/session_03/ex5
chmod +x setup-my-app.sh verify-my-app.sh
sudo ./setup-my-app.sh
```

Script tạo thư mục, chép mã nguồn, tạo file log, phân quyền, cài Server Block, chạy `nginx -t` rồi mới reload Nginx.

## Kiểm tra

```bash
sudo ./verify-my-app.sh
```

Script kiểm tra:

1. Output `ls -la /opt/my-app/`, `html/` và `logs/`.
2. User `devops` ghi `Update Test` vào `index.html`.
3. User `www-data` đọc được HTML và có quyền ghi vào thư mục log.
4. HTTP trả thành công, không có lỗi 403.
5. Access log phát sinh tại `/opt/my-app/logs/access.log`.

Kết quả thật được ghi vào [verification-output.txt](verification-output.txt).

## Kết quả mong đợi

```text
drwxr-s--- devops:www-data /opt/my-app/html
drwxrws--- devops:www-data /opt/my-app/logs
-rw-r----- devops:www-data /opt/my-app/html/index.html
-rw-rw---- devops:www-data /opt/my-app/logs/access.log

devops ghi index.html: PASS
www-data đọc HTML và ghi thư mục logs: PASS
HTTP/1.1 200 OK
```

## Kiểm tra thủ công log

```bash
curl http://localhost/
tail -f /opt/my-app/logs/access.log
```

Nếu gặp HTTP 403 hoặc lỗi mở log, kiểm tra:

```bash
namei -l /opt/my-app/html/index.html
sudo -u www-data test -r /opt/my-app/html/index.html && echo READ_OK
sudo -u www-data test -w /opt/my-app/logs && echo WRITE_OK
sudo tail -n 30 /var/log/nginx/error.log
```

## Bằng chứng

Đề không yêu cầu ảnh chụp. Trước khi nộp, chạy `sudo ./verify-my-app.sh` trên Droplet để thay nội dung placeholder trong `verification-output.txt` bằng output thật.
