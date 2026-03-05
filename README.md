# Nginx with Certbot - Alpine

集成了 Nginx 和 Certbot 的 Docker 镜像，基于 Alpine Linux，支持自动续期和手动管理 SSL 证书。

## 特性

- ✅ 基于 Nginx Alpine 最新版
- ✅ 集成 Certbot 用于 Let's Encrypt 证书管理
- ✅ 自动续期（每天凌晨 2 点）
- ✅ 支持手动创建、续期、删除证书
- ✅ 平滑重载配置（不中断连接）
- ✅ 完整的证书管理工具

## 目录结构

```
nginx/
├── Dockerfile                          # Docker 镜像构建文件
├── docker-compose.yml                  # Docker Compose 配置
├── scripts/                            # 脚本目录
│   ├── entrypoint.sh                  # 容器入口脚本
│   ├── renew-certs.sh                 # 自动续期脚本
│   └── cert.sh                        # 证书管理脚本
├── nginx/                              # Nginx 配置目录
│   ├── nginx.conf                     # Nginx 主配置
│   └── conf.d/                        # 虚拟主机配置
│       ├── default.conf               # 默认配置
│       └── example.com.conf.template  # 域名配置模板
├── data/                               # 数据目录（运行时创建）
│   ├── letsencrypt/                   # SSL 证书存储
│   ├── html/                          # Webroot 目录
│   └── logs/                          # 日志目录
└── README.md                           # 本文件
```

## 快速开始

### 1. 构建镜像

```bash
cd nginx
docker build -t nginx:latest .
```

### 2. 启动容器

```bash
# 使用 docker-compose
docker-compose up -d

# 或使用 docker run
docker run -d \
  --name nginx \
  -p 80:80 \
  -p 443:443 \
  -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v $(pwd)/nginx/conf.d:/etc/nginx/conf.d:ro \
  -v $(pwd)/data/letsencrypt:/etc/letsencrypt \
  -v $(pwd)/data/html:/var/www/html \
  -v $(pwd)/data/logs/nginx:/var/log/nginx \
  -v $(pwd)/data/logs/certbot:/var/log/certbot \
  nginx:latest
```

### 3. 配置域名

复制模板并修改为你的域名：

```bash
cp nginx/conf.d/example.com.conf.template nginx/conf.d/yourdomain.com.conf
# 编辑 yourdomain.com.conf，修改域名和后端配置
```

重载 nginx 配置：

```bash
docker exec nginx nginx -s reload
```

### 4. 申请 SSL 证书

```bash
# 方法1: 使用证书管理工具
docker exec nginx cert create yourdomain.com admin@yourdomain.com

# 方法2: 直接使用 certbot
docker exec nginx certbot certonly \
  --webroot \
  --webroot-path=/var/www/html \
  --email admin@yourdomain.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com
```

### 5. 启用 HTTPS

编辑 `nginx/conf.d/yourdomain.com.conf`，取消 HTTPS 服务器配置的注释，然后重载：

```bash
docker exec nginx nginx -s reload
```

## 证书管理

### 使用证书管理工具

```bash
# 查看帮助
docker exec nginx cert help

# 创建新证书
docker exec nginx cert create example.com admin@example.com

# 续期所有证书
docker exec nginx cert renew

# 强制续期所有证书
docker exec nginx cert renew-force

# 列出所有证书
docker exec nginx cert list

# 查看证书信息
docker exec nginx cert info example.com

# 删除证书
docker exec nginx cert delete example.com

# 测试续期（dry-run）
docker exec nginx cert test
```

### 直接使用 Certbot

```bash
# 申请新证书
docker exec nginx certbot certonly \
  --webroot \
  --webroot-path=/var/www/html \
  --email your@email.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com

# 续期所有证书
docker exec nginx certbot renew

# 列出所有证书
docker exec nginx certbot certificates

# 删除证书
docker exec nginx certbot delete --cert-name yourdomain.com
```

## 自动续期

镜像内置了自动续期功能，每天凌晨 2 点自动检查并续期即将到期的证书（30天内）。

### 查看续期日志

```bash
# 实时查看日志
docker exec nginx tail -f /var/log/certbot/renew.log

# 查看最近的日志
docker exec nginx tail -50 /var/log/certbot/renew.log
```

### 手动触发续期

```bash
# 使用续期脚本
docker exec nginx /scripts/renew-certs.sh

# 或使用证书管理工具
docker exec nginx cert renew
```

### 修改续期时间

编辑 Dockerfile 中的 crontab 配置：

```dockerfile
# 每天凌晨 2 点
RUN echo "0 2 * * * /scripts/renew-certs.sh >> /var/log/certbot/renew.log 2>&1" > /etc/crontabs/root

# 改为每周一凌晨 2 点
RUN echo "0 2 * * 1 /scripts/renew-certs.sh >> /var/log/certbot/renew.log 2>&1" > /etc/crontabs/root

# 改为每 12 小时
RUN echo "0 */12 * * * /scripts/renew-certs.sh >> /var/log/certbot/renew.log 2>&1" > /etc/crontabs/root
```

## Nginx 管理

### 重载配置

```bash
# 平滑重载（推荐，不中断连接）
docker exec nginx nginx -s reload

# 测试配置
docker exec nginx nginx -t
```

### 查看日志

```bash
# Nginx 访问日志
docker exec nginx tail -f /var/log/nginx/access.log

# Nginx 错误日志
docker exec nginx tail -f /var/log/nginx/error.log

# Certbot 续期日志
docker exec nginx tail -f /var/log/certbot/renew.log
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| TZ | 时区 | Asia/Shanghai |

## 端口

| 端口 | 说明 |
|------|------|
| 80 | HTTP |
| 443 | HTTPS |

## 卷挂载

| 容器路径 | 说明 | 推荐挂载 |
|----------|------|----------|
| /etc/nginx/nginx.conf | Nginx 主配置 | 只读 |
| /etc/nginx/conf.d | 虚拟主机配置 | 只读 |
| /etc/letsencrypt | SSL 证书存储 | 读写（持久化） |
| /var/www/html | Webroot 目录 | 读写 |
| /var/log/nginx | Nginx 日志 | 读写 |
| /var/log/certbot | Certbot 日志 | 读写 |

## 故障排查

### 证书申请失败

1. 检查域名 DNS 解析是否正确
2. 确保 80 端口可以从外网访问
3. 查看 certbot 日志：`docker exec nginx cat /var/log/letsencrypt/letsencrypt.log`

### Nginx 启动失败

1. 检查配置文件语法：`docker exec nginx nginx -t`
2. 查看错误日志：`docker logs nginx`

### 自动续期不工作

1. 检查 crond 是否运行：`docker exec nginx ps | grep crond`
2. 查看 crontab 配置：`docker exec nginx crontab -l`
3. 查看续期日志：`docker exec nginx cat /var/log/certbot/renew.log`

## 最佳实践

1. **定期备份证书**：备份 `data/letsencrypt` 目录
2. **监控证书到期时间**：使用 `cert info` 查看
3. **测试续期**：定期运行 `cert test` 确保续期功能正常
4. **使用只读挂载**：配置文件使用只读挂载（`:ro`）提高安全性
5. **日志轮转**：定期清理或轮转日志文件

## 安全建议

1. 使用强密码和密钥
2. 定期更新镜像
3. 限制容器权限（避免使用 `privileged`）
4. 配置防火墙规则
5. 启用 HTTPS 强制跳转

## 许可证

MIT License

## 支持

如有问题，请提交 Issue 或 Pull Request。
