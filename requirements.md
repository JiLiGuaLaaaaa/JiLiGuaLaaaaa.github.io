# 项目需求说明

## 1. 项目定位

本项目是个人静态博客，目标是简单、安全、维护成本低、容易迁移。

公开博客必须保持静态，当前技术路线是：

- Astro + TypeScript
- Markdown / MDX 写文章
- pnpm 管理依赖
- GitHub Actions 构建
- GitHub Pages 托管
- Cloudflare 管理 DNS、自定义域名、HTTPS 和前置保护

阿里云 ECS 只作为未来动态服务预留。当前公开博客不要引入 ECS、Docker、数据库、服务端运行时、WordPress、Ghost 或后端 API。

## 2. 网站信息

- 网站名称：`辣子鸡丁砂锅`
- 网站描述：`这个人懒死了，什么介绍都没有`
- 作者昵称：`辣子鸡丁砂锅`
- 语言：中文，用户可见文案默认使用简体中文
- 公开地址：`https://blog.20050619.xyz`
- GitHub 账号：`JiLiGUaLaaaaa`
- GitHub 仓库：`git@github.com:JiLiGuaLaaaaa/JiLiGuaLaaaaa.github.io.git`
- GitHub Pages 目标域名：`jiligualaaaaa.github.io`
- Cloudflare DNS：`blog CNAME jiligualaaaaa.github.io`

站点名称、描述、头像和图标必须集中配置，方便以后修改。

## 3. 安全规则

永远不要提交密钥或敏感信息。

禁止提交：

- ECS 登录信息、root 密码、公网 IP 与密码组合
- SSH 私钥
- Cloudflare API Token
- GitHub Token
- 包含真实密钥的 `.env`
- 数据库文件
- 私密日记内容
- 本地服务器登录信息
- 任何账号密码或真实服务连接信息

`.gitignore` 必须覆盖常见敏感文件：

```gitignore
.env
.env.*
*.pem
*.key
server-secret.txt
secrets.txt
private/
diary/
*.sqlite
*.db
相关配置信息.txt
```

`相关配置信息.txt` 是本地配置文件，不能读取、展示或提交。若发现真实敏感信息已经进入仓库，应立即停止并报告。

## 4. 页面与内容

公开站点需要保留：

- 首页
- 博客列表页
- 博客文章详情页
- 关于页
- 标签页
- 归档页
- 搜索页或搜索入口
- 404 页面
- RSS
- sitemap
- robots.txt

文章放在 `src/content/blog/`，使用 Markdown 或 MDX。推荐 frontmatter：

```yaml
title: "文章标题"
description: "文章描述"
pubDate: 2026-01-01
updatedDate: 2026-01-02
tags:
  - 示例标签
draft: false
```

文章公开路径必须使用 `/blog/xxx/`，不要改成 `/posts/xxx/`。生产环境不发布 `draft: true` 的文章。

## 5. 功能要求

必须保留或预留：

- 暗色模式
- RSS 订阅
- sitemap
- robots.txt
- 标签
- 归档
- 静态搜索，优先使用纯前端方案
- 右下角二次元小角色

当前不显示评论区，也不显示评论占位，不接入任何真实评论系统。未来评论、统计、表单、API、私密日记等动态能力应作为独立服务部署，不混入当前公开静态博客。

私密日记不得放进 GitHub Pages。不要创建 `/diary`、`/private`、`/private-diary` 等公开路由，除非用户明确确认这些内容可以公开。

## 6. 当前视觉设计

整体视觉参考 `uxiaohan/vhAstro-Theme` 的卡片、资料卡、两列布局和柔和 Banner 风格，但只迁移静态前端表现。

当前设计要求：

- 使用樱花粉色系和柔和渐变
- 页面基础背景使用简单柔和渐变，不再把 `public/images/site-bg.jpg` 作为博客页面背景图
- 顶部 Banner / Hero 使用 `public/images/banner/` 中的主题图片；前景图片应在保证主要人物完整可见的前提下尽可能占满整个 Banner，只有前景图因比例限制无法铺满时，才使用模糊背景层补足空白区域；前景图和模糊背景之间不能有生硬分界，应通过柔和透明过渡、边缘混合和遮罩融合；浅色模式下 Banner 图片不能被白色遮罩压得模糊发灰
- 博客、标签、标签详情、归档、搜索、关于等主题页的 Banner 在向下滚动时应统一流畅收起，让正文区域完整展示
- 即使页面正文内容很少，也要保留足够的页面可滚动空间，保证用户仍然可以向下滚动并触发 Banner 收起；不足内容用空白区域补齐，不用无意义内容填充
- 顶部导航栏应在用户向下滚动时收起，向上滚动时重新显示；页面回到顶部时必须显示；滚动到页面底部时不要因为浏览器滚动校正或回弹误触发显示；并尊重 `prefers-reduced-motion`
- 不再维护单独主界面；根路径 `/` 进入后应直接跳转到博客页 `/blog/`
- 文章列表卡片应支持整张卡片点击进入文章，卡片内标签链接仍应可以单独点击
- 移动端顶部导航应保持紧凑，暗色/亮色模式按钮不要单独占一整行
- 首屏加载应避免不必要的重资源抢占，例如全量动作帧立即预加载或高成本固定背景绘制
- 资料卡显示头像、文章数、标签数、热门标签快捷导航和公开 QQ
- 页脚 RSS/Sitemap 使用两组拼接复古徽章：`SEO + Sitemap`、`订阅 + RSS`
- 博客列表页顶部只保留标题，不显示旧说明文案
- 博客概览只显示文章数和标签数，不显示 `/blog/` 路径

当前公开资源：

- `public/images/site-icon.png`：网页图标
- `public/images/blog-avatar.png`：博客头像
- `public/images/banner/`：主题 Banner 图片
  - `blog.png`：博客页 Banner
  - `tags.png`：标签页和标签详情页 Banner
  - `archive.png`：归档页 Banner
  - `search.png`：搜索页 Banner
  - `about.png`：关于页 Banner
- `public/images/video-mascot/`：当前主用小人动作帧

不要再保留旧版小人帧、旧抠图、旧预览图、审查图或根目录重复素材作为仓库内容。

## 7. 二次元小角色

组件路径：`src/components/CursorCharacter.astro`。

当前小人使用 `public/images/video-mascot/` 中的透明 PNG 动作帧。当前动作设计已经确认满意，后续不要重新设计、重切、重生成或替换动作帧，除非用户明确要求。

必须保留：

- 鼠标移动时按角度切换视线方向
- 多角度方向帧
- 正面闲置眨眼
- 点击一次只播放一次挥手
- 拖动位置
- 隐藏 / 显示
- 移动端隐藏
- `prefers-reduced-motion`
- 图片预加载和双图片层切换，避免切帧闪烁

如果以后需要重新生成当前小人帧，使用：

- 本地源视频：`生成指定动作视频 (3).mp4`
- 处理脚本：`scripts/process_video_mascot.py`
- 工具环境：使用 `uv` 安装并运行 Python 依赖

生成脚本可以输出本地预览图和审查图，但这些临时产物不要提交。

小人说话文案在 `src/components/CursorCharacter.astro` 中维护：

- 初始气泡文字在 `data-character-bubble`
- 自动轮播文案在 `messages` 数组
- 重新显示时的文案在 `say("我回来啦。")`

这些文案会公开显示，不要写入任何敏感信息。

## 8. 部署规则

使用 GitHub Actions 部署到 GitHub Pages，工作流位于 `.github/workflows/deploy.yml`。

部署流程：

1. 安装 pnpm 和 Node
2. 执行 `pnpm install --frozen-lockfile`
3. 执行 `pnpm build`
4. 上传 `dist/`
5. 发布到 GitHub Pages

GitHub Pages 的 Source 必须选择 GitHub Actions，不要使用 Deploy from a branch。否则 GitHub Pages 会按 Jekyll 解析 Astro 源码并导致 YAML front matter 错误。

Astro 站点地址应为 `https://blog.20050619.xyz`。公开博客不要使用 ECS 或 Docker 部署。

## 9. 文档与计划规则

需求变化时按顺序处理：

1. 更新 `requirements.md`
2. 更新 `plan.md`
3. 实现代码或资源调整
4. 必要时更新 README
5. 运行检查
6. 完成后更新 plan 状态

`plan.md` 使用 Markdown checkbox，保留关键历史阶段和当前 TODO，不再记录过度冗长的逐轮细节。

README 使用简单中文说明：

- 项目是什么
- 如何本地运行
- 如何写文章
- 如何构建和部署
- GitHub Pages 和 Cloudflare 如何配置
- RSS、sitemap、标签、归档、搜索是什么
- 哪些文件不能提交
- 为什么当前公开博客不使用 ECS
- 当前主要资源放在哪里

## 10. 质量检查

完成任务前优先运行：

```bash
pnpm install
pnpm build
```

如果环境没有全局 `pnpm`，可使用：

```bash
corepack pnpm install --frozen-lockfile
corepack pnpm build
```

如果包含可用检查，也应运行：

- `tsc --noEmit`
- `git diff --check`
- 敏感词或敏感文件扫描

如果 `pnpm build` 在当前沙箱环境因 Astro/Vite `spawn EPERM` 失败，要明确说明，并在本机或 GitHub Actions 再验证。

## 11. 项目整理规则

保持仓库轻量：

- 不提交 `dist/`、`.astro/`、`node_modules/`、`.venv/`、`.uv-cache/`、`.pnpm-store/`
- 不提交视频源文件、预览图、审查图、Python `__pycache__` 或临时处理产物
- 不保留已被当前实现替代的旧资源和旧脚本
- 删除文件前必须确认不被当前代码、构建流程或后续维护脚本引用

## 12. 非目标

除非用户明确修改需求，否则不要实现：

- WordPress
- Ghost
- 服务端渲染博客
- 数据库 CMS
- 用户登录系统
- 公开博客后台管理系统
- 当前仓库中的动态后端 API
- 当前公开博客的 Docker 或 ECS 部署
- 把私密日记放进 GitHub Pages
