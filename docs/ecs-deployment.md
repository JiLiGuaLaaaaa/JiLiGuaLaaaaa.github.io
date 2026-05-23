# ECS 动态服务部署说明

本文只记录部署步骤和占位配置。真实服务器地址、账号、密码、Token、证书私钥和数据库内容不得写入仓库。

## 目标结构

```text
GitHub Pages 静态博客
  https://blog.example.com

ECS 动态服务
  https://api.example.com
  -> 127.0.0.1:8787
```

静态博客仍由 GitHub Actions 发布到 GitHub Pages。ECS 只运行 `server/index.mjs`，负责访问量统计、公开生活记录和私密日记管理 API。

## DNS

在 DNS 服务商中为动态服务准备独立子域名：

```text
api.example.com  A  <ECS_PUBLIC_IP>
```

如果使用 Cloudflare 代理，请在服务器上配置 HTTPS 或使用 Cloudflare 的安全回源方案。真实域名和公网 IP 以控制台为准，不写入仓库。

## 服务器目录

建议在 ECS 上使用类似目录：

```text
/opt/blog-project        # 项目源码
/var/lib/blog-dynamic    # 动态数据目录
/etc/blog-dynamic.env    # 服务环境变量
```

动态数据目录必须在仓库外，避免日记、生活记录草稿、访问量数据被提交。

## 环境变量

在服务器上创建 `/etc/blog-dynamic.env`，内容参考：

```text
BLOG_DYNAMIC_HOST=127.0.0.1
BLOG_DYNAMIC_PORT=8787
BLOG_DYNAMIC_ALLOWED_ORIGINS=https://blog.example.com
BLOG_DYNAMIC_ADMIN_TOKEN=replace-with-a-long-random-token
BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic
BLOG_DYNAMIC_PUBLIC_BASE_URL=https://api.example.com
```

其中 `BLOG_DYNAMIC_ADMIN_TOKEN` 必须替换为足够长的随机值。不要把真实文件复制回仓库。

## systemd

仓库提供示例文件：

```text
server/blog-dynamic.service.example
```

部署时复制到服务器的 systemd 目录后，按服务器真实路径调整：

```text
WorkingDirectory=/opt/blog-project
EnvironmentFile=/etc/blog-dynamic.env
ExecStart=/usr/bin/node /opt/blog-project/server/index.mjs
ReadWritePaths=/var/lib/blog-dynamic
```

## 反向代理

仓库提供 nginx 示例：

```text
server/nginx.conf.example
```

部署时把 `api.example.com` 换成真实 API 子域名，并确保反向代理到：

```text
http://127.0.0.1:8787
```

HTTPS 证书可以由 Cloudflare、服务器上的 ACME 工具或其他受信任方式管理。证书私钥不能提交。

## 静态博客构建配置

GitHub Pages 构建时需要配置公开环境变量：

```text
PUBLIC_DYNAMIC_API_BASE=https://api.example.com
PUBLIC_DYNAMIC_ADMIN_URL=https://api.example.com/admin/
```

如果暂时不配置这些变量，静态博客仍可正常浏览，只是不显示访问量，生活记录页面会提示未连接动态服务，连续点击小人不会打开真实写日记入口。

## 验证

部署后可以检查：

```text
GET https://api.example.com/health
GET https://api.example.com/api/stats?path=/blog/
GET https://api.example.com/api/life?limit=6
```

管理接口必须带：

```text
Authorization: Bearer <BLOG_DYNAMIC_ADMIN_TOKEN>
```

不要在公开页面、README、提交记录或工单中粘贴真实 Token。
