# Plan

## 已完成的关键阶段

- [x] 建立 Astro + TypeScript + Markdown/MDX 静态博客基础结构
- [x] 配置站点信息、内容集合、示例文章、中文 README 和安全忽略规则
- [x] 实现首页、博客列表、文章详情、关于、标签、归档、搜索和 404 页面
- [x] 实现暗色模式、RSS、sitemap、robots.txt、CNAME 和 GitHub Pages Actions 部署流程
- [x] 修复 GitHub Pages 误用 Jekyll 构建 `.astro` 文件的问题，并补充 `.nojekyll`
- [x] 完成二次元小人从早期 SVG/图片方案到视频帧方案的迁移
- [x] 使用 `生成指定动作视频 (3).mp4` 生成当前主用 `public/images/video-mascot/` 动作帧
- [x] 完成小人交互：鼠标方向跟随、多角度方向帧、空闲眨眼、点击单次挥手、拖动、隐藏/显示、移动端隐藏和预加载防闪烁
- [x] 确认当前小人动作设计满意，后续只调整布局、播放、防闪烁和文案，不重做动作帧
- [x] 迁移视觉到接近 `uxiaohan/vhAstro-Theme` 的卡片、资料卡、两列布局和柔和 Banner 风格
- [x] 保留静态架构，不接入评论、统计、音乐、后端 API、数据库、Docker 或 ECS
- [x] 使用 `public/images/site-bg.jpg` 作为全站背景，并调整焦点优先展示人物头部
- [x] 使用 `public/images/site-icon.png` 作为网页图标，`public/images/blog-avatar.png` 作为博客头像
- [x] 根据 `question.md` 回答保留公开 QQ，不新增分类、不显示评论占位，不加入友链/动态/留言板
- [x] 完成最近 UI 调整：删除博客页顶部说明文案、页脚徽章合并为两组、资料卡改为热门标签导航

## 本次工程整理

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和相关资源说明
- [x] 更新工程整理、删除无用文件和精简文档需求
- [x] 盘点当前代码引用和资源引用，确认旧版小人资源、旧脚本、审查图、预览图和根目录重复素材不再参与运行
- [x] 删除确认不再使用的旧素材、旧小人帧、旧 refine 脚本、审查/预览产物和根目录重复素材
- [x] 修复小人气泡文案数组中缺失逗号的语法问题，保留用户新增文案
- [x] 精简 `plan.md`，保留关键历史记录和当前 TODO
- [x] 精简 `requirements.md`，保留长期有效规则
- [x] 更新 README 和 `public/images/README.md` 中的资源说明
- [x] 运行可用检查并记录结果（`tsc --noEmit`、`git diff --check`、`corepack pnpm install --frozen-lockfile`、敏感词扫描通过；`corepack pnpm build` 在沙箱内仍因 `spawn EPERM` 失败，但沙箱外重跑已通过并生成 14 个页面）

## 本次背景微调

- [x] 更新背景右移需求
- [x] 调整全站背景焦点，减少个人名片对背景人物的遮挡
- [x] 运行可用检查并记录结果（`tsc --noEmit`、`git diff --check` 和敏感词扫描通过；`corepack pnpm build` 在沙箱内仍因 `spawn EPERM` 失败，但沙箱外重跑已通过并生成 17 个页面）

## 本次首页、移动端和首屏性能调整

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和相关首页/布局/小人组件文件
- [x] 进一步调整全站背景人物位置，减少与右侧个人名片的重叠，并记录前后大致区域
- [x] 将首页首屏改为直接展示博客文章列表，移除不必要的大 Banner、公告卡和最新文章推荐区
- [x] 让文章卡片整卡可点击，同时保留标签链接的单独点击能力
- [x] 压缩移动端顶部导航高度，让主题切换按钮与导航区域更紧凑
- [x] 优化首屏加载，减少背景固定绘制成本和小人动作帧首屏全量预加载
- [x] 更新 README 说明本次交互、首页和性能调整
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；敏感文件跟踪检查通过；`corepack pnpm build` 在当前沙箱仍因 Astro/Vite `spawn EPERM` 失败，沙箱外重跑申请被自动审批系统拒绝，未能在本轮完成构建验证）

## 本次博客入口、渐变背景和主题 Banner 调整

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和相关页面/布局文件
- [x] 将根路径 `/` 改为直接跳转博客页，移除单独主界面内容维护
- [x] 将博客页面背景改为基础柔和渐变，不再使用全站背景图
- [x] 整理 `banner/` 图片，按主题重命名并迁移到公开资源目录
- [x] 为博客、标签、归档、搜索、关于页面接入对应主题 Banner 图片
- [x] 实现滚动后 Banner 流畅收起，保证正文能完整展示
- [x] 更新 README 说明当前入口、背景和 Banner 资源规则
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；Banner 资源和旧主界面引用检查通过；`corepack pnpm build` 在当前沙箱仍因 Astro/Vite `spawn EPERM` 失败，沙箱外重跑申请被自动审批系统拒绝，未能在本轮完成构建验证）

## 本次 Banner 填充和收起修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和相关 Banner 页面/样式/脚本文件
- [x] 修复部分分类或标签页面 Banner 无法收起的问题
- [x] 调整 Banner 展示方式，让背景填满容器，同时保留人物完整可见
- [x] 更新 README 说明 Banner 展示和脚本机制
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；Banner 双层图片和全站脚本导入检查通过；`corepack pnpm build` 在当前沙箱仍因 Astro/Vite `spawn EPERM` 失败，沙箱外重跑申请被自动审批系统拒绝，未能在本轮完成构建验证）

## 本次 GitHub Actions 构建修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和相关布局/脚本文件
- [x] 修复 Banner 收起脚本在服务端构建阶段访问 `document` 的问题
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；确认已移除 `@/scripts/collapsible-banner` 服务端导入；`corepack pnpm build` 在当前本地沙箱仍因 Astro/Vite `spawn EPERM` 失败，无法在本地沙箱完成完整构建验证）

## 本次 Banner 图片替换

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和当前 Banner 资源
- [x] 用根目录新放入的 5 张 Banner 图片替换现有主题 Banner
- [x] 更新 README 和资源说明中的 Banner 文件名
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；旧 `.jpg` 与根目录 `banner1-5.png` 引用扫描无命中；`corepack pnpm build` 在当前本地沙箱仍因 Astro/Vite `spawn EPERM` 失败，沙箱外重跑申请被自动审批系统拒绝，未能在本轮完成完整构建验证）

## 本次短内容滚动和顶部栏收起

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和相关布局/样式文件
- [x] 增加短内容页面的可滚动空白，保证 Banner 总能收起
- [x] 实现顶部导航栏下滑收起、上滑显示
- [x] 更新 README 中的交互说明
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；源码和文档资源引用扫描未发现旧 `.jpg` Banner、根目录 `banner1-5.png` 或旧服务端 Banner 脚本引用；`corepack pnpm build` 在当前本地沙箱仍因 Astro/Vite `spawn EPERM` 失败，未能在本地沙箱完成完整构建验证）

## 本次 Banner 前景铺满优化

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和 Banner 样式文件
- [x] 调整 Banner 前景图片，让其在人物完整可见前提下尽可能占满 Banner
- [x] 更新 README 中的 Banner 展示说明
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；Banner 样式和旧 `.jpg` 引用扫描通过；`corepack pnpm build` 在当前本地沙箱仍因 Astro/Vite `spawn EPERM` 失败，未能在本地沙箱完成完整构建验证）

## 本次 Banner5 替换和融合优化

- [x] 阅读 `requirements.md`、`plan.md`、`README.md`、Banner 样式和当前 Banner 资源
- [x] 用根目录新的 `banner5.png` 替换关于页 Banner
- [x] 调整 Banner 图片填充和前景/模糊背景融合过渡
- [x] 更新 README 中的 Banner 展示说明
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；根目录 `banner5.png` 已清理，`public/images/banner/about.png` 已替换为新 `3904x1088` 图片；Banner 样式和旧 `.jpg` 引用扫描通过；`corepack pnpm build` 在当前本地沙箱仍因 Astro/Vite `spawn EPERM` 失败，未能在本地沙箱完成完整构建验证）

## 本次 Banner 边界和底部导航修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md`、Banner 样式和顶部导航脚本
- [x] 优化 Banner 前景/背景边界，减少浅色模式发灰和硬边
- [x] 修复滚动到底部时顶部导航栏误弹出的问题
- [x] 更新 README 中的 Banner 和导航说明
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；Banner 融合样式、浅色清晰度参数和底部导航状态逻辑扫描通过；`corepack pnpm build` 在当前本地沙箱仍因 Astro/Vite `spawn EPERM` 失败，未能在本地沙箱完成完整构建验证）

## 本次移动端 Banner 填充优化

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和当前 Banner 样式
- [x] 只调整移动端 Banner 填充策略，保持电脑版效果不变
- [x] 更新 README 中的移动端 Banner 说明
- [x] 运行可用检查并记录结果（`tsc --noEmit` 和 `git diff --check` 通过；移动端 Banner 专用样式和旧 `.jpg` 引用扫描通过；`corepack pnpm build` 在当前本地沙箱仍因 Astro/Vite `spawn EPERM` 失败，未能在本地沙箱完成完整构建验证）

## 当前维护提示

- [ ] 后续如果要重新生成当前小人帧，继续使用本地 `生成指定动作视频 (3).mp4` 和 `scripts/process_video_mascot.py`

## 本次动态服务 HTTPS 正式修复

- [x] 复核当前计划、部署脚本和动态服务错误链路，确认根因是动态 API 子域 HTTPS 不通，而不是前端把动态服务地址写错
- [x] 补强 `server/bootstrap-docker.sh`，支持识别 Let's Encrypt 证书、用 certbot 自动申请证书、生成 nginx 443 反向代理，并保留 Docker 容器只监听本机端口的部署模式
- [x] 补强 `server/bootstrap-linux.sh`，让非 Docker 备用部署路径也支持同一套 HTTPS 证书变量和 nginx 443 配置
- [x] 更新部署文档、示例环境变量和 nginx 示例，写清 HTTPS 必须打通以及 `BLOG_DYNAMIC_LETSENCRYPT_EMAIL` / `BLOG_DYNAMIC_SSL_CERT_PATH` / `BLOG_DYNAMIC_SSL_KEY_PATH` 的用法
- [x] 运行本地语法、构建和敏感信息检查
- [x] 补齐 Cloudflare 代理场景下的服务器 origin TLS 兜底变量和文档说明，并明确自签 origin TLS 需要用户批准安全取舍后才能远程启用
- [x] 确认 TLS 策略：用户已批准自签 origin TLS + Cloudflare Full 模式继续部署
- [ ] 将修复后的部署脚本同步到独立动态服务服务器并重新部署
- [ ] 验证 `https://activity.20050619.xyz/health` 和 `https://activity.20050619.xyz/api/dynamics?limit=1` 可以正常访问

## 本次动态功能改造

- [x] 在 `AGENTS.md` 写入本次动态功能改造的重点规则：敏感信息不入库、公开博客继续静态、动态能力独立部署到独立服务器、每完成一步重新阅读 `plan.md`
- [x] 更新 `requirements.md`，记录本次新增需求：连续点击小人进入写日记、分享个人生活记录、访问量统计、域名与独立动态服务拆分、安全和隐私边界
- [x] 检查仓库结构、现有前端入口、小人组件、搜索/布局/配置文件、`.gitignore` 和本地配置文件状态，确认实现边界，不展示敏感内容
- [x] 设计动态服务方案：API 路由、数据存储、认证方式、CORS、部署路径、环境变量、反向代理和域名子域拆分；如发现认证或域名用途无法确认，立即询问用户
- [x] 实现动态服务代码骨架，只提交源码、假占位 `.env.example` 和部署脚本，不提交真实密钥、真实数据库、真实日记或访问日志
- [x] 实现访问量统计 API 与博客前端展示逻辑，保证静态博客在 API 不可用时仍可正常显示
- [x] 实现个人生活记录的公开展示与管理 API 约定，明确公开记录和私密草稿边界，不把私密内容写入 GitHub Pages
- [x] 实现连续点击小人多次后的写日记入口交互，并接入受保护的动态服务入口；确保入口不是认证边界
- [x] 增加域名、独立服务器、反向代理和服务部署配置说明，文档中只使用占位符，不写真实服务器信息
- [x] 更新 README，说明新架构、动态功能使用方式、部署方式、安全注意事项和仍需人工确认的域名/DNS/服务器步骤
- [x] 运行可用检查：类型检查、构建或可替代构建检查、敏感信息扫描、资源引用扫描，并记录无法在沙箱完成的原因
- [x] 从头到尾复核 `plan.md`、`requirements.md`、`README.md`、`.gitignore` 和本轮变更，确认没有泄露敏感信息，再更新本轮计划完成状态

## 本次动态发布与日记升级

- [x] 将公开页面的“生活记录”改成“动态”，并把前端入口、文案和路由统一为动态命名
- [x] 实现动态发布页，支持像 QQ 空间说说一样直接发布公开动态，并通过密码确认
- [x] 实现日记入口升级：早期版本已支持连续点击小人 20 次后进入密码确认，再进入日记编辑环节；本轮已进一步改为 8 秒触发窗口
- [x] 把动态服务 API 扩展为动态发布、动态列表、日记验证和日记写入，保留兼容别名但以动态为主
- [x] 更新 README、部署说明和环境变量说明，写清楚动态发布密码、日记密码和默认子域名接入方式
- [x] 运行类型检查、构建、资源引用和敏感信息检查，并确认静态站在无后端配置时仍能降级运行

## 本次动态入口体验修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和动态/日记相关源码，确认当前问题来自前端交互和动态服务地址未注入
- [x] 修复连续点击小人 20 次后不弹日记密码框的问题，确保服务地址缺失时也能打开弹窗并显示明确提示；本轮触发窗口已改为 8 秒
- [x] 调整动态发布页，去掉“心情”，并把发布密码改为点击发布后弹窗输入
- [x] 让 GitHub Actions 构建显式读取 `PUBLIC_DYNAMIC_API_BASE`，避免线上静态页面无法拿到动态服务地址
- [x] 更新 README 和相关部署说明，写清楚动态服务地址、动态发布密码和日记密码分别在哪里改
- [x] 运行类型检查、构建/语法检查和敏感信息检查，并复核本轮变更没有写入真实密钥或服务器信息

## 本次私人服务器可迁移部署

- [x] 读取 `requirements.md`、`plan.md`、`README.md` 和现有动态服务部署模板，确认旧文档偏 ECS 且当前登录信息是密码式服务器信息
- [x] 增加 Linux 服务器一键部署脚本，支持私人小电脑、ECS 或未来其他服务器，避免把真实服务器配置写入仓库
- [x] 根据首次远程部署中暴露的 Node.js 包安装风险，增强部署脚本：优先使用可移植 Node.js，支持 `/opt/blog-node`、`BLOG_DYNAMIC_NODE_DIR` 和 `BLOG_DYNAMIC_NODE_VERSION`，并在 apt/dpkg 半坏状态下先尝试修复
- [x] 增加 Docker / Docker Compose 部署路径，容器内只跑动态服务，宿主机继续负责 nginx 或其他反向代理
- [x] 更新动态服务文档，把“ECS 专用”改为“独立动态服务服务器”，并说明迁移时只需迁移环境文件和数据目录
- [x] 更新 README 中的动态服务部署说明，明确 `activity.20050619.xyz`、Cloudflare、GitHub Actions Variable 和服务器环境变量的关系
- [x] 使用本地配置文件中的登录信息连接私人服务器并执行 Docker 动态服务部署，不在日志和文档中输出真实信息（已完成 SSH 连接、上传、Docker Compose 启动、容器运行检查、本机 health 检查和 nginx 配置检查）
- [x] 重新运行部署脚本修改后的检查、服务端语法检查和敏感信息扫描，确认没有提交真实 IP、账号、密码、Token 或证书私钥；本机未安装 Docker CLI，Compose 结构已通过远端实际 Docker 部署、容器 health 和 nginx 配置检查验证

## 本次动态图片与日记本体验升级

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和动态/日记/服务端相关源码，确认本轮 6 项新增需求和安全边界
- [x] 更新 `requirements.md` 和 `plan.md`，记录动态图片、笔图标入口、日记弹窗、动态展开、日记本搜索和 8 秒触发条件
- [x] 完善动态发布与展示：笔图标入口、密码后编辑、拖拽/选择图片、图片预览、发布到动态服务、短内容完整展示和长内容展开/收起
- [x] 完善日记入口与日记本：8 秒内 20 次触发、弹窗不因点击外部关闭、密码后显示日记本、搜索标题/内容、新建日记入口
- [x] 完善服务端和部署配置：动态图片存储、上传静态读取、日记搜索接口、Docker/nginx 上传大小限制与可移植配置
- [x] 更新 README、部署说明和服务器操作说明，写清楚本次新增功能和部署后的注意事项，不写入真实密钥或服务器信息
- [x] 运行本地可用检查：服务端语法、Astro/TypeScript 构建检查、`git diff --check`、敏感信息扫描；沙箱内 Astro 检查仍会因环境权限触发 `spawn EPERM`，沙箱外同命令和完整构建已通过
- [x] 把服务端变更重新部署到独立动态服务服务器；已通过本地 txt 中的 SSH 登录信息完成 Docker 部署、容器重建、nginx 配置更新与脚本内健康检查
- [x] 从头到尾复核 `plan.md`、`requirements.md`、`README.md` 和本轮 diff，确认功能与安全边界后汇报

## 本次 Cloudflare 525 继续修复

- [x] 重新读取 `plan.md` 并确认当前未完成项
- [x] 使用本地 txt 中的 SSH 信息连接独立动态服务服务器，检查 Docker、nginx、TLS、端口监听和本机健康检查
- [x] 从服务器侧验证公网域名和源站地址的 HTTP/HTTPS 回源效果，区分代码问题、nginx 问题和 Cloudflare 回源问题
- [x] 如源站配置不一致，重新同步部署脚本并重建 Docker/nginx/TLS 配置
- [x] 增加 Cloudflare 支持的备用 HTTPS 端口监听，并验证是否可绕开源站 80/443 拦截（结论：源站本机可用，但公网备用端口没有到达源站，不能绕开当前回源问题）
- [x] Cloudflare Tunnel 生效后验证 `https://activity.20050619.xyz/health` 和 `https://activity.20050619.xyz/api/dynamics?limit=1` 均返回 200
- [x] 运行本地语法/差异检查，并复核没有泄露敏感信息

## 本次 Cloudflare Tunnel 正式接入修复

- [x] 继续复查公网 443：源站本机 nginx/TLS 正常，公网 IP + Host 可访问，但公网域名 SNI 会触发 525/ICP 拦截，确认继续改 nginx 证书不能根治
- [x] 为 Docker 部署增加 Cloudflare Tunnel 可选 profile、token-file 和文档说明，保持服务器迁移时只迁移环境文件、数据目录和 tunnel token
- [x] 将 Cloudflare Tunnel 支持同步到独立动态服务服务器；当前服务器没有 Tunnel token，已完成服务端待命配置，未伪造公网部署成功
- [x] 用户已在 Cloudflare Zero Trust 创建 `blog-dynamic` Tunnel，安装 `cloudflared` connector，配置 `activity.20050619.xyz -> http://127.0.0.1:8787`，公网 `https://activity.20050619.xyz/health` 已返回 200
- [x] 运行本地语法/差异检查，并复核没有泄露敏感信息

## 本次动态服务回归修复

- [x] 重新阅读 `plan.md`，确认当前失败发生在“动态图片与日记本体验升级”之后，优先按部署回归处理
- [x] 复核前端 `PUBLIC_DYNAMIC_API_BASE`、动态/日记请求路径、服务端接口和 Docker/nginx 部署脚本，确认最小修复点
- [x] 修正部署脚本的默认行为：保留新版动态/日记/图片功能，但避免默认强制切换到复杂 HTTPS/Tunnel 链路
- [x] 使用本地授权的 SSH 信息同步并重新部署到私人动态服务服务器，不输出真实 IP、账号、密码、token 或证书内容
- [x] 验证服务器本机 API、nginx 反代和公网 `activity` 域名可访问；公网动态列表 API 已返回 200
- [x] 用户已在网页端验证动态发布、日记功能和图片上传均恢复正常
- [x] 运行本地语法/差异/敏感信息检查，重新从头到尾复核 `plan.md` 后汇报

## 本次回归修复当前结果

- [x] 已同步修复后的 Docker/nginx 部署脚本到私人动态服务服务器，并完成容器重建和 nginx reload
- [x] 已验证服务器本机动态服务正常：`/health`、`/api/dynamics?limit=1`、日记鉴权和上传静态读取路径均按预期响应
- [x] 已将源站 nginx HTTPS 配置调整为 Cloudflare 兼容的 TLS 1.2/1.3 与常见 ECDH 曲线，并重新部署到服务器
- [x] 已用带唯一标记的公网请求和源站日志确认：公网 525 请求没有以正常 HTTP 请求形式进入 nginx 访问日志
- [x] 已抓包确认公网请求会触达服务器 443，但在 TLS/入口层被重置；备用 HTTPS 端口 8443/2053 仍返回 522
- [x] Cloudflare Tunnel 生效后，公网 `https://activity.20050619.xyz/health` 已返回 200；原 525/ICP 拦截入口已绕开

## 本次公网入口与源站 TLS 回归修复

- [x] 重新阅读 `plan.md`，继续按“我改动部署后造成回归”的方向处理，不把动态服务未部署作为原因
- [x] 修复部署模板：nginx 默认启用 TLS 1.2/1.3，但不再写死 `ssl_ecdh_curve`；新增 `BLOG_DYNAMIC_NGINX_SSL_PROTOCOLS` 和 `BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE` 便于迁移时显式控制
- [x] 同步并重新部署到私人动态服务服务器，确认容器、nginx 语法、本机 `/health` 和源站强制解析 HTTPS 均返回 200
- [x] 验证 `activity` 公开域名现状：HTTPS 仍返回 525；HTTP ACME 测试公开返回备案/上游策略拦截页；抓包显示公网请求到达 443 后在 TLS 入口层被重置，未形成正常 nginx 访问日志
- [x] 根据用户截图确认：Cloudflare 的 `activity` A 记录和 GitHub `PUBLIC_DYNAMIC_API_BASE=https://activity.20050619.xyz` 配置方向正确，不再要求用户重复修改这两处
- [x] 用户已在网页端验证源站链路上的动态发布、日记会话、日记读取和图片上传/读取能力正常
- [x] 运行本地语法/差异/敏感信息检查：`node --check server/index.mjs` 和 `git diff --check` 通过；敏感信息扫描未发现真实密钥，只有占位符和本机回环地址；`corepack pnpm build` 仍因 Astro/Vite `spawn EPERM` 失败；Git Bash `bash -n` 在当前 Windows 沙箱因 MSYS 权限错误无法执行
- [x] 远端接口级验证本轮被 SSH 执行审批层拦截，未再次连接服务器；随后用户通过网页端实际验证动态、日记和图片上传功能均正常
- [x] 重新从头到尾复核 `plan.md` 后汇报

## 本次动态与日记管理、检索和性能升级

- [x] 阅读 `requirements.md`、`plan.md` 和动态/日记/服务端相关源码，确认本轮 13 项新增需求和安全边界
- [x] 更新 `requirements.md` 和 `plan.md`，记录动态分界线、时间位置、正方形缩略图、检索、管理、日记编辑删除、长内容展开、性能和新动态 Banner 需求
- [x] 完善服务端接口：动态/日记按关键字和日期筛选，动态/日记编辑与删除，日记标题可为空，管理接口继续要求会话或管理 Token
- [x] 完善动态展示：去掉无标题时的“动态”占位，增加清晰分界线，右下角蓝色小时间，正方形透明补齐缩略图和原图查看
- [x] 完善动态检索与管理入口：右上角笔图标密码确认后进入管理视图，支持发布、编辑、删除动态，并避免编辑输入时重绘列表
- [x] 完善日记本体验：日期跨度检索、编辑、删除、清晰分界线、无标题不显示占位、长正文自动换行和查看更多/收起
- [x] 使用根目录 `banner.jpg` 作为动态页 Banner 的公开资源，并更新动态页引用
- [x] 更新 README、动态服务文档和服务器操作说明，写清新增功能和部署注意事项，不写入真实密钥或服务器信息
- [x] 运行本地可用检查：服务端语法、Astro/TypeScript 构建或可替代检查、`git diff --check`、敏感信息扫描；沙箱内 Astro 构建起初因 `spawn EPERM` 失败，沙箱外完整 `corepack pnpm build` 已通过
- [x] 从头到尾复核 `plan.md`、`requirements.md`、`README.md` 和本轮 diff，确认功能与安全边界后汇报

## 本次服务器 Docker 启动兼容修复

- [x] 重新阅读 `requirements.md`、`plan.md`、README 和服务器部署说明，确认当前失败来自服务器缺少 Docker Compose v2 和旧 `docker-compose` 重建兼容问题
- [x] 更新部署文档和操作说明，补充旧 `docker-compose` 服务器的正确更新方式，不再只提示 `docker compose`
- [x] 通过 SSH 连接私人动态服务服务器，检查当前 `blog-dynamic` 容器和镜像状态
- [x] 修复 Docker 原生命令读取带引号 env 文件导致 `BLOG_DYNAMIC_PUBLIC_BASE_URL` 解析失败的问题
- [x] 在不删除 `/var/lib/blog-dynamic` 数据的前提下重建或重新创建 `blog-dynamic` 容器
- [x] 验证本机 `/health`、公网 `/health` 和公网动态列表接口返回正常
- [x] 从头到尾复核 `plan.md`、`requirements.md`、README 和本轮 diff 后汇报

## 本次动态与日记展示回归修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和动态/日记组件源码，确认当前回归集中在运行时插入 DOM 的样式命中、展开收起和管理按钮误触
- [x] 更新 `requirements.md` 和 `plan.md`，记录本轮动态/日记展示、滚动和管理模式修复需求
- [x] 修复动态列表展示：运行时条目全局样式、清晰分界线、右下角蓝色小时间、正方形不裁切缩略图、正文自动换行和查看更多/收起
- [x] 修复动态管理弹窗：列表可滚动、默认隐藏编辑删除按钮、点击管理后才进入编辑删除模式
- [x] 修复日记本展示：运行时条目全局样式、清晰分界线、正文自动换行和查看更多/收起
- [x] 修复日记管理交互：默认隐藏编辑删除按钮、点击管理后才进入编辑删除模式
- [x] 更新 README，写清动态和日记管理模式与展示修复后的行为
- [x] 运行本地可用检查：TypeScript/Astro 检查或构建、`git diff --check`、敏感信息扫描
- [x] 从头到尾复核 `plan.md`、`requirements.md`、`README.md` 和本轮 diff 后汇报

## 本次动态编辑弹窗滚动修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和动态组件源码，并定位用户提到的 `演示视频4.mp4`
- [x] 更新 `requirements.md` 和 `plan.md`，记录动态管理 / 编辑弹窗必须能上下滚动的修复要求
- [x] 修复 `DynamicFeed.astro` 中动态管理 / 编辑弹窗的滚动容器和编辑定位逻辑
- [x] 更新 README，补充动态管理弹窗滚动和编辑定位行为
- [x] 运行本地可用检查：Astro/TypeScript 构建或可替代检查、`git diff --check`、敏感信息扫描
- [x] 从头到尾复核 `plan.md`、`requirements.md`、`README.md` 和本轮 diff 后汇报

## 本次动态管理弹窗顶部操作栏修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和动态组件源码，确认截图中的问题是弹窗顶部操作栏被滚出视野且弹窗仍受外层动态面板影响
- [x] 更新 `requirements.md` 和 `plan.md`，记录动态管理弹窗必须脱离外层面板、内部滚动、顶部操作栏始终可点
- [x] 修复 `DynamicFeed.astro`：把动态弹窗挂到 `body` 下、改为面板内部滚动、移除会把顶部操作栏滚走的自动定位
- [x] 更新 README，补充动态管理弹窗顶部操作栏固定和内部滚动行为
- [x] 运行本地可用检查：Astro/TypeScript 构建或可替代检查、`git diff --check`、敏感信息扫描
- [x] 从头到尾复核 `plan.md`、`requirements.md`、`README.md` 和本轮 diff 后汇报

## 本次动态管理弹窗固定顶栏二次修复

- [x] 重新阅读 `AGENTS.md`、`requirements.md`、`plan.md`、`README.md` 和 `DynamicFeed.astro`，确认当前问题仍是动态管理弹窗滚动层和顶部操作栏交互没有彻底隔离
- [x] 更新 `requirements.md` 和 `plan.md`，记录顶部操作栏不能依赖 sticky、面板本身不滚动、内容区单独滚动和禁止自动聚焦挤走顶部按钮
- [x] 修复 `DynamicFeed.astro`：把管理弹窗改成固定面板、固定顶部操作栏和独立滚动内容区，并只重置内容区滚动位置
- [x] 更新 README，补充动态管理弹窗现在是固定顶部栏 + 内容区滚动的实现行为
- [x] 运行本地可用检查：Astro/TypeScript 构建或可替代检查、`git diff --check`、敏感信息扫描；沙箱内 `corepack pnpm build` 仍因 Astro/Vite `spawn EPERM` 失败，沙箱外同命令已通过并构建 19 个页面
- [x] 从头到尾复核 `plan.md`、`requirements.md`、`README.md` 和本轮 diff 后汇报
