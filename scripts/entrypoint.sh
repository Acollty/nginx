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
