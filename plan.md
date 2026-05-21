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

## 当前维护提示

- [ ] 后续如果要重新生成当前小人帧，继续使用本地 `生成指定动作视频 (3).mp4` 和 `scripts/process_video_mascot.py`
