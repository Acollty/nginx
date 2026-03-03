# 快速开始指南

## 1. 构建镜像

```bash
cd wk-nginx
docker build -t nginx:latest .
```

## 2. 初始化数据目录

```bash
mkdir -p data/letsencrypt data/html data/logs/nginx data/logs/certbot
chmod -R 755 data/
```

或使用 Makefile：

```bash
make init
```

## 3. 配置域名

### 3.1 复制配置模板

```bash
cp nginx/conf.d/example.com.conf.template nginx/conf.d/yourdomain.com.conf
```

### 3.2 编辑配置文件

编辑 `nginx/conf.d/yourdomain.com.conf`，修改：
- `server_name example.com;` → `server_name yourdomain.com;`
- 根据需要配置后端代理或静态文件

## 4. 启动容器

```bash
docker-compose up -d
```

或使用 Makefile：

```bash
make up
```

## 5. 验证 Nginx 运行

```bash
# 测试配置
docker exec nginx nginx -t

# 查看日志
docker logs nginx

# 访问测试
curl http://localhost/
```

## 6. 申请 SSL 证书

### 前提条件
- 域名已解析到服务器 IP
- 80 端口可以从外网访问
- Nginx 已正常运行

### 申请证书

```bash
# 使用证书管理工具（推荐）
docker exec nginx cert-manager create yourdomain.com admin@yourdomain.com

# 或直接使用 certbot
docker exec nginx certbot certonly \
  --webroot \
  --webroot-path=/var/www/html \
  --email admin@yourdomain.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com
```

## 7. 启用 HTTPS

### 7.1 编辑配置文件

编辑 `nginx/conf.d/yourdomain.com.conf`：

1. 启用 HTTP 到 HTTPS 重定向（取消注释）：
```nginx
location / {
    return 301 https://$host$request_uri;
}
```

2. 启用 HTTPS 服务器配置（取消整个 server 块的注释）

### 7.2 重载 Nginx

```bash
docker exec nginx nginx -s reload
```

或使用 Makefile：

```bash
make nginx-reload
```

## 8. 验证 HTTPS

```bash
# 测试 HTTPS 访问
curl https://yourdomain.com -k

# 查看证书信息
docker exec nginx cert-manager info yourdomain.com
```

## 9. 监控自动续期

### 查看续期日志

```bash
docker exec nginx tail -f /var/log/certbot/renew.log
```

或使用 Makefile：

```bash
make cert-logs
```

### 手动测试续期

```bash
docker exec nginx cert-manager test
```

## 常用命令

```bash
# 使用 Makefile
make build          # 构建镜像
make up             # 启动容器
make down           # 停止容器
make restart        # 重启容器
make logs           # 查看日志
make shell          # 进入容器
make nginx-reload   # 重载 Nginx
make nginx-test     # 测试 Nginx 配置
make cert-list      # 列出证书
make cert-renew     # 续期证书
make cert-test      # 测试续期
make cert-logs      # 查看续期日志

# 直接使用 Docker
docker exec nginx cert-manager help     # 证书管理帮助
docker exec nginx nginx -s reload       # 重载 Nginx
docker exec nginx nginx -t              # 测试配置
docker logs nginx                       # 查看日志
```

## 完整示例

假设你的域名是 `example.com`：

```bash
# 1. 构建和启动
cd wk-nginx
make init
make build
make up

# 2. 配置域名
cp nginx/conf.d/example.com.conf.template nginx/conf.d/example.com.conf
# 编辑 example.com.conf，修改域名

# 3. 重载配置
make nginx-reload

# 4. 申请证书
docker exec nginx cert-manager create example.com admin@example.com

# 5. 启用 HTTPS
# 编辑 nginx/conf.d/example.com.conf，启用 HTTPS 配置
make nginx-reload

# 6. 验证
curl https://example.com
docker exec nginx cert-manager info example.com

# 7. 查看自动续期日志
make cert-logs
```

## 故障排查

### 证书申请失败

```bash
# 检查 DNS 解析
nslookup yourdomain.com

# 检查 80 端口
curl http://yourdomain.com/.well-known/acme-challenge/test

# 查看 certbot 日志
docker exec nginx cat /var/log/letsencrypt/letsencrypt.log
```

### Nginx 配置错误

```bash
# 测试配置
make nginx-test

# 查看错误日志
docker exec nginx tail -50 /var/log/nginx/error.log
```

### 自动续期不工作

```bash
# 检查 crond
docker exec nginx ps | grep crond

# 查看 crontab
docker exec nginx crontab -l

# 手动触发续期
docker exec nginx /scripts/renew-certs.sh
```

## 下一步

- 阅读 [README.md](README.md) 了解详细功能
- 配置多个域名
- 设置日志轮转
- 配置监控告警
