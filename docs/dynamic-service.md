# ECS 动态服务方案

公开博客继续由 GitHub Pages 托管，动态功能独立运行在 ECS 上。仓库只保存源码、示例配置和部署说明，不保存真实域名、服务器地址、Token、数据库、访问日志或私密日记内容。

## 架构边界

- 静态博客：Astro 构建，发布到 GitHub Pages。
- 动态服务：Node.js 服务，部署在 ECS。
- 前端接入：通过 `PUBLIC_DYNAMIC_API_BASE` 配置 API 基础地址。
- 写日记入口：连续点击小人 20 次且在 10 秒内完成后，打开日记密码确认。
- 安全边界：小人入口只是隐藏入口，真正写入由动态服务的会话或认证保护。

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
BLOG_DYNAMIC_PUBLIC_BASE_URL=https://api.example.com
```

静态博客构建时使用：

```text
PUBLIC_DYNAMIC_API_BASE=https://api.example.com
```

这些值都必须在真实部署环境中填写。不要把真实值提交到仓库。

## API 设计

公开 API：

- `GET /health`：健康检查。
- `GET /api/stats?path=/blog/`：读取全站和单页访问量。
- `POST /api/stats/pageview`：记录一次页面访问，只保存聚合计数。
- `GET /api/dynamics?limit=6`：读取已发布的公开动态。
- `GET /api/life?limit=6`：兼容旧地址，返回同样的动态列表。

写入接口：

- `POST /api/dynamics`：创建公开动态，需要发布密码。
- `POST /api/diary/session`：验证日记密码并创建短期会话。
- `POST /api/diary`：写入私密日记。
- `GET /api/diary`：读取私密日记列表。
- `POST /api/life`：兼容旧地址，写入逻辑与动态接口一致。
- `GET /admin/`：动态服务提供的简单管理页面。

其中 `POST /api/diary` 和 `GET /api/diary` 支持会话令牌或管理员 Token；`GET /admin/` 也可以继续用管理员 Token 进入。

```text
Authorization: Bearer <BLOG_DYNAMIC_ADMIN_TOKEN>
```

## 数据存储

默认使用文件存储，路径由 `BLOG_DYNAMIC_DATA_DIR` 指定：

- `stats.json`：访问量聚合数据。
- `dynamic-records.json`：公开动态记录。
- `life-records.json`：旧生活记录兼容文件，仍会被公开 API 合并读取。
- `diary-entries.json`：私密日记，只能通过认证 API 读取。

生产环境应把数据目录放在仓库外，例如 `/var/lib/blog-dynamic`，并做好服务器备份。

## CORS

动态服务只允许 `BLOG_DYNAMIC_ALLOWED_ORIGINS` 中配置的来源访问。开发时可以加入本地 Astro 地址，生产时只保留博客域名。

## 域名和反向代理

建议使用独立 API 子域名指向 ECS 动态服务。示例反向代理关系：

```text
https://api.example.com  ->  http://127.0.0.1:8787
```

真实 DNS、HTTPS 证书和反向代理配置需要在服务器或控制台中完成。仓库文档只使用占位符。
