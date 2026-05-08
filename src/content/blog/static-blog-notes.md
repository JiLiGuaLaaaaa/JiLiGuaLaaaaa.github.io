---
title: "为什么先做静态博客"
description: "记录当前公开博客选择 Astro、GitHub Pages 和 Cloudflare 的原因。"
pubDate: 2026-05-08
tags:
  - Astro
  - 静态博客
  - 部署
draft: false
---

静态博客的好处是维护成本低，公开页面不需要服务器、数据库或后台登录系统。

当前站点的公开页面会由 Astro 构建成静态文件，再通过 GitHub Pages 发布。Cloudflare 负责自定义域名、HTTPS 和前置保护。

这样做的边界也很清楚：公开博客不连接 ECS，不保存数据库，不包含私密日记内容。未来动态服务可以独立扩展。
