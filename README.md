# 辣子鸡丁砂锅

这是一个个人静态博客，使用 Astro 构建，部署到 GitHub Pages，并通过 Cloudflare 使用自定义域名 `blog.20050619.xyz`。

当前公开博客只发布静态页面，不依赖 ECS、Docker、数据库、后端 API、WordPress 或 Ghost。

GitHub 仓库地址：`git@github.com:JiLiGuaLaaaaa/JiLiGuaLaaaaa.github.io.git`。

## 常用命令

```bash
pnpm install
pnpm dev
pnpm build
pnpm preview
```

- `pnpm dev`：本地开发预览。
- `pnpm build`：检查并构建静态站点。
- `pnpm preview`：预览构建后的站点。

## 写文章

文章放在 `src/content/blog/`，使用 Markdown 或 MDX。

推荐 frontmatter：

```yaml
title: "文章标题"
description: "文章描述"
pubDate: 2026-01-01
updatedDate: 2026-01-02
tags:
  - 示例标签
draft: false
```

公开文章路径是 `/blog/xxx/`。生产页面会过滤 `draft: true` 的文章。

## 页面和功能

- 首页：展示站点简介、最近文章和标签。
- 博客：列出所有公开文章。
- 标签：按主题分类文章。
- 归档：按年份整理文章。
- 搜索：使用纯前端静态搜索数据，不连接后端。
- RSS：`/rss.xml`，用于订阅文章更新。
- sitemap：由 Astro sitemap 集成生成，帮助搜索引擎发现页面。
- robots.txt：公开爬虫规则并声明 sitemap 地址。
- 评论占位：现在只留位置，不连接任何评论服务。
- 二次元小角色：使用 `public/images/mascot-frames/` 中的动作帧，支持鼠标视线方向切换、正面空闲眼部眨眼、点击挥手、拖动位置和隐藏；移动端隐藏，不连接后端。眨眼时用前端眼皮层真实盖住眼睛，挥手时用静止底图叠加右臂动作，避免身体大幅漂移。

图片资源放在 `public/images/`：

- `site-bg.jpg`：页面背景图，显示时约 45% 不透明度。
- `mascot-frames/look/`：九宫格视线方向帧，用于根据鼠标位置切换小人朝向；右向帧由左向帧镜像生成，保证左右一致。
- `mascot-frames/blink/`：保留眨眼审核帧；实际网页眨眼使用正面帧上的 CSS 眼皮层，只改变眼部，不切换整张人物图。
- `mascot-frames/wave/`：打招呼帧，用于点击或显示时的挥手动作；包含算法补出的 `wave-*-to-*` 过渡帧，让动作更连贯。当前挥手帧以静止正面帧为底图，再叠加右臂动作，减少身位变化。
- `scripts/refine_mascot_frames.py`：使用 `uv` 虚拟环境中的 Pillow 重新生成动作帧、修复挥手切分边界、补正上/正下视角、填补下摆透明破洞和生成补帧。
- 所有动作帧统一为同一画布和同一底部基线，避免动作之间忽大忽小。
- `mascot-frames/preview.jpg`：动作帧预览图，只用于本地检查，不提交到仓库。

## 部署

GitHub Actions 工作流位于 `.github/workflows/deploy.yml`。

流程是：

1. 安装 pnpm 和 Node。
2. 执行 `pnpm install --frozen-lockfile`。
3. 执行 `pnpm build`。
4. 上传 `dist/` 静态产物。
5. 发布到 GitHub Pages。

GitHub Pages 需要在仓库设置里启用 Pages，并选择 GitHub Actions 作为构建和部署来源。

如果 Actions 日志里出现 `GitHub Pages: jekyll` 或 `.astro` 文件的 YAML front matter 错误，说明 Pages 仍在使用 `Deploy from a branch`。需要进入仓库 `Settings -> Pages`，把 `Build and deployment -> Source` 改成 `GitHub Actions`。

`public/.nojekyll` 会随构建产物一起发布，用来明确告诉 GitHub Pages 不要按 Jekyll 处理静态产物。

## Cloudflare 和 CNAME

Cloudflare 中的 DNS 记录应保持：

```text
blog CNAME jiligualaaaaa.github.io
```

CNAME 的意思是把 `blog.20050619.xyz` 指向 GitHub Pages 的默认域名。仓库中的 `public/CNAME` 会在构建后生成 Pages 需要的自定义域名文件。

不要把 Cloudflare API Token、账号密码或任何密钥写进仓库。

## 为什么当前不使用 ECS

公开博客是静态站点，GitHub Pages 已经可以托管 HTML、CSS、JS 和图片，不需要服务器长期运行。

ECS 暂时只作为未来动态服务预留，例如评论、统计、表单、API 或私密日记。未来这些服务应使用独立子域名和访问控制，不应混入当前公开静态博客。

## 不要提交的文件

不要把以下内容提交到仓库：

- ECS 登录名、密码、公网 IP 和密码组合
- SSH 私钥
- Cloudflare API Token
- GitHub Token
- 包含真实密钥的 `.env`
- 数据库文件
- 私密日记内容
- 本地服务器登录信息

`.gitignore` 已经包含这些常见敏感文件规则，但仍需要在提交前人工确认没有泄露信息。
