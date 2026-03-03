#!/bin/bash

# SSL 证书自动续期脚本
# 此脚本会被 cron 定时执行

set -e

LOG_FILE="/var/log/certbot/renew.log"

echo "========================================" | tee -a "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting certificate renewal check" | tee -a "$LOG_FILE"

# 执行证书续期
certbot renew --quiet --webroot --webroot-path=/var/www/html 2>&1 | tee -a "$LOG_FILE"

RENEW_EXIT_CODE=${PIPESTATUS[0]}

if [ $RENEW_EXIT_CODE -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Certificate renewal check completed (exit code: $RENEW_EXIT_CODE)" | tee -a "$LOG_FILE"
    
    # 重载 nginx 配置（不重启，平滑更新）
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Reloading nginx configuration..." | tee -a "$LOG_FILE"
    nginx -s reload 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Nginx reloaded successfully" | tee -a "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Nginx reload failed" | tee -a "$LOG_FILE"
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Certificate renewal failed (exit code: $RENEW_EXIT_CODE)" | tee -a "$LOG_FILE"
fi

echo "========================================" | tee -a "$LOG_FILE"
