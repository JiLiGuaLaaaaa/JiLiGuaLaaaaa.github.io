ARG NODE_IMAGE=node:22-bookworm-slim
FROM ${NODE_IMAGE}

WORKDIR /app

ENV NODE_ENV=production \
    BLOG_DYNAMIC_HOST=0.0.0.0 \
    BLOG_DYNAMIC_PORT=8787 \
    BLOG_DYNAMIC_DATA_DIR=/var/lib/blog-dynamic

COPY index.mjs ./server/index.mjs

RUN mkdir -p /var/lib/blog-dynamic

EXPOSE 8787

CMD ["node", "server/index.mjs"]
