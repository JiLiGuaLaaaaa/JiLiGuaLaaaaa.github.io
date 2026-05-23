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
- [x] 实现日记入口升级：10 秒内连续点击小人 20 次后进入密码确认，再进入日记编辑环节
- [x] 把动态服务 API 扩展为动态发布、动态列表、日记验证和日记写入，保留兼容别名但以动态为主
- [x] 更新 README、部署说明和环境变量说明，写清楚动态发布密码、日记密码和默认子域名接入方式
- [x] 运行类型检查、构建、资源引用和敏感信息检查，并确认静态站在无后端配置时仍能降级运行

## 本次动态入口体验修复

- [x] 阅读 `requirements.md`、`plan.md`、`README.md` 和动态/日记相关源码，确认当前问题来自前端交互和动态服务地址未注入
- [x] 修复 10 秒内点击小人 20 次后不弹日记密码框的问题，确保服务地址缺失时也能打开弹窗并显示明确提示
- [x] 调整动态发布页，去掉“心情”，并把发布密码改为点击发布后弹窗输入
- [x] 让 GitHub Actions 构建显式读取 `PUBLIC_DYNAMIC_API_BASE`，避免线上静态页面无法拿到动态服务地址
- [x] 更新 README 和相关部署说明，写清楚动态服务地址、动态发布密码和日记密码分别在哪里改
- [x] 运行类型检查、构建/语法检查和敏感信息检查，并复核本轮变更没有写入真实密钥或服务器信息

## 本次私人服务器可迁移部署

- [x] 读取 `requirements.md`、`plan.md`、`README.md` 和现有动态服务部署模板，确认旧文档偏 ECS 且当前登录信息是密码式服务器信息
- [x] 增加 Linux 服务器一键部署脚本，支持私人小电脑、ECS 或未来其他服务器，避免把真实服务器配置写入仓库
- [x] 更新动态服务文档，把“ECS 专用”改为“独立动态服务服务器”，并说明迁移时只需迁移环境文件和数据目录
- [x] 更新 README 中的动态服务部署说明，明确 `activity.20050619.xyz`、Cloudflare、GitHub Actions Variable 和服务器环境变量的关系
- [ ] 使用本地配置文件中的登录信息连接私人服务器并执行动态服务部署，不在日志和文档中输出真实信息（本次远程修改被执行审批拦截，需用户明确授权后继续）
- [x] 运行脚本语法检查、服务端语法检查和敏感信息扫描，确认没有提交真实 IP、账号、密码、Token 或证书私钥
