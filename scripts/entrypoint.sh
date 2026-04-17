#!/bin/bash

# Nginx with Certbot - 入口脚本
# 启动 crond 和 nginx

set -e

# 将 /scripts 和 /usr/local/bin 添加到 PATH
export PATH="/usr/local/bin:/scripts:$PATH"

echo "========================================="
echo "Nginx with Certbot - Starting"
echo "========================================="

# 启动 crond（用于自动续期）
echo "Starting crond for automatic certificate renewal..."
crond -b -l 2

# 确保 default.conf 存在（挂载空目录时自动生成）
NGINX_CONF_DIR="/etc/nginx/conf.d"
if [ ! -f "$NGINX_CONF_DIR/default.conf" ]; then
    echo "Generating default.conf..."
    cat > "$NGINX_CONF_DIR/default.conf" << 'NGINX_EOF'
# 默认服务器配置 - 用于 Let's Encrypt 验证
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }

    location ~ \.php$ {
        return 444;
    }

    location / {
        return 404;
    }
}
NGINX_EOF
fi

# 检查证书文件是否存在，不存在则禁用对应配置
echo "Checking SSL certificates..."
for conf_file in "$NGINX_CONF_DIR"/*.conf; do
    [ -f "$conf_file" ] || continue
    [ "$(basename "$conf_file")" = "default.conf" ] && continue
    
    # 提取证书路径（使用 sed 替代 grep -P）
    cert_path=$(sed -n 's/^[[:space:]]*ssl_certificate[[:space:]]\+\([^;]\+\);.*/\1/p' "$conf_file" | head -1 | tr -d ' ')
    
    if [ -n "$cert_path" ] && [ ! -f "$cert_path" ]; then
        echo "WARNING: Certificate not found: $cert_path"
        echo "Disabling config: $conf_file"
        mv "$conf_file" "$conf_file.disabled"
    fi
done

# 检查 nginx 配置
echo "Testing nginx configuration..."
nginx -t

# 根据传入的命令执行不同操作
if [ "$1" = "nginx" ]; then
    echo "Starting nginx..."
    exec nginx -g "daemon off;"
elif [ "$1" = "certbot" ]; then
    # 直接执行 certbot 命令
    shift
    exec certbot "$@"
elif [ "$1" = "renew" ]; then
    # 执行续期
    echo "Running certificate renewal..."
    /scripts/renew-certs.sh
elif [ "$1" = "cert" ]; then
    # 执行证书管理
    shift
    /scripts/cert.sh "$@"
else
    # 执行自定义命令
    exec "$@"
fi
