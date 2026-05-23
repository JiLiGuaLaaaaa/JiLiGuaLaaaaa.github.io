# 博客动态服务

这个目录是部署到独立动态服务服务器的 Node.js 服务，不属于 GitHub Pages 静态构建产物。服务器可以是带公网 IP 的私人 Linux 小电脑，也可以是 ECS、VPS 或其他云服务器。

## 本地运行

```bash
node server/index.mjs
sudo bash server/bootstrap-docker.sh
```

`node server/index.mjs` 用于本地测试。`sudo bash server/bootstrap-docker.sh` 是目标 Linux 服务器上的推荐部署方式，会创建 Docker 容器、nginx、环境文件和数据目录。`sudo bash server/bootstrap-linux.sh` 保留为非 Docker 备用部署方式。

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
```

不要把真实 `.env`、数据库文件、日记内容或访问日志提交进仓库。

密码修改位置：

- 动态发布密码：`BLOG_DYNAMIC_POST_PASSWORD`
- 日记密码：`BLOG_DYNAMIC_DIARY_PASSWORD`

如果使用 systemd，一般修改服务器上的 `/etc/blog-dynamic.env` 后重启服务。静态博客页面要能连接这个服务，还需要在 GitHub Actions Variables 中配置 `PUBLIC_DYNAMIC_API_BASE` 并重新部署。

可迁移部署只依赖两类服务器状态：

- `/etc/blog-dynamic.env`
- `/var/lib/blog-dynamic`

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
