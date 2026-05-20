# 辣子鸡丁砂锅

这是一个个人静态博客，使用 Astro 构建，部署到 GitHub Pages，并通过 Cloudflare 使用自定义域名 `blog.20050619.xyz`。

当前视觉优先参考 `uxiaohan/vhAstro-Theme`，保留静态博客架构，迁移顶部 Banner、资料卡、公告卡、磨砂卡片和文章列表等前端表现；不接入主题里的 Twikoo、Waline 或其他真实评论服务。

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

- 首页：使用接近 vhAstro 的顶部 Banner、资料卡、公告卡、最近文章和标签布局。
- 资料卡：显示头像、文章数、标签数和热门标签快捷导航；热门标签按文章数量优先展示，点击后进入对应标签页。
- 博客：列出所有公开文章，并显示文章数、标签数等静态概览。
- 标签：按主题分类文章。
- 归档：按年份整理文章。
- 搜索：使用纯前端静态搜索数据，不连接后端。
- RSS：`/rss.xml`，用于订阅文章更新。
- sitemap：由 Astro sitemap 集成生成，帮助搜索引擎发现页面。
- robots.txt：公开爬虫规则并声明 sitemap 地址。
- RSS、Sitemap 和 SEO 入口在页面底部使用两组拼接复古徽章展示：`SEO + Sitemap` 指向 sitemap，`订阅 + RSS` 指向 RSS。
- 评论：当前不显示评论区，也不显示评论占位；以后如果需要评论，应作为独立动态服务处理。
- 二次元小角色：当前使用 `public/images/video-mascot/` 中从用户视频处理得到的透明动作帧，支持鼠标视线方向切换、多角度方向帧、正面空闲眨眼、点击单次挥手、拖动位置和隐藏；移动端隐藏，不连接后端。组件会在播放前预解码图片，并使用双图片层切换，下一帧确认可用后才替换当前帧，避免切帧时短暂空白闪烁。

公开资料：

- QQ：`1640203349`

当前不新增分类字段，文章继续使用标签和归档组织。友链、朋友圈、动态、留言板等动态功能后续通过服务器或独立动态服务补充，不放进当前静态博客。

图片资源放在 `public/images/`：

- `site-icon.png`：网页图标。
- `blog-avatar.png`：博客个人头像。
- `site-bg.jpg`：全站页面背景图。页面会叠加柔和遮罩保证正文可读，并把背景焦点偏向人物头部；顶部 Banner / Hero 使用纯柔和渐变，不再裁切背景人物图。
- `video-mascot/look/`：从 `生成指定动作视频 (3).mp4` 中重新抽取的视线方向帧，用于根据鼠标位置切换小人朝向；左右命名按网页鼠标方向修正，右向帧由左向真实帧镜像生成。
- `video-mascot/look-angle/`：每 10° 一张的 36 张方向细分帧。现在优先从 `生成指定动作视频 (3).mp4` 的连续视线段抽取稳定真实帧，缺少的右侧对称角度使用真实帧镜像生成，不使用透明叠加、权重混合或插值补帧。生成脚本会输出审查表，记录每张角度帧的源帧号和是否镜像。
- `video-mascot/blink/`：从视频闭眼段抽取并贴回正面身体轮廓的眨眼帧，实际网页只在正面闲置、没有方向过渡时播放，避免眨眼闪烁或突然跳帧。
- `video-mascot/wave/`：从视频挥手段抽取的 8 个实帧，用于点击或显示时的挥手动作。点击一次只播放一次正向伸手/挥手序列，结束后回到正面帧。
- `scripts/process_video_mascot.py`：使用 `uv` 虚拟环境中的 `imageio`、`imageio-ffmpeg`、`numpy` 和 Pillow 从本地 `生成指定动作视频 (3).mp4` 抽帧；通过绿色优势色键、主体连通域保留、肤色/服饰保护、边缘反混色、去绿边和 alpha 柔化生成透明 PNG，再统一到 `860x680` 画布和同一底部基线。
- 重新处理视频帧前，先运行 `uv pip install pillow imageio imageio-ffmpeg numpy`，再运行 `uv run python scripts/process_video_mascot.py`。
- 所有动作帧统一为同一画布和同一底部基线，避免动作之间忽大忽小；前端组件也使用同一宽高比，并预加载/解码全部动作帧。由于透明画布顶部留白较多，页面只在显示层裁掉顶部空白，让提示气泡更贴近可见人物，动作帧文件本身不改变。
- 旧版小人抠图、旧动作帧、旧 refine 脚本、审查图和预览图已经清理；生成脚本产生的临时预览/审查文件只用于本地检查，不提交到仓库。

小角色说话文案在 `src/components/CursorCharacter.astro` 中维护：

- 初始气泡文字在 `data-character-bubble` 那一行。
- 自动轮播的话在 `messages` 数组里，修改、添加或删除数组项即可。
- 隐藏后重新显示时的“我回来啦。”在 `returnButton` 点击事件里的 `say("我回来啦。")`。

这些文案会直接显示在公开网页上，不要写入密钥、服务器地址、账号密码或其他私密信息。

## 待确认问题

如果主题迁移过程中有需要用户决定的页面或构思，会记录在根目录的 `question.md`。当前已根据回答落实：公开 QQ、优先 vhAstro 风格、不新增分类、不显示评论占位，并把动态类页面留到以后通过服务器实现。

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
