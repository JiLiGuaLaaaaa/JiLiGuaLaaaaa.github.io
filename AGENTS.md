# AGENTS.md

## 1. 角色说明

你是本仓库的工程代理。

你的任务是帮助构建和维护一个个人静态博客。

当前项目目标是：

- 简单
- 安全
- 维护成本低
- 容易迁移
- 当前公开博客保持静态
- 未来动态服务可以单独扩展

本项目当前使用 Astro + GitHub Pages + Cloudflare。

阿里云 ECS 暂时只作为未来动态服务预留。

---

## 2. 必须先读的文件

在进行任何工程修改之前，必须完整阅读：

1. `requirements.md`
2. `plan.md`，如果存在
3. `README.md`，如果存在
4. 与当前任务相关的源代码文件

如果 `plan.md` 不存在，必须先创建 `plan.md`，再开始工程实现。

---

## 3. 需求管理规则

每当用户新增、删除、修改或澄清需求时，必须更新 `requirements.md`。

不要只修改代码。

以下情况都算需求变化：

- 新增页面
- 新增组件
- 修改网站设计
- 修改域名
- 修改部署方式
- 修改安全规则
- 新增或修改 RSS
- 新增或修改 sitemap
- 新增或修改标签
- 新增或修改归档
- 新增或修改搜索
- 新增或修改评论占位
- 新增或修改二次元小角色
- 涉及 ECS、Docker、Cloudflare、GitHub Pages、私密日记等任何架构变化

需求变化时必须按以下顺序处理：

1. 更新 `requirements.md`
2. 更新 `plan.md`
3. 实现代码
4. 必要时更新 README
5. 运行检查
6. 标记已完成的 plan 项

---

## 4. 计划管理规则

开始工程前，必须创建或更新 `plan.md`。

`plan.md` 必须使用 Markdown checkbox。

示例：

```md
# Plan

- [ ] 阅读 requirements.md
- [ ] 检查仓库结构
- [ ] 实现功能
- [ ] 更新文档
- [ ] 运行构建
```

每完成一个计划项，必须将其标记为 `[x]`。

示例：

```md
- [x] 阅读 requirements.md
```

每次开始新的计划项之前，都必须完整阅读一遍 `plan.md`。

这是强制要求。

不要在没有重新阅读 `plan.md` 的情况下继续下一项任务。

---

## 5. 执行流程规则

每个任务都应按以下流程执行：

1. 阅读 `requirements.md`
2. 完整阅读 `plan.md`
3. 找到下一个未完成任务
4. 只完成当前任务
5. 运行当前任务相关检查
6. 完成后把当前任务标记为 `[x]`
7. 开始下一项任务前，再次完整阅读 `plan.md`

不要提前标记未完成任务。

不要一次性随意勾选多个任务，除非这些任务确实已经全部完成。

---

## 6. 当前架构规则

公开博客必须保持静态。

当前公开博客技术栈：

- Astro
- TypeScript
- Markdown 或 MDX
- pnpm
- GitHub Actions
- GitHub Pages
- Cloudflare 自定义域名

公开博客不应依赖：

- 阿里云 ECS
- Docker
- Docker Compose
- 数据库
- 服务端运行时
- WordPress
- Ghost
- 后端 API

阿里云 ECS 只作为未来动态服务预留。

---

## 7. 网站信息

网站名称：

```text
辣子鸡丁砂锅
```

网站描述：

```text
这个人懒死了，什么介绍都没有
```

网站描述必须方便以后修改。

作者昵称：

```text
辣子鸡丁砂锅
```

博客语言：

```text
中文
```

用户可见文案默认使用简体中文。

---

## 8. 域名和仓库信息

博客域名：

```text
blog.20050619.xyz
```

GitHub 账号：

```text
JiLiGUaLaaaaa
```

GitHub 仓库：

```text
git@github.com:JiLiGuaLaaaaa/pilipala.github.io.git
```

GitHub Pages 目标域名：

```text
jiligualaaaaa.github.io
```

公开博客最终地址：

```text
https://blog.20050619.xyz
```

Cloudflare 中已经确认：

```text
blog CNAME jiligualaaaaa.github.io
```

不要硬编码无关域名。

---

## 9. 安全规则

永远不要提交密钥或敏感信息。

禁止提交：

- ECS root 密码
- ECS 登录凭据
- SSH 私钥
- Cloudflare API Token
- GitHub Token
- 包含真实密钥的 `.env`
- 数据库文件
- 私密日记内容
- 本地服务器登录信息文件

确保 `.gitignore` 至少包含：

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
```

如果发现仓库中存在敏感信息，应立即停止并明确报告。

不要把密钥复制进文档、注释、测试、示例或 README。

`.env.example` 只能使用假占位值。

---

## 10. 私密日记规则

私密日记内容绝不能包含在当前公开 Astro 静态站中。

不要创建这些公开路由：

```text
/diary
/private
/private-diary
```

除非用户明确确认这些内容是公开内容。

如果以后需要私密日记，应作为单独服务部署在 ECS 上，并加访问控制。

可接受的未来访问控制方式包括：

- Cloudflare Access
- Basic Auth
- 应用级登录
- VPN
- Tailscale
- WireGuard

---

## 11. 博客功能规则

本项目需要实现或预留：

- 暗色模式
- RSS
- sitemap
- robots.txt
- 标签
- 归档
- 搜索
- 评论占位
- 可爱的二次元鼠标跟随小角色

这些功能应优先使用静态或纯前端方案。

不要因为这些功能引入后端服务，除非用户明确修改架构需求。

---

## 12. URL 规则

博客文章路径必须使用：

```text
/blog/xxx/
```

不要使用：

```text
/posts/xxx/
```

除非用户之后明确要求修改。

---

## 13. 二次元小角色规则

需要实现一个可爱的二次元风格小角色。

要求：

- 纯前端实现
- 不需要后端
- 不需要数据库
- 不需要 ECS
- 不需要 Docker
- 可以部署在 GitHub Pages
- 默认显示在右下角附近
- 鼠标移动时，小角色的眼睛、头部或脸部跟随光标移动
- 不影响正文阅读
- 移动端可以隐藏或简化
- 尊重 `prefers-reduced-motion`

建议文件：

```text
src/components/CursorCharacter.astro
```

优先使用原创 SVG / CSS / JavaScript 实现。

如果使用第三方图片、模型或 Live2D 资源，必须确认许可证允许使用。

许可证不明确时，不要使用第三方资源。

---

## 14. 评论占位规则

当前只做评论占位，不实现真实评论系统。

要求：

- 方便以后接入真实评论服务
- 不连接 ECS
- 不连接数据库
- 不使用真实 API Key
- 不写入第三方评论服务密钥
- 不引入动态博客系统

可以使用类似文案：

```text
评论功能以后再加，现在先留个位置。
```

未来评论服务可能部署在：

```text
comment.20050619.xyz
```

---

## 15. 搜索规则

需要提供搜索功能或搜索入口。

优先使用静态搜索方案，例如 Pagefind。

不要为了搜索功能引入后端服务。

除非用户明确要求，否则不要使用服务器端搜索、数据库搜索或 ECS 搜索服务。

---

## 16. 部署规则

使用 GitHub Actions 部署到 GitHub Pages。

工作流文件建议路径：

```text
.github/workflows/deploy.yml
```

Astro 配置中的站点地址应使用：

```text
https://blog.20050619.xyz
```

公开博客不要使用 ECS 部署。

公开博客不要使用 Docker 部署。

---

## 17. Cloudflare 规则

Cloudflare 用于 DNS、自定义域名、HTTPS 和前置保护。

已经确认 DNS 记录：

```text
blog CNAME jiligualaaaaa.github.io
```

可以在 README 中用简单中文解释：

- CNAME 是什么
- 为什么需要指向 GitHub Pages
- 如何在 Cloudflare 中检查

不要在仓库中保存 Cloudflare 密钥。

---

## 18. 代码风格规则

优先使用：

- TypeScript
- Astro 组件
- 简单目录结构
- 少量依赖
- 清晰命名
- 可访问 HTML
- 响应式 CSS
- 良好中文排版
- 快速加载

避免不必要的复杂度。

不要加入大型框架或重依赖，除非确实需要。

不要在当前仓库中添加后端代码，除非用户明确修改架构。

---

## 19. 内容规则

博客文章使用 Markdown 或 MDX。

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

生产环境中，草稿文章不能被发布。

---

## 20. 文档规则

当行为、使用方式、部署方式、架构或需求发生变化时，必须更新 README。

README 应使用简单中文说明：

- 本项目是什么
- 如何本地运行
- 如何写文章
- 如何构建
- 如何部署
- GitHub Pages 如何配置
- Cloudflare DNS 如何配置
- CNAME 是什么
- RSS 是什么
- sitemap 是什么
- 标签是什么
- 归档是什么
- 搜索是什么
- 哪些文件不能提交
- 为什么当前公开博客不使用 ECS
- 未来如何把动态服务单独放到 ECS

---

## 21. 检查规则

完成任务前必须运行可用检查。

优先运行：

```bash
pnpm install
pnpm build
```

如果项目包含 lint：

```bash
pnpm lint
```

如果项目包含格式化命令：

```bash
pnpm format
```

只有命令成功后，才能把对应验证任务标记为完成。

如果命令失败，必须修复或明确说明失败原因。

---

## 22. Git 规则

修改前先检查仓库状态。

推荐命令：

```bash
git status
ls
```

不要覆盖用户已有修改。

不要随意删除文件。

除非 plan 中明确要求或用户明确要求，否则不要删除已有内容。

---

## 23. 完成汇报规则

完成任务后，需要汇报：

- 修改了什么
- 修改了哪些文件
- 完成了哪些 plan 项
- 运行了哪些检查
- 是否还有 TODO
- 是否有需要用户手动操作的地方

不要声称部署成功，除非确实已经验证。

不要声称 DNS 已生效，除非已经验证或用户确认。

---

## 24. 本次 ECS 动态功能改造重点

用户本次明确要求为博客增加动态能力，包括连续点击互动小人进入写日记、分享个人生活记录、查看访问量，以及配置域名和服务器相关内容。

执行本次任务时必须遵守：

- 公开博客继续由 GitHub Pages 托管，保持静态构建和静态部署。
- 动态能力只能作为独立服务部署到阿里云 ECS，不把后端运行时混入 GitHub Pages。
- 本地 `相关配置信息.txt` 只能用于理解服务器和域名条件，禁止把其中的服务器地址、账号、密码、Token、私钥或其他敏感信息写入仓库、文档、日志、示例或最终回复。
- 不要提交真实 `.env`、数据库文件、日记内容、访问日志或服务器登录信息。
- 仓库里只能提供 `.env.example` 这类假占位配置。
- 日记内容不得写入 `src/content/`、`public/`、`dist/` 或任何会被 GitHub Pages 发布的目录。
- 连续点击小人进入写日记只能作为入口交互，不能被当作真正的安全边界；写入日记必须经过服务端认证。
- 分享个人生活记录应区分公开记录和私密草稿；只有明确发布的公开记录可以被博客前端读取展示。
- 访问量统计只记录完成统计所需的最少信息，避免采集不必要的个人隐私。
- 域名配置优先使用子域名隔离静态站和动态服务，例如公开博客继续使用主博客域名，ECS API 使用单独 API 子域名；实际记录以本地配置和用户确认为准。
- 每完成 `plan.md` 中的一项任务后，必须重新从头到尾阅读一遍 `plan.md`，再继续下一项。
- 如遇到域名用途、日记公开范围、认证方式、部署权限等无法从本地文件确认的问题，必须立即询问用户，不要自行猜测。
