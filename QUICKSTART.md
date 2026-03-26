# 快速开始指南

## 1. 初始化并启动

```bash
make init
make up
```

## 2. 申请证书（自动生成 nginx 配置）

确保域名已解析到服务器 IP，80 端口可从外网访问，然后执行：

```bash
# 基础用法（静态文件）
docker exec nginx cert create example.com admin@example.com

# 带反向代理
docker exec nginx cert create example.com admin@example.com http://backend:8080
```

命令会自动完成：
1. 通过 certbot 申请 SSL 证书
2. 在 `nginx/conf.d/` 生成域名配置文件（HTTP 重定向 + HTTPS）
3. 重载 nginx

## 3. 验证

```bash
curl https://example.com
docker exec nginx cert info example.com
```

## 常用命令

```bash
make up             # 启动容器
make down           # 停止容器
make logs           # 查看日志
make shell          # 进入容器
make nginx-reload   # 重载 Nginx
make nginx-test     # 测试 Nginx 配置
make cert-list      # 列出证书
make cert-renew     # 续期证书
make cert-test      # 测试续期（dry-run）
make cert-logs      # 查看续期日志
```

## 故障排查

```bash
# 检查 80 端口可达性
curl http://example.com/.well-known/acme-challenge/test

# 查看 nginx 错误日志
docker exec nginx tail -50 /var/log/nginx/error.log

# 查看 certbot 日志
docker exec nginx cat /var/log/letsencrypt/letsencrypt.log

# 检查 crond（自动续期）
docker exec nginx ps | grep crond
```
