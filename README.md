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
- 二次元小角色：当前使用 `public/images/video-mascot/` 中从用户视频处理得到的透明动作帧，支持鼠标视线方向切换、多角度方向帧、正面空闲眨眼、点击单次挥手、拖动位置和隐藏；移动端隐藏，不连接后端。组件会在播放前预解码图片以减少闪烁。

图片资源放在 `public/images/`：

- `site-bg.jpg`：页面背景图，显示时约 45% 不透明度。
- `video-mascot/look/`：从视频中抽取的视线方向帧，用于根据鼠标位置切换小人朝向；左右命名按网页鼠标方向修正，右向帧由左向帧镜像生成，保证左右一致。
- `video-mascot/look-angle/`：由八方向视角帧按角度权重混合生成的 36 张方向细分帧，每 10° 一张。组件会根据鼠标相对角度选择最接近的方向帧，例如上偏左、上偏右、下偏左、下偏右等，不再只是从中心帧过渡到八方向帧。
- `video-mascot/blink/`：从视频闭眼段抽取并贴回正面身体轮廓的眨眼帧，实际网页只在正面闲置、没有方向过渡时播放，避免眨眼闪烁或突然跳帧。
- `video-mascot/wave/`：从视频挥手段抽取的 8 个实帧，用于点击或显示时的挥手动作。点击一次只播放一次正向伸手/挥手序列，结束后回到正面帧。
- `scripts/process_video_mascot.py`：使用 `uv` 虚拟环境中的 `imageio`、`imageio-ffmpeg`、`numpy` 和 Pillow 从 `生成指定动作视频 (2).mp4` 抽帧；通过 HSV/色键思路去除绿色背景，通过水印角落文字检测替换为绿幕色并只保留人物主连通区域去除水印，再统一画布和底部基线。挥手帧会保护手部肤色区域，避免指尖在抠图时被削掉。
- 重新处理视频帧前，先运行 `uv pip install pillow imageio imageio-ffmpeg numpy`，再运行 `uv run python scripts/process_video_mascot.py`。
- `mascot-frames/` 和 `scripts/refine_mascot_frames.py`：保留上一版图片帧生成方案，作为备用资源，不再是当前网页主用小人。
- 所有动作帧统一为同一画布和同一底部基线，避免动作之间忽大忽小。
- `video-mascot/preview.jpg`：视频动作帧预览图，只用于本地检查，不提交到仓库。

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
