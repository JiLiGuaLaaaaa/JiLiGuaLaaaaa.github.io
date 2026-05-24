# 独立动态服务方案

公开博客继续由 GitHub Pages 托管，动态功能独立运行在一台 Linux 动态服务服务器上。服务器可以是带公网 IP 的私人小电脑，也可以是 ECS、VPS 或其他云服务器。仓库只保存源码、示例配置和部署说明，不保存真实服务器地址、账号密码、Token、数据库、访问日志或私密日记内容。

## 架构边界

- 静态博客：Astro 构建，发布到 GitHub Pages。
- 动态服务：Node.js 服务，部署在独立动态服务服务器。
- 前端接入：通过 `PUBLIC_DYNAMIC_API_BASE` 配置 API 基础地址。
- 写日记入口：连续点击小人 20 次且在 8 秒内完成后，打开日记密码确认；密码正确后先进入日记本列表，再通过新建入口写日记。
- 安全边界：小人入口只是隐藏入口，真正写入由动态服务的会话或认证保护。
- 可迁移边界：迁移服务器时只需要迁移 `/etc/blog-dynamic.env` 和 `BLOG_DYNAMIC_DATA_DIR` 指向的数据目录。

## 环境变量

动态服务使用以下环境变量：

```text
BLOG_DYNAMIC_HOST=127.0.0.1
BLOG_DYNAMIC_PORT=8787
BLOG_DYNAMIC_ALLOWED_ORIGINS=https://blog.example.com,http://localhost:4321
BLOG_DYNAMIC_ADMIN_TOKEN=replace-with-a-long-random-token
BLOG_DYNAMIC_POST_PASSWORD=replace-with-a-publish-password
BLOG_DYNAMIC_DIARY_PASSWORD=replace-with-a-diary-password
BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic
BLOG_DYNAMIC_PUBLIC_BASE_URL=https://activity.20050619.xyz
BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE=24m
BLOG_DYNAMIC_NGINX_SSL_PROTOCOLS="TLSv1.2 TLSv1.3"
BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE=
BLOG_DYNAMIC_ACME_WEBROOT=/var/www/blog-dynamic-acme
BLOG_DYNAMIC_AUTO_ISSUE_TLS=1
BLOG_DYNAMIC_REQUIRE_SSL=1
BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS=0
BLOG_DYNAMIC_SELF_SIGNED_CERT_DIR=/etc/blog-dynamic/tls
BLOG_DYNAMIC_LETSENCRYPT_EMAIL=admin@example.com
BLOG_DYNAMIC_LETSENCRYPT_STAGING=0
BLOG_DYNAMIC_SSL_CERT_PATH=
BLOG_DYNAMIC_SSL_KEY_PATH=
BLOG_DYNAMIC_CLOUDFLARED_ENABLE=0
BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE=/etc/blog-dynamic-cloudflared.token
```

静态博客构建时使用：

```text
PUBLIC_DYNAMIC_API_BASE=https://activity.20050619.xyz
```

这些值都必须在真实部署环境中填写。不要把真实值提交到仓库。

密码修改位置：

- 动态发布密码由服务器环境变量 `BLOG_DYNAMIC_POST_PASSWORD` 控制。
- 日记密码由服务器环境变量 `BLOG_DYNAMIC_DIARY_PASSWORD` 控制。
- 静态页面连接哪个动态服务由 GitHub Actions Variable `PUBLIC_DYNAMIC_API_BASE` 控制。

修改服务器环境变量后需要重启动态服务；修改 GitHub Actions Variable 后需要重新部署 GitHub Pages。

## API 设计

公开 API：

- `GET /health`：健康检查。
- `GET /api/stats?path=/blog/`：读取全站和单页访问量。
- `POST /api/stats/pageview`：记录一次页面访问，只保存聚合计数。
- `GET /api/dynamics?limit=6`：读取已发布的公开动态，包含公开图片引用；支持 `title`、`content`、`q`、`from` 和 `to` 参数，用于标题关键字、正文关键字、综合关键字和日期跨度筛选。
- `GET /api/life?limit=6`：兼容旧地址，返回同样的动态列表。
- `GET /uploads/...`：读取动态图片，只允许读取动态服务数据目录下的图片文件。

写入接口：

- `POST /api/dynamics/session`：验证动态发布密码并创建短期发布会话。
- `POST /api/dynamics`：创建公开动态，需要发布密码、短期发布会话或管理员 Token，支持最多 4 张 JPG/PNG/WebP 图片。
- `PUT/PATCH /api/dynamics/:id`：编辑公开动态，需要短期发布会话或管理员 Token；可以保留已有图片，也可以追加新图片。
- `DELETE /api/dynamics/:id`：删除公开动态，需要短期发布会话或管理员 Token；删除记录时会同时清理对应上传图片文件。
- `POST /api/diary/session`：验证日记密码并创建短期会话。
- `POST /api/diary`：写入私密日记。
- `GET /api/diary`：读取私密日记列表；支持 `q`、`title`、`content`、`from` 和 `to` 参数，可按标题、内容和日期跨度检索。
- `PUT/PATCH /api/diary/:id`：编辑私密日记，需要日记会话或管理员 Token。
- `DELETE /api/diary/:id`：删除私密日记，需要日记会话或管理员 Token。
- `POST /api/life`：兼容旧地址，写入逻辑与动态接口一致。
- `GET /admin/`：动态服务提供的简单管理页面。

其中动态编辑/删除必须使用动态发布会话或管理员 Token，日记读写/编辑/删除必须使用日记会话或管理员 Token；`GET /admin/` 也可以继续用管理员 Token 进入。

```text
Authorization: Bearer <BLOG_DYNAMIC_ADMIN_TOKEN>
```

## 数据存储

默认使用文件存储，路径由 `BLOG_DYNAMIC_DATA_DIR` 指定：

- `stats.json`：访问量聚合数据。
- `dynamic-records.json`：公开动态记录。
- `life-records.json`：旧生活记录兼容文件，仍会被公开 API 合并读取；新版动态管理接口也兼容编辑或删除这些旧记录。
- `diary-entries.json`：私密日记，只能通过认证 API 读取。
- `uploads/`：动态图片目录，公开动态中附带的图片保存在这里。

生产环境应把数据目录放在仓库外，例如 `/var/lib/blog-dynamic`，并做好服务器备份。

## CORS

动态服务只允许 `BLOG_DYNAMIC_ALLOWED_ORIGINS` 中配置的来源访问。开发时可以加入本地 Astro 地址，生产时只保留博客域名。

## 域名和反向代理

建议使用独立 API 子域名指向动态服务服务器。默认建议子域名是 `activity.20050619.xyz`，也可以迁移到其他域名。示例反向代理关系：

```text
https://activity.20050619.xyz  ->  http://127.0.0.1:8787
```

真实 DNS、HTTPS 证书和反向代理配置需要在服务器或控制台中完成。`PUBLIC_DYNAMIC_API_BASE` 使用 HTTPS 时，动态服务域名也必须能通过 HTTPS 访问。部署脚本可以在设置 `BLOG_DYNAMIC_LETSENCRYPT_EMAIL` 后自动申请 Let's Encrypt 证书；如果已经有证书，则用 `BLOG_DYNAMIC_SSL_CERT_PATH` 和 `BLOG_DYNAMIC_SSL_KEY_PATH` 指向服务器上的证书文件。Cloudflare 代理导致 HTTP-01 验证不可用时，也可以设置 `BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS=1` 先生成服务器 origin TLS 证书并打开 443 回源；Cloudflare 需使用 Full 模式，Full strict 应使用受信任证书或 Cloudflare Origin CA。nginx 默认启用 TLS 1.2/1.3，但不写死 ECDH 曲线，避免部分回源握手出现 `bad key share`。

如果源站本机 nginx/TLS 和 `127.0.0.1:8787` 都正常，但公网通过 Cloudflare 仍然出现 525，或者公网 HTTP 返回备案/上游策略拦截页，应使用 Cloudflare Tunnel。Tunnel 让服务器主动连接 Cloudflare，公开访问链路变为：

```text
https://activity.20050619.xyz -> Cloudflare Tunnel -> http://127.0.0.1:8787
```

Docker 部署支持可选的 `cloudflared` profile。真实 Tunnel token 只放在服务器上的 `BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE`，不要写入仓库、README、聊天记录或 `/etc/blog-dynamic.env` 以外的公开位置。仓库文档只使用占位符。
