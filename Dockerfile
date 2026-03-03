# Nginx with Certbot - Alpine 最新版
# 支持自动续期和手动管理 SSL 证书

FROM nginx:alpine

LABEL maintainer="demo@example.com"
LABEL description="Nginx with Certbot for automatic SSL certificate management"

# 设置时区
ENV TZ=Asia/Shanghai

# 安装必要的软件包
RUN apk add --no-cache \
    tzdata \
    certbot \
    certbot-nginx \
    bash \
    curl \
    openssl \
    dcron \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# 创建必要的目录
RUN mkdir -p /var/log/nginx \
             /var/www/html/.well-known/acme-challenge \
             /etc/letsencrypt \
             /var/log/certbot \
             /scripts

# 复制脚本文件到 /scripts
COPY scripts/renew-certs.sh /scripts/renew-certs.sh
COPY scripts/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/cert-manager.sh /scripts/cert-manager.sh

# 设置脚本执行权限
RUN chmod +x /scripts/*.sh

# 在 /usr/local/bin 创建包装脚本（不是软链接或复制）
RUN echo '#!/bin/sh' > /usr/local/bin/cert-manager && \
    echo 'exec /scripts/cert-manager.sh "$@"' >> /usr/local/bin/cert-manager && \
    chmod +x /usr/local/bin/cert-manager && \
    echo '#!/bin/sh' > /usr/local/bin/renew-certs && \
    echo 'exec /scripts/renew-certs.sh "$@"' >> /usr/local/bin/renew-certs && \
    chmod +x /usr/local/bin/renew-certs

# 将 /scripts 目录添加到 PATH，这样可以直接调用脚本
ENV PATH="/scripts:/usr/local/bin:${PATH}"

# 将 PATH 写入 /etc/profile 和 /etc/environment，确保 docker exec 也能使用
RUN echo 'export PATH="/scripts:/usr/local/bin:$PATH"' >> /etc/profile && \
    echo 'export PATH="/scripts:/usr/local/bin:$PATH"' >> /etc/profile.d/custom-path.sh && \
    echo 'PATH="/scripts:/usr/local/bin:$PATH"' >> /etc/environment

# 创建 crontab 文件用于自动续期（每天凌晨 2 点执行）
RUN echo "0 2 * * * /scripts/renew-certs.sh >> /var/log/certbot/renew.log 2>&1" > /etc/crontabs/root

# 暴露端口
EXPOSE 80 443

# 使用自定义入口脚本
ENTRYPOINT ["/scripts/entrypoint.sh"]

# 默认启动 nginx
CMD ["nginx"]
