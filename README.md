# 辣子鸡丁砂锅

这是一个个人静态博客，使用 Astro 构建，部署到 GitHub Pages，并通过 Cloudflare 使用自定义域名 `blog.20050619.xyz`。

当前视觉优先参考 `uxiaohan/vhAstro-Theme`，保留静态博客架构，迁移顶部 Banner、资料卡、公告卡、磨砂卡片和文章列表等前端表现；不接入主题里的 Twikoo、Waline 或其他真实评论服务。

当前公开博客只发布静态页面，不依赖 Docker、数据库、后端 API、WordPress 或 Ghost。

本次新增的访问量、动态发布和写日记能力采用“静态博客 + 独立动态服务服务器”的方式：GitHub Pages 仍只托管静态页面，带公网 IP 的私人服务器只运行单独的动态 API 服务。真实服务器地址、Token、密码、证书私钥和数据库内容不写入仓库。

GitHub 仓库地址：`git@github.com:JiLiGuaLaaaaa/JiLiGuaLaaaaa.github.io.git`。

## 常用命令

```bash
pnpm install
pnpm dev
pnpm build
pnpm preview
node server/index.mjs
```

- `pnpm dev`：本地开发预览。
- `pnpm build`：检查并构建静态站点。
- `pnpm preview`：预览构建后的站点。
- `node server/index.mjs`：本地启动动态服务骨架，真实部署时需要通过环境变量配置。
- `sudo bash server/bootstrap-docker.sh`：在目标 Linux 服务器上用 Docker 配置动态服务、nginx 和数据目录。
- `sudo bash server/bootstrap-linux.sh`：非 Docker 备用部署方式。

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

- 入口：根路径 `/` 只负责跳转到 `/blog/`，不再维护单独主界面；进入站点后直接看到博客页面。
- 页面背景：博客页面使用基础柔和渐变，不再把背景人物图作为全站背景。
- 主题 Banner：博客、标签、归档、搜索、关于页面使用 `public/images/banner/` 中按主题命名的图片；Banner 前景图会在保证主要人物完整可见的前提下尽可能占满整个区域，只有图片比例无法铺满时才由更强的模糊背景层补足空白。浅色模式下会弱化白色遮罩、提高前景图对比和饱和度，并通过多段透明遮罩做边缘融合，避免和模糊背景出现生硬分界。正文较短的页面会保留额外空白滚动区，保证 Banner 仍然可以被收起。
- 移动端 Banner：保持电脑版效果不变，单独在手机窄屏下提高 Banner 高度，并用超宽前景图层居中显示，让横幅图尽可能填满可见区域，同时仍优先保留主要人物完整。
- 顶部导航：向下滚动时自动收起，明确向上滚动或回到页面顶部时重新显示；滚动到页面底部时保持收起，避免浏览器滚动校正导致导航误弹出。
- 文章列表：整张文章卡片都可以点击进入文章，卡片内标签仍可单独点击进入对应标签页。
- 移动端头部：导航保持紧凑横向排列，暗色/亮色模式按钮和导航在同一行，减少顶部占用空间。
- 资料卡：显示头像、文章数、标签数和热门标签快捷导航；热门标签按文章数量优先展示，点击后进入对应标签页。
- 博客：列出所有公开文章，并显示文章数、标签数等静态概览。
- 标签：按主题分类文章。
- 归档：按年份整理文章。
- 搜索：使用纯前端静态搜索数据，不连接后端。
- 动态：`/dynamic/` 页面会从独立动态服务服务器读取已发布的公开动态；顶部可按标题关键字、正文关键字和起止日期检索。单条动态没有标题时不再显示“动态”占位，动态之间有清晰分界，发布时间显示在右下角；图片以正方形缩略图展示，不裁切原图，点击后按原比例打开。右上角的小笔图标是管理入口，点击后先输入发布密码，密码正确后可以发布新动态，也可以编辑或删除已有动态。编辑器支持文本和最多 4 张图片，图片可点击选择或拖拽进编辑区；短动态完整展示，长内容会显示“查看更多 / 收起”。如果未配置动态服务或 API 不可用，会显示降级提示，不影响静态博客浏览。
- 访问量：页脚会在配置 `PUBLIC_DYNAMIC_API_BASE` 后显示全站访问量和当前页面访问量；统计只保存聚合计数。
- RSS：`/rss.xml`，用于订阅文章更新。
- sitemap：由 Astro sitemap 集成生成，帮助搜索引擎发现页面。
- robots.txt：公开爬虫规则并声明 sitemap 地址。
- RSS、Sitemap 和 SEO 入口在页面底部使用两组拼接复古徽章展示：`SEO + Sitemap` 指向 sitemap，`订阅 + RSS` 指向 RSS。
- 评论：当前不显示评论区，也不显示评论占位；以后如果需要评论，应作为独立动态服务处理。
- 二次元小角色：当前使用 `public/images/video-mascot/` 中从用户视频处理得到的透明动作帧，支持鼠标视线方向切换、多角度方向帧、正面空闲眨眼、点击单次挥手、拖动位置和隐藏；移动端隐藏。8 秒内连续点击小人 20 次会打开写日记入口，入口会先走密码确认，再进入日记本列表；日记本顶部可按标题/内容关键字和起止日期检索，单条日记支持编辑、删除、长正文“查看更多 / 收起”和自动换行，没有标题时不显示占位标题，再通过“新建”进入日记编辑。点击弹窗外部不会关闭日记弹窗，真正写入日记必须经过动态服务认证，入口本身不是安全边界。组件首屏只预热基础朝向帧，其他角度、眨眼和挥手帧延后到浏览器空闲时预加载；播放前仍会预解码图片，并使用双图片层切换，下一帧确认可用后才替换当前帧，避免切帧时短暂空白闪烁。

公开资料：

- QQ：`1640203349`

当前不新增文章分类字段，文章继续使用标签和归档组织。友链、朋友圈、留言板等动态功能后续通过服务器或独立动态服务补充，不放进当前静态博客。

## 动态服务

动态服务源码放在 `server/`，设计说明放在 `docs/dynamic-service.md`，服务器部署说明放在 `docs/server-deployment.md`。

推荐把动态服务部署到带公网 IP 的独立 Linux 服务器，默认公开地址使用：

```text
https://activity.20050619.xyz
```

这个地址需要同时出现在三个地方：

- Cloudflare DNS：`activity` 子域名解析到动态服务服务器公网 IP。
- 服务器环境变量：`BLOG_DYNAMIC_PUBLIC_BASE_URL=https://activity.20050619.xyz`，并在 `BLOG_DYNAMIC_ALLOWED_ORIGINS` 中允许 `https://blog.20050619.xyz`。
- GitHub Actions Variable：`PUBLIC_DYNAMIC_API_BASE=https://activity.20050619.xyz`，用于把动态服务地址写入静态页面构建产物。

服务器上一键配置命令推荐使用 Docker：

```bash
sudo bash server/bootstrap-docker.sh
```

Docker 脚本默认使用 `/opt/blog-project`、`/var/lib/blog-dynamic` 和 `/etc/blog-dynamic.env`。容器只把服务绑定到宿主机 `127.0.0.1:8787`，公开访问继续交给 nginx 或 Cloudflare。非 Docker 环境仍可使用 `server/bootstrap-linux.sh` 作为备用。

动态服务提供：

- `GET /health`：健康检查。
- `POST /api/stats/pageview` 和 `GET /api/stats`：访问量聚合统计。
- `GET /api/dynamics`：读取已发布的公开动态，支持 `title`、`content`、`q`、`from`、`to` 和 `limit` 参数筛选，动态图片通过 `/uploads/...` 公开读取。
- `POST /api/dynamics`：创建公开动态，必须通过发布密码、短期发布会话或管理 Token 确认，支持最多 4 张 JPG/PNG/WebP 图片。
- `PUT/PATCH /api/dynamics/:id`：编辑公开动态，必须通过短期发布会话或管理 Token 认证。
- `DELETE /api/dynamics/:id`：删除公开动态及其图片文件，必须通过短期发布会话或管理 Token 认证。
- `POST /api/diary/session`：验证日记密码并创建短期会话。
- `POST /api/diary` 和 `GET /api/diary`：写入和读取私密日记，必须通过会话或管理 Token 认证；`GET /api/diary` 支持 `q`、`title`、`content`、`from` 和 `to` 参数筛选。
- `PUT/PATCH /api/diary/:id`：编辑私密日记，必须通过日记会话或管理 Token 认证。
- `DELETE /api/diary/:id`：删除私密日记，必须通过日记会话或管理 Token 认证。
- `GET /api/life` 和 `POST /api/life`：保留兼容别名，以动态接口为主。
- `GET /admin/`：简单管理页面，用于写日记和动态。

服务端环境变量示例在 `server/.env.example`。真实部署时需要在服务器上配置：

```text
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
BLOG_DYNAMIC_AUTO_ISSUE_TLS=1
BLOG_DYNAMIC_REQUIRE_SSL=1
BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS=0
BLOG_DYNAMIC_SELF_SIGNED_CERT_DIR=/etc/blog-dynamic/tls
BLOG_DYNAMIC_CLOUDFLARED_ENABLE=0
BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE=/etc/blog-dynamic-cloudflared.token
```

静态博客构建时可配置：

```text
PUBLIC_DYNAMIC_API_BASE=https://activity.20050619.xyz
```

`PUBLIC_DYNAMIC_API_BASE` 需要配置在 GitHub 仓库的 `Settings -> Secrets and variables -> Actions -> Variables` 中，变量名保持 `PUBLIC_DYNAMIC_API_BASE`，值填写你的动态服务公开地址。当前默认建议填写 `https://activity.20050619.xyz`。GitHub Actions 构建时会读取这个变量并写入静态页面。如果它为空，线上博客仍会正常显示静态内容，但访问量、动态列表、动态发布和日记验证都会提示未接上动态服务。

动态发布密码和日记密码不在 GitHub Pages 或前端代码里修改，而是在动态服务服务器环境变量里修改：

- 动态发布密码：修改 `BLOG_DYNAMIC_POST_PASSWORD`
- 日记密码：修改 `BLOG_DYNAMIC_DIARY_PASSWORD`

如果用 systemd 部署，通常是在服务器上的 `/etc/blog-dynamic.env` 中改这两个值；修改后重启动态服务。如果只是改 `PUBLIC_DYNAMIC_API_BASE`，需要重新运行 GitHub Actions 部署静态站。

当前可迁移部署默认关系是：

```text
blog.20050619.xyz       -> GitHub Pages 静态博客
activity.20050619.xyz   -> 私人服务器公网 IP 上的动态服务
PUBLIC_DYNAMIC_API_BASE -> https://activity.20050619.xyz
```

服务器侧由 `/etc/blog-dynamic.env` 控制运行参数，Cloudflare 负责把 `activity` 子域名解析到服务器公网 IP。动态图片会存放在 `/var/lib/blog-dynamic/uploads/`。以后迁移服务器时，只需要迁移 `/etc/blog-dynamic.env` 和整个 `/var/lib/blog-dynamic`，再把 `activity` 的 DNS 指到新公网 IP；如果动态服务公开域名不变，GitHub Actions Variable 不需要改。

如果修改了 `server/index.mjs`、动态图片处理、编辑/删除接口或 Docker 配置，需要在服务器的 `/opt/blog-project/server` 目录执行 `sudo docker compose up -d --build` 重建容器；只改前端页面时，则重新触发 GitHub Actions 部署静态站。

如果暂时不配置这些变量，博客仍能作为纯静态站点正常访问，只是不显示访问量，动态页面不会读取服务器数据；连续点击小人 20 次仍会打开日记密码框，但会提示动态服务地址还没有配置。

图片资源放在 `public/images/`：

- `site-icon.png`：网页图标。
- `blog-avatar.png`：博客个人头像。
- `banner/blog.png`：博客页主题 Banner。
- `banner/tags.png`：标签页和标签详情页主题 Banner。
- `banner/archive.png`：归档页主题 Banner。
- `banner/search.png`：搜索页主题 Banner。
- `banner/about.png`：关于页主题 Banner。
- `banner/dynamic.jpg`：动态页主题 Banner，由项目根目录本轮新增的 `banner.jpg` 复制到公开资源目录。
- `video-mascot/look/`：从 `生成指定动作视频 (3).mp4` 中重新抽取的视线方向帧，用于根据鼠标位置切换小人朝向；左右命名按网页鼠标方向修正，右向帧由左向真实帧镜像生成。
- `video-mascot/look-angle/`：每 10° 一张的 36 张方向细分帧。现在优先从 `生成指定动作视频 (3).mp4` 的连续视线段抽取稳定真实帧，缺少的右侧对称角度使用真实帧镜像生成，不使用透明叠加、权重混合或插值补帧。生成脚本会输出审查表，记录每张角度帧的源帧号和是否镜像。
- `video-mascot/blink/`：从视频闭眼段抽取并贴回正面身体轮廓的眨眼帧，实际网页只在正面闲置、没有方向过渡时播放，避免眨眼闪烁或突然跳帧。
- `video-mascot/wave/`：从视频挥手段抽取的 8 个实帧，用于点击或显示时的挥手动作。点击一次只播放一次正向伸手/挥手序列，结束后回到正面帧。
- `scripts/process_video_mascot.py`：使用 `uv` 虚拟环境中的 `imageio`、`imageio-ffmpeg`、`numpy` 和 Pillow 从本地 `生成指定动作视频 (3).mp4` 抽帧；通过绿色优势色键、主体连通域保留、肤色/服饰保护、边缘反混色、去绿边和 alpha 柔化生成透明 PNG，再统一到 `860x680` 画布和同一底部基线。
- 重新处理视频帧前，先运行 `uv pip install pillow imageio imageio-ffmpeg numpy`，再运行 `uv run python scripts/process_video_mascot.py`。
- 所有动作帧统一为同一画布和同一底部基线，避免动作之间忽大忽小；前端组件也使用同一宽高比。为减少首屏加载压力，组件会先加载基础朝向帧，再延迟预加载其他动作帧。由于透明画布顶部留白较多，页面只在显示层裁掉顶部空白，让提示气泡更贴近可见人物，动作帧文件本身不改变。
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

## 为什么公开博客本体不部署到服务器

公开博客是静态站点，GitHub Pages 已经可以托管 HTML、CSS、JS 和图片，不需要服务器长期运行。

独立服务器只用于动态服务，例如访问量统计、公开动态发布和私密日记管理。公开博客本体仍不部署到服务器，也不把后端代码混入 GitHub Pages 构建产物。

推荐使用独立 API 子域名指向动态服务，例如：

```text
https://activity.20050619.xyz -> http://127.0.0.1:8787
```

真实 DNS、HTTPS 和反向代理配置需要在 Cloudflare、服务器或控制台中完成，并以本地配置和用户最终确认为准。如果 Cloudflare 代理阻止了 Let's Encrypt HTTP-01 验证，可以临时或长期改用服务器 origin TLS：在服务器环境里设置 `BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS=1`，脚本会在服务器本机生成 origin 证书并开启 443 回源；Cloudflare 需要使用 Full 模式。Full strict 模式应改用 Let's Encrypt、Cloudflare Origin CA 或手动配置受信任证书。nginx 默认启用 TLS 1.2/1.3，但不强制 `ssl_ecdh_curve`；除非明确知道源站握手需要，否则保持 `BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE` 为空。

如果源站本机健康检查正常，但公网带 `activity.20050619.xyz` 的 HTTPS 回源仍返回 525 或被上游备案策略拦截，推荐使用 Cloudflare Tunnel。Docker 部署支持启用 `cloudflared` 容器：把 Tunnel token 放到服务器 `/etc/blog-dynamic-cloudflared.token`，设置 `BLOG_DYNAMIC_CLOUDFLARED_ENABLE=1` 后重新运行 `server/bootstrap-docker.sh`。Cloudflare Tunnel 公共主机名应指向 `http://127.0.0.1:8787`。真实 Tunnel token 不要写入仓库。

## 不要提交的文件

不要把以下内容提交到仓库：

- 服务器登录名、密码、公网 IP 和密码组合
- SSH 私钥
- Cloudflare API Token
- GitHub Token
- 包含真实密钥的 `.env`
- 数据库文件
- 私密日记内容
- 本地服务器登录信息
- `server/.data/` 本地测试数据
- `相关配置信息.txt`

`.gitignore` 已经包含这些常见敏感文件规则，但仍需要在提交前人工确认没有泄露信息。
