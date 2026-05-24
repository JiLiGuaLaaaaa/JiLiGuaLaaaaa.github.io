# 博客动态服务

这个目录是部署到独立动态服务服务器的 Node.js 服务，不属于 GitHub Pages 静态构建产物。服务器可以是带公网 IP 的私人 Linux 小电脑，也可以是 ECS、VPS 或其他云服务器。

## 本地运行

```bash
node server/index.mjs
sudo bash server/bootstrap-docker.sh
```

`node server/index.mjs` 用于本地测试。`sudo bash server/bootstrap-docker.sh` 是目标 Linux 服务器上的推荐部署方式，会创建 Docker 容器、nginx、环境文件和数据目录。`sudo bash server/bootstrap-linux.sh` 保留为非 Docker 备用部署方式。

当前私人服务器只有旧版 `docker-compose`，没有 Docker Compose v2 的 `docker compose` 插件。更新动态服务时优先运行 `sudo bash /opt/blog-project/server/bootstrap-docker.sh`；脚本会优先使用可用的 Compose，并在旧版重建容器触发兼容错误时改用 `docker run` 只重建 `blog-dynamic` 容器。不要删除 `/var/lib/blog-dynamic` 数据目录。

脚本会保留 `/etc/blog-dynamic.env` 作为主要配置文件，并额外生成 `/etc/blog-dynamic.docker.env` 供 `docker run --env-file` 兜底路径使用。日常修改密码和配置只改 `/etc/blog-dynamic.env`，不要手动维护 Docker 专用文件。

Docker 方案不需要宿主机安装 Node.js；Node 运行时在镜像内。容器只监听宿主机 `127.0.0.1:8787`，公开域名通过 nginx 或 Cloudflare 反向代理访问。

非 Docker 备用脚本会优先使用已有的 Node.js 18+。如果目标机没有可用版本，会尝试把可移植 Node.js 安装到 `/opt/blog-node`，可通过 `BLOG_DYNAMIC_NODE_DIR` 和 `BLOG_DYNAMIC_NODE_VERSION` 覆盖。

生产环境必须设置真实环境变量。先复制示例文件到服务器上的 `.env` 或 systemd 环境文件，再把占位值替换成真实值。

```bash
BLOG_DYNAMIC_HOST=127.0.0.1
BLOG_DYNAMIC_PORT=8787
BLOG_DYNAMIC_ALLOWED_ORIGINS=https://blog.example.com
BLOG_DYNAMIC_ADMIN_TOKEN=replace-with-a-long-random-token
BLOG_DYNAMIC_POST_PASSWORD=replace-with-a-publish-password
BLOG_DYNAMIC_DIARY_PASSWORD=replace-with-a-diary-password
BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic
BLOG_DYNAMIC_NODE_DIR=/opt/blog-node
BLOG_DYNAMIC_NODE_VERSION=22.11.0
BLOG_DYNAMIC_PUBLIC_BASE_URL=https://activity.20050619.xyz
BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE=24m
BLOG_DYNAMIC_NGINX_SSL_PROTOCOLS="TLSv1.2 TLSv1.3"
BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE=
BLOG_DYNAMIC_LETSENCRYPT_EMAIL=admin@example.com
BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS=0
BLOG_DYNAMIC_CLOUDFLARED_ENABLE=0
BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE=/etc/blog-dynamic-cloudflared.token
```

不要把真实 `.env`、数据库文件、日记内容或访问日志提交进仓库。

密码修改位置：

- 动态发布密码：`BLOG_DYNAMIC_POST_PASSWORD`
- 日记密码：`BLOG_DYNAMIC_DIARY_PASSWORD`

如果使用 systemd，一般修改服务器上的 `/etc/blog-dynamic.env` 后重启服务。静态博客页面要能连接这个服务，还需要在 GitHub Actions Variables 中配置 `PUBLIC_DYNAMIC_API_BASE` 并重新部署。

生产环境下动态服务公开地址必须支持 HTTPS。部署脚本默认会在 `/etc/letsencrypt/live/<域名>/` 查找证书；如果设置了 `BLOG_DYNAMIC_LETSENCRYPT_EMAIL`，脚本会自动用 certbot 申请 Let's Encrypt 证书并写入 443 nginx 配置。如果你使用已有证书，则设置 `BLOG_DYNAMIC_SSL_CERT_PATH` 和 `BLOG_DYNAMIC_SSL_KEY_PATH`。如果 Cloudflare 代理挡住 HTTP-01 验证，可设置 `BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS=1` 让服务器生成 origin TLS 证书并开启 443 回源，Cloudflare 需使用 Full 模式。证书私钥只放服务器上，不要提交。默认不要设置 `BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE`，避免回源 TLS 握手因为曲线不匹配失败。

如果源站本机 HTTPS 正常，但 Cloudflare 带域名 SNI 回源仍返回 525 或被上游备案策略拦截，推荐启用 Cloudflare Tunnel。把 Tunnel token 放到服务器的 `/etc/blog-dynamic-cloudflared.token`，再设置：

```bash
export BLOG_DYNAMIC_CLOUDFLARED_ENABLE=1
export BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE=/etc/blog-dynamic-cloudflared.token
sudo -E bash server/bootstrap-docker.sh
```

Tunnel 公共主机名里把 `activity.20050619.xyz` 指向 `http://127.0.0.1:8787`。这个方案不依赖公网 80/443 入站回源，迁移服务器时除了环境文件和数据目录，还要迁移 token 文件。真实 Tunnel token 不要写入仓库或聊天记录。

可迁移部署只依赖两类服务器状态：

- `/etc/blog-dynamic.env`
- `/etc/blog-dynamic.docker.env` 可由脚本重新生成，不需要手动迁移
- `/var/lib/blog-dynamic`
- 如果启用 Cloudflare Tunnel：`/etc/blog-dynamic-cloudflared.token`

迁移到新服务器时，把这两项迁过去，重新运行 `server/bootstrap-linux.sh`，再把动态服务域名的 DNS 指向新服务器即可。

如果使用 Docker 方案，迁移到新服务器时把这两项迁过去，重新运行 `server/bootstrap-docker.sh`，再把动态服务域名的 DNS 指向新服务器即可。

## API

- `GET /health`
- `GET /api/stats?path=/blog/`
- `POST /api/stats/pageview`
- `GET /api/dynamics?limit=6`
- `GET /uploads/...`
- `GET /api/life?limit=6`
- `POST /api/dynamics/session`
- `POST /api/dynamics`
- `POST /api/life`
- `POST /api/diary/session`
- `GET /api/diary`
- `POST /api/diary`
- `GET /admin/`

受保护接口按接口分别使用发布密码、日记密码或管理员 Token：

```text
Authorization: Bearer <BLOG_DYNAMIC_ADMIN_TOKEN>
```

## 数据目录

服务会在 `BLOG_DYNAMIC_DATA_DIR` 中创建：

- `stats.json`
- `dynamic-records.json`
- `life-records.json`
- `diary-entries.json`
- `uploads/`

生产环境建议放在 `/var/lib/blog-dynamic` 这类仓库外路径，并配置备份。
