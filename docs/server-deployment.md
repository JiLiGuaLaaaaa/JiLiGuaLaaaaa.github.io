# 独立动态服务服务器部署说明

本文只记录部署步骤和占位配置。真实服务器地址、账号、密码、Token、证书私钥和数据库内容不得写入仓库。

## 目标结构

```text
GitHub Pages 静态博客
  https://blog.20050619.xyz

独立动态服务服务器
  https://activity.20050619.xyz
  -> 127.0.0.1:8787
```

静态博客仍由 GitHub Actions 发布到 GitHub Pages。独立动态服务服务器只运行 `server/index.mjs`，负责访问量统计、公开动态发布和私密日记管理 API。

服务器可以是带公网 IP 的私人 Linux 小电脑，也可以是 ECS、VPS 或其他云服务器。迁移时不需要改前端代码，只需要迁移环境文件、数据目录，并把 DNS 指到新服务器。

## Docker 一键部署脚本

推荐使用 Docker 部署动态服务。宿主机只保留 nginx、Cloudflare 前置或其他反向代理职责，Node.js 运行时在容器里，减少服务器迁移时的环境差异。

```bash
sudo bash server/bootstrap-docker.sh
```

脚本会完成：

- 检查或安装 Docker、Docker Compose、nginx。
- 把动态服务代码、`Dockerfile` 和 `docker-compose.yml` 放到 `/opt/blog-project/server/`。
- 创建数据目录 `/var/lib/blog-dynamic`。
- 创建环境文件 `/etc/blog-dynamic.env`。
- 构建并启动 `blog-dynamic` 容器。
- 创建 nginx 80 端口反向代理配置，默认 `client_max_body_size` 为 `24m`，用于支持动态图片上传。

容器默认只映射到宿主机：

```text
127.0.0.1:8787 -> container:8787
```

公开访问仍通过 nginx 或 Cloudflare 到达 `https://activity.20050619.xyz`。

默认动态服务公开域名是：

```text
activity.20050619.xyz
```

可以在运行脚本前用环境变量覆盖：

```bash
export BLOG_DYNAMIC_DOMAIN=activity.20050619.xyz
export BLOG_DYNAMIC_BLOG_ORIGIN=https://blog.20050619.xyz
export BLOG_DYNAMIC_REPO_DIR=/opt/blog-project
export BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic
export BLOG_DYNAMIC_ENV_FILE=/etc/blog-dynamic.env
export BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE=24m
sudo -E bash server/bootstrap-docker.sh
```

如果非交互执行脚本，必须提前设置密码变量，或者允许脚本自动生成：

```bash
export BLOG_DYNAMIC_POST_PASSWORD=replace-with-a-publish-password
export BLOG_DYNAMIC_DIARY_PASSWORD=replace-with-a-diary-password
export BLOG_DYNAMIC_ADMIN_TOKEN=replace-with-a-long-random-token
sudo -E bash server/bootstrap-docker.sh
```

这些真实值只应存在于目标服务器环境中，不要复制回仓库。

## 非 Docker 备用脚本

仓库也保留通用 Linux 直装脚本：

```bash
sudo bash server/bootstrap-linux.sh
```

备用脚本会完成：

- 检查或安装 Node.js、nginx。
- 创建系统用户 `blog`。
- 把动态服务代码放到 `/opt/blog-project/server/index.mjs`。
- 必要时把可移植 Node.js 安装到 `/opt/blog-node`，减少对发行版包源状态的依赖。
- 创建数据目录 `/var/lib/blog-dynamic`。
- 创建环境文件 `/etc/blog-dynamic.env`。
- 创建并启动 systemd 服务 `blog-dynamic`。
- 创建 nginx 80 端口反向代理配置，默认 `client_max_body_size` 为 `24m`。

备用脚本默认动态服务公开域名是：

```text
activity.20050619.xyz
```

可以在运行脚本前用环境变量覆盖：

```bash
export BLOG_DYNAMIC_DOMAIN=activity.20050619.xyz
export BLOG_DYNAMIC_BLOG_ORIGIN=https://blog.20050619.xyz
export BLOG_DYNAMIC_REPO_DIR=/opt/blog-project
export BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic
export BLOG_DYNAMIC_ENV_FILE=/etc/blog-dynamic.env
export BLOG_DYNAMIC_NODE_DIR=/opt/blog-node
export BLOG_DYNAMIC_NODE_VERSION=22.11.0
export BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE=24m
sudo -E bash server/bootstrap-linux.sh
```

如果非交互执行备用脚本，也必须提前设置密码变量，或者允许脚本自动生成：

```bash
export BLOG_DYNAMIC_POST_PASSWORD=replace-with-a-publish-password
export BLOG_DYNAMIC_DIARY_PASSWORD=replace-with-a-diary-password
export BLOG_DYNAMIC_ADMIN_TOKEN=replace-with-a-long-random-token
sudo -E bash server/bootstrap-linux.sh
```

Docker 方案是当前推荐路径，备用脚本只用于无法使用 Docker 的服务器。

## DNS

在 DNS 服务商中为动态服务准备独立子域名：

```text
activity.20050619.xyz  A  <SERVER_PUBLIC_IP>
```

如果使用 Cloudflare 代理，请在服务器上配置 HTTPS 或使用 Cloudflare 的安全回源方案。真实域名和公网 IP 以控制台为准，不写入仓库。

## 服务器目录

建议在服务器上使用类似目录：

```text
/opt/blog-project        # 项目源码
/var/lib/blog-dynamic    # 动态数据目录
/etc/blog-dynamic.env    # 服务环境变量
```

动态数据目录必须在仓库外，避免日记、动态草稿或兼容数据、访问量数据被提交。动态图片保存在 `/var/lib/blog-dynamic/uploads/`，迁移和备份时必须包含整个 `/var/lib/blog-dynamic`。

## 环境变量

在服务器上创建 `/etc/blog-dynamic.env`，内容参考：

```text
BLOG_DYNAMIC_HOST=127.0.0.1
BLOG_DYNAMIC_PORT=8787
BLOG_DYNAMIC_ALLOWED_ORIGINS=https://blog.20050619.xyz,http://localhost:4321
BLOG_DYNAMIC_ADMIN_TOKEN=replace-with-a-long-random-token
BLOG_DYNAMIC_POST_PASSWORD=replace-with-a-publish-password
BLOG_DYNAMIC_DIARY_PASSWORD=replace-with-a-diary-password
BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic
BLOG_DYNAMIC_NODE_DIR=/opt/blog-node
BLOG_DYNAMIC_NODE_VERSION=22.11.0
BLOG_DYNAMIC_PUBLIC_BASE_URL=https://activity.20050619.xyz
BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE=24m
```

其中 `BLOG_DYNAMIC_ADMIN_TOKEN` 必须替换为足够长的随机值。不要把真实文件复制回仓库。

如果要修改动态发布密码或日记密码，就改这两个值：

- `BLOG_DYNAMIC_POST_PASSWORD`
- `BLOG_DYNAMIC_DIARY_PASSWORD`

它们只应保存在服务器的环境变量文件里，不要写进 GitHub Pages、前端页面、README 或提交记录。

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

使用一键脚本时不需要手动复制这个文件，脚本会按变量自动生成。

## 反向代理

仓库提供 nginx 示例：

```text
server/nginx.conf.example
```

部署时把 `activity.20050619.xyz` 换成真实 API 子域名，并确保反向代理到：

```text
http://127.0.0.1:8787
```

HTTPS 证书可以由 Cloudflare、服务器上的 ACME 工具或其他受信任方式管理。证书私钥不能提交。

## 静态博客构建配置

GitHub Pages 构建时需要配置公开环境变量：

```text
PUBLIC_DYNAMIC_API_BASE=https://activity.20050619.xyz
```

在 GitHub 仓库的 `Settings -> Secrets and variables -> Actions -> Variables` 里新增同名变量 `PUBLIC_DYNAMIC_API_BASE`，值填动态服务公开地址。GitHub Actions 构建时会读取这个变量。如果它为空，静态博客仍可正常浏览，只是不显示访问量，动态页面会提示未连接动态服务，连续点击小人会打开日记密码弹窗，但无法完成验证。

## 迁移到另一台服务器

迁移时核心只有两类状态：

- 环境文件：`/etc/blog-dynamic.env`
- 数据目录：`/var/lib/blog-dynamic`

建议流程：

1. 在旧服务器停止服务：`sudo systemctl stop blog-dynamic`
2. 备份 `/etc/blog-dynamic.env` 和 `/var/lib/blog-dynamic`
3. 在新服务器放置当前仓库代码并运行 `sudo bash server/bootstrap-linux.sh`
4. 把备份的环境文件和数据目录恢复到新服务器
5. 重启服务：`sudo systemctl restart blog-dynamic`
6. 在 Cloudflare 或 DNS 服务商中把动态服务子域名指向新服务器公网 IP
7. 如果公开地址没变，GitHub Actions Variable 不需要改；如果公开地址变了，修改 `PUBLIC_DYNAMIC_API_BASE` 后重新部署 GitHub Pages

## 验证

部署后可以检查：

```text
GET https://activity.20050619.xyz/health
GET https://activity.20050619.xyz/api/stats?path=/blog/
GET https://activity.20050619.xyz/api/dynamics?limit=6
GET https://activity.20050619.xyz/api/life?limit=6
GET https://activity.20050619.xyz/uploads/dynamics/<example-image>
```

管理 Token 可用于受保护接口，网页端动态发布和日记入口分别使用发布密码、日记密码：

```text
Authorization: Bearer <BLOG_DYNAMIC_ADMIN_TOKEN>
```

不要在公开页面、README、提交记录或工单中粘贴真实 Token。
