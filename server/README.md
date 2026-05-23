# 博客动态服务

这个目录是部署到 ECS 的独立动态服务，不属于 GitHub Pages 静态构建产物。

## 本地运行

```bash
node server/index.mjs
```

生产环境必须设置真实环境变量。先复制示例文件到服务器上的 `.env` 或 systemd 环境文件，再把占位值替换成真实值。

```bash
BLOG_DYNAMIC_HOST=127.0.0.1
BLOG_DYNAMIC_PORT=8787
BLOG_DYNAMIC_ALLOWED_ORIGINS=https://blog.example.com
BLOG_DYNAMIC_ADMIN_TOKEN=replace-with-a-long-random-token
BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic
BLOG_DYNAMIC_PUBLIC_BASE_URL=https://api.example.com
```

不要把真实 `.env`、数据库文件、日记内容或访问日志提交进仓库。

## API

- `GET /health`
- `GET /api/stats?path=/blog/`
- `POST /api/stats/pageview`
- `GET /api/life?limit=6`
- `POST /api/life`
- `GET /api/diary`
- `POST /api/diary`
- `GET /admin/`

管理类 API 需要：

```text
Authorization: Bearer <BLOG_DYNAMIC_ADMIN_TOKEN>
```

## 数据目录

服务会在 `BLOG_DYNAMIC_DATA_DIR` 中创建：

- `stats.json`
- `life-records.json`
- `diary-entries.json`

生产环境建议放在 `/var/lib/blog-dynamic` 这类仓库外路径，并配置备份。
