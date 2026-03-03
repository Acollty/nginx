#!/bin/bash

# SSL 证书管理脚本
# 提供便捷的证书管理命令

set -e

# 显示帮助信息
show_help() {
    cat << EOF
SSL Certificate Manager - Usage:

Commands:
  create <domain> <email>     - Create a new certificate for a domain
  renew                       - Renew all certificates
  renew-force                 - Force renew all certificates
  list                        - List all certificates
  delete <domain>             - Delete a certificate
  info <domain>               - Show certificate information
  test                        - Test certificate renewal (dry-run)

Examples:
  cert-manager create example.com admin@example.com
  cert-manager renew
  cert-manager list
  cert-manager info example.com

EOF
}

# 创建新证书
create_cert() {
    local domain=$1
    local email=$2
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        echo "Error: Domain and email are required"
        echo "Usage: cert-manager create <domain> <email>"
        exit 1
    fi
    
    echo "Creating certificate for $domain..."
    certbot certonly \
        --webroot \
        --webroot-path=/var/www/html \
        --email "$email" \
        --agree-tos \
        --no-eff-email \
        -d "$domain"
    
    if [ $? -eq 0 ]; then
        echo "Certificate created successfully for $domain"
        echo "Reloading nginx..."
        nginx -s reload
    else
        echo "Failed to create certificate for $domain"
        exit 1
    fi
}

# 续期所有证书
renew_certs() {
    echo "Renewing all certificates..."
    certbot renew --webroot --webroot-path=/var/www/html
    
    if [ $? -eq 0 ]; then
        echo "Certificate renewal completed"
        echo "Reloading nginx..."
        nginx -s reload
    else
        echo "Certificate renewal failed"
        exit 1
    fi
}

# 强制续期所有证书
force_renew_certs() {
    echo "Force renewing all certificates..."
    certbot renew --force-renewal --webroot --webroot-path=/var/www/html
    
    if [ $? -eq 0 ]; then
        echo "Certificate force renewal completed"
        echo "Reloading nginx..."
        nginx -s reload
    else
        echo "Certificate force renewal failed"
        exit 1
    fi
}

# 列出所有证书
list_certs() {
    echo "Listing all certificates..."
    certbot certificates
}

# 删除证书
delete_cert() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        echo "Error: Domain is required"
        echo "Usage: cert-manager delete <domain>"
        exit 1
    fi
    
    echo "Deleting certificate for $domain..."
    certbot delete --cert-name "$domain"
}

# 显示证书信息
show_cert_info() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        echo "Error: Domain is required"
        echo "Usage: cert-manager info <domain>"
        exit 1
    fi
    
    echo "Certificate information for $domain:"
    certbot certificates --cert-name "$domain"
    
    # 显示证书文件详情
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        echo ""
        echo "Certificate details:"
        openssl x509 -in "/etc/letsencrypt/live/$domain/fullchain.pem" -text -noout | grep -A 2 "Validity"
    fi
}

# 测试续期（dry-run）
test_renew() {
    echo "Testing certificate renewal (dry-run)..."
    certbot renew --dry-run --webroot --webroot-path=/var/www/html
}

# 主逻辑
case "$1" in
    create)
        create_cert "$2" "$3"
        ;;
    renew)
        renew_certs
        ;;
    renew-force)
        force_renew_certs
        ;;
    list)
        list_certs
        ;;
    delete)
        delete_cert "$2"
        ;;
    info)
        show_cert_info "$2"
        ;;
    test)
        test_renew
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
