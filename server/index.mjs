import { createServer } from "node:http";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { dirname, extname, join, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { randomBytes, timingSafeEqual } from "node:crypto";

const __dirname = dirname(fileURLToPath(import.meta.url));
const host = process.env.BLOG_DYNAMIC_HOST || "127.0.0.1";
const port = Number.parseInt(process.env.BLOG_DYNAMIC_PORT || "8787", 10);
const publicBaseUrl = process.env.BLOG_DYNAMIC_PUBLIC_BASE_URL || "";
const adminToken = process.env.BLOG_DYNAMIC_ADMIN_TOKEN || "";
const dynamicPostPassword = process.env.BLOG_DYNAMIC_POST_PASSWORD || "";
const diaryPassword = process.env.BLOG_DYNAMIC_DIARY_PASSWORD || "";
const dataDir = resolve(process.env.BLOG_DYNAMIC_DATA_DIR || join(__dirname, ".data"));
const allowedOrigins = new Set(
  (process.env.BLOG_DYNAMIC_ALLOWED_ORIGINS || "http://localhost:4321")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean)
);

const maxBodyBytes = 24 * 1024 * 1024;
const maxDynamicImages = 4;
const maxDynamicImageBytes = 3 * 1024 * 1024;
const diarySessionTtlMs = 30 * 60 * 1000;
const dynamicSessionTtlMs = 30 * 60 * 1000;
const diarySessions = new Map();
const dynamicSessions = new Map();

const files = {
  stats: join(dataDir, "stats.json"),
  dynamics: join(dataDir, "dynamic-records.json"),
  life: join(dataDir, "life-records.json"),
  diary: join(dataDir, "diary-entries.json"),
  uploads: join(dataDir, "uploads")
};

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store"
};

const htmlHeaders = {
  "Content-Type": "text/html; charset=utf-8",
  "Cache-Control": "no-store"
};

const uploadContentTypes = {
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".webp": "image/webp"
};

const dynamicImageTypes = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"]
]);

const defaultStats = () => ({
  total: 0,
  pages: {},
  updatedAt: new Date().toISOString()
});

const isPlaceholderToken = (value) =>
  !value || value === "replace-with-a-long-random-token" || value.length < 24;

const isPlaceholderPassword = (value) =>
  !value || value.startsWith("replace-with-") || value.length < 8;

const nowIso = () => new Date().toISOString();

const send = (response, status, body, headers = jsonHeaders) => {
  response.writeHead(status, headers);
  response.end(Buffer.isBuffer(body) ? body : typeof body === "string" ? body : JSON.stringify(body));
};

const sendJson = (response, status, body) => send(response, status, body);

const sendError = (response, status, message) => {
  sendJson(response, status, { ok: false, error: message });
};

const httpError = (status, message) => Object.assign(new Error(message), { status });

const getOrigin = (request) => request.headers.origin || "";

const applyCors = (request, response) => {
  const origin = getOrigin(request);
  if (origin && allowedOrigins.has(origin)) {
    response.setHeader("Access-Control-Allow-Origin", origin);
    response.setHeader("Vary", "Origin");
  }
  response.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type,Authorization");
};

const safeEqual = (a, b) => {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
};

const isAuthorized = (request) => {
  if (isPlaceholderToken(adminToken)) return false;
  const header = request.headers.authorization || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return Boolean(match && safeEqual(match[1], adminToken));
};

const requirePassword = (response, configuredPassword, suppliedPassword, name) => {
  if (isPlaceholderPassword(configuredPassword)) {
    sendError(response, 503, `${name} password is not configured.`);
    return false;
  }
  if (!safeEqual(String(suppliedPassword || ""), configuredPassword)) {
    sendError(response, 401, "Password is incorrect.");
    return false;
  }
  return true;
};

const cleanupDiarySessions = () => {
  const now = Date.now();
  for (const [token, expiresAt] of diarySessions.entries()) {
    if (expiresAt <= now) diarySessions.delete(token);
  }
};

const createDiarySession = () => {
  cleanupDiarySessions();
  const token = randomBytes(32).toString("base64url");
  const expiresAt = Date.now() + diarySessionTtlMs;
  diarySessions.set(token, expiresAt);
  return { token, expiresAt };
};

const cleanupDynamicSessions = () => {
  const now = Date.now();
  for (const [token, expiresAt] of dynamicSessions.entries()) {
    if (expiresAt <= now) dynamicSessions.delete(token);
  }
};

const createDynamicSession = () => {
  cleanupDynamicSessions();
  const token = randomBytes(32).toString("base64url");
  const expiresAt = Date.now() + dynamicSessionTtlMs;
  dynamicSessions.set(token, expiresAt);
  return { token, expiresAt };
};

const isDiarySessionAuthorized = (request) => {
  cleanupDiarySessions();
  const header = request.headers.authorization || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) return false;
  const token = match[1];
  const expiresAt = diarySessions.get(token);
  if (!expiresAt || expiresAt <= Date.now()) {
    diarySessions.delete(token);
    return false;
  }
  return true;
};

const isDynamicSessionAuthorized = (request) => {
  cleanupDynamicSessions();
  const header = request.headers.authorization || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) return false;
  const token = match[1];
  const expiresAt = dynamicSessions.get(token);
  if (!expiresAt || expiresAt <= Date.now()) {
    dynamicSessions.delete(token);
    return false;
  }
  return true;
};

const requireDiaryAuth = (request, response) => {
  if (isAuthorized(request) || isDiarySessionAuthorized(request)) return true;
  sendError(response, 401, "Unauthorized.");
  return false;
};

const ensureDataDir = async () => {
  await mkdir(dataDir, { recursive: true });
};

const readJsonFile = async (filePath, fallback) => {
  await ensureDataDir();
  try {
    const raw = await readFile(filePath, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    if (error?.code === "ENOENT") return fallback();
    throw error;
  }
};

const writeJsonFile = async (filePath, value) => {
  await ensureDataDir();
  const tempPath = `${filePath}.${process.pid}.tmp`;
  await writeFile(tempPath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
  await rename(tempPath, filePath);
};

const readBody = (request) =>
  new Promise((resolveBody, rejectBody) => {
    let size = 0;
    const chunks = [];

    request.on("data", (chunk) => {
      size += chunk.length;
      if (size > maxBodyBytes) {
        rejectBody(new Error("Request body is too large."));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });

    request.on("end", () => {
      const raw = Buffer.concat(chunks).toString("utf8").trim();
      if (!raw) {
        resolveBody({});
        return;
      }
      try {
        resolveBody(JSON.parse(raw));
      } catch {
        rejectBody(new Error("Invalid JSON body."));
      }
    });

    request.on("error", rejectBody);
  });

const cleanText = (value, maxLength) =>
  String(value || "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxLength);

const cleanMultiline = (value, maxLength) =>
  String(value || "")
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n")
    .trim()
    .slice(0, maxLength);

const normalizePath = (value) => {
  const text = String(value || "/").trim();
  if (!text.startsWith("/")) return "/";
  try {
    const parsed = new URL(text, "https://blog.local");
    return parsed.pathname.slice(0, 160) || "/";
  } catch {
    return "/";
  }
};

const makeId = () => `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 9)}`;

const publicImageRecord = (image) => {
  if (!image || typeof image !== "object" || !image.src) return null;
  return {
    src: image.src,
    alt: image.alt || "",
    type: image.type || "",
    width: Number(image.width || 0),
    height: Number(image.height || 0)
  };
};

const publicLifeRecord = (record) => ({
  id: record.id,
  title: record.title,
  content: record.content,
  mood: record.mood,
  images: Array.isArray(record.images) ? record.images.map(publicImageRecord).filter(Boolean) : [],
  createdAt: record.createdAt,
  updatedAt: record.updatedAt
});

const publicDynamicRecord = (record) => ({
  id: record.id,
  title: record.title || "",
  content: record.content,
  mood: record.mood,
  images: Array.isArray(record.images) ? record.images.map(publicImageRecord).filter(Boolean) : [],
  createdAt: record.createdAt,
  updatedAt: record.updatedAt
});

const parseDynamicImage = (image) => {
  if (!image || typeof image !== "object") {
    throw httpError(400, "Invalid image payload.");
  }

  const dataUrl = String(image.dataUrl || "");
  const match = dataUrl.match(/^data:(image\/(?:jpeg|png|webp));base64,([A-Za-z0-9+/=]+)$/);
  if (!match) {
    throw httpError(400, "Only JPEG, PNG and WebP images are supported.");
  }

  const type = match[1];
  const extension = dynamicImageTypes.get(type);
  const buffer = Buffer.from(match[2], "base64");
  if (!extension || buffer.length === 0) {
    throw httpError(400, "Invalid image payload.");
  }
  if (buffer.length > maxDynamicImageBytes) {
    throw httpError(413, "Each image must be smaller than 3 MB after compression.");
  }

  return {
    buffer,
    type,
    extension,
    alt: cleanText(image.alt || image.name || "", 80),
    width: Number(image.width || 0),
    height: Number(image.height || 0)
  };
};

const saveDynamicImages = async (rawImages, recordId) => {
  if (!Array.isArray(rawImages) || rawImages.length === 0) return [];
  if (rawImages.length > maxDynamicImages) {
    throw httpError(400, `At most ${maxDynamicImages} images can be attached.`);
  }

  const bucketDate = new Date();
  const bucket = `${bucketDate.getFullYear()}${String(bucketDate.getMonth() + 1).padStart(2, "0")}`;
  const uploadDir = join(files.uploads, "dynamics", bucket);
  await mkdir(uploadDir, { recursive: true });

  const savedImages = [];
  for (const [index, rawImage] of rawImages.entries()) {
    const image = parseDynamicImage(rawImage);
    const fileName = `${recordId}-${index}-${randomBytes(4).toString("hex")}.${image.extension}`;
    await writeFile(join(uploadDir, fileName), image.buffer);
    savedImages.push({
      src: `/uploads/dynamics/${bucket}/${fileName}`,
      alt: image.alt,
      type: image.type,
      size: image.buffer.length,
      width: image.width,
      height: image.height
    });
  }
  return savedImages;
};

const handleUploadRead = async (response, url) => {
  let decodedPath = "";
  try {
    decodedPath = decodeURIComponent(url.pathname);
  } catch {
    sendError(response, 404, "Not found.");
    return;
  }

  if (!decodedPath.startsWith("/uploads/") || decodedPath.includes("\0")) {
    sendError(response, 404, "Not found.");
    return;
  }

  const uploadsRoot = resolve(files.uploads);
  const relativePath = decodedPath.replace(/^\/uploads\/+/, "");
  const filePath = resolve(uploadsRoot, relativePath);
  if (filePath === uploadsRoot || !filePath.startsWith(`${uploadsRoot}${sep}`)) {
    sendError(response, 403, "Forbidden.");
    return;
  }

  const contentType = uploadContentTypes[extname(filePath).toLowerCase()];
  if (!contentType) {
    sendError(response, 404, "Not found.");
    return;
  }

  try {
    const body = await readFile(filePath);
    send(response, 200, body, {
      "Content-Type": contentType,
      "Cache-Control": "public, max-age=31536000, immutable"
    });
  } catch (error) {
    if (error?.code === "ENOENT") {
      sendError(response, 404, "Not found.");
      return;
    }
    throw error;
  }
};

const handleStatsRead = async (response, url) => {
  const stats = await readJsonFile(files.stats, defaultStats);
  const path = normalizePath(url.searchParams.get("path"));
  sendJson(response, 200, {
    ok: true,
    total: Number(stats.total || 0),
    page: Number(stats.pages?.[path] || 0),
    path,
    updatedAt: stats.updatedAt || null
  });
};

const handleStatsWrite = async (request, response) => {
  const body = await readBody(request);
  const path = normalizePath(body.path);
  const stats = await readJsonFile(files.stats, defaultStats);
  stats.total = Number(stats.total || 0) + 1;
  stats.pages = stats.pages && typeof stats.pages === "object" ? stats.pages : {};
  stats.pages[path] = Number(stats.pages[path] || 0) + 1;
  stats.updatedAt = nowIso();
  await writeJsonFile(files.stats, stats);
  sendJson(response, 200, {
    ok: true,
    total: stats.total,
    page: stats.pages[path],
    path,
    updatedAt: stats.updatedAt
  });
};

const handleLifeRead = async (response, url) => {
  const limit = Math.max(1, Math.min(24, Number.parseInt(url.searchParams.get("limit") || "6", 10) || 6));
  const records = await readPublicDynamicRecords(limit);
  sendJson(response, 200, { ok: true, records });
};

const readPublicDynamicRecords = async (limit) => {
  const [dynamicRecords, legacyLifeRecords] = await Promise.all([
    readJsonFile(files.dynamics, () => []),
    readJsonFile(files.life, () => [])
  ]);
  return [...dynamicRecords, ...legacyLifeRecords]
    .filter((record) => record.status === "published")
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)))
    .slice(0, limit)
    .map(publicDynamicRecord);
};

const handleDynamicRead = async (response, url) => {
  const limit = Math.max(1, Math.min(24, Number.parseInt(url.searchParams.get("limit") || "6", 10) || 6));
  const records = await readPublicDynamicRecords(limit);
  sendJson(response, 200, { ok: true, records });
};

const handleDynamicWrite = async (request, response) => {
  const body = await readBody(request);
  const adminAuthorized = isAuthorized(request);
  const sessionAuthorized = isDynamicSessionAuthorized(request);
  if (!adminAuthorized && !sessionAuthorized) {
    if (!requirePassword(response, dynamicPostPassword, body.password, "Dynamic publish")) return;
  }

  const id = makeId();
  const title = cleanText(body.title, 80);
  const content = cleanMultiline(body.content, 1000);
  const mood = cleanText(body.mood, 24);
  const status = adminAuthorized && body.status === "draft" ? "draft" : "published";
  const images = await saveDynamicImages(body.images, id);

  if (!content && images.length === 0) {
    sendError(response, 400, "Content or image is required.");
    return;
  }

  const records = await readJsonFile(files.dynamics, () => []);
  const record = {
    id,
    title,
    content,
    mood,
    images,
    status,
    createdAt: nowIso(),
    updatedAt: nowIso()
  };
  records.unshift(record);
  await writeJsonFile(files.dynamics, records);
  sendJson(response, 201, { ok: true, record: publicDynamicRecord(record) });
};

const handleLegacyLifeRead = async (response, url) => {
  const limit = Math.max(1, Math.min(24, Number.parseInt(url.searchParams.get("limit") || "6", 10) || 6));
  const records = await readJsonFile(files.life, () => []);
  const published = records
    .filter((record) => record.status === "published")
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)))
    .slice(0, limit)
    .map(publicLifeRecord);
  sendJson(response, 200, { ok: true, records: published });
};

const handleLifeWrite = async (request, response) => {
  await handleDynamicWrite(request, response);
};

const handleDynamicSessionCreate = async (request, response) => {
  const body = await readBody(request);
  if (!requirePassword(response, dynamicPostPassword, body.password, "Dynamic publish")) return;
  const session = createDynamicSession();
  sendJson(response, 200, {
    ok: true,
    token: session.token,
    expiresAt: new Date(session.expiresAt).toISOString()
  });
};

const handleDiaryRead = async (request, response, url) => {
  if (!requireDiaryAuth(request, response)) return;
  const query = cleanText(url.searchParams.get("q"), 120).toLowerCase();
  const entries = await readJsonFile(files.diary, () => []);
  const filteredEntries = query
    ? entries.filter((entry) => `${entry.title || ""}\n${entry.content || ""}`.toLowerCase().includes(query))
    : entries;
  sendJson(response, 200, {
    ok: true,
    entries: filteredEntries
      .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)))
      .map((entry) => ({
        id: entry.id,
        title: entry.title,
        content: entry.content,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt
      }))
  });
};

const handleDiarySessionCreate = async (request, response) => {
  const body = await readBody(request);
  if (!requirePassword(response, diaryPassword, body.password, "Diary")) return;
  const session = createDiarySession();
  sendJson(response, 200, {
    ok: true,
    token: session.token,
    expiresAt: new Date(session.expiresAt).toISOString()
  });
};

const handleDiaryWrite = async (request, response) => {
  if (!requireDiaryAuth(request, response)) return;
  const body = await readBody(request);
  const title = cleanText(body.title, 80) || "未命名日记";
  const content = cleanMultiline(body.content, 10000);

  if (!content) {
    sendError(response, 400, "Content is required.");
    return;
  }

  const entries = await readJsonFile(files.diary, () => []);
  const entry = {
    id: makeId(),
    title,
    content,
    createdAt: nowIso(),
    updatedAt: nowIso()
  };
  entries.unshift(entry);
  await writeJsonFile(files.diary, entries);
  sendJson(response, 201, { ok: true, entry: { id: entry.id, title: entry.title, createdAt: entry.createdAt } });
};

const adminHtml = () => `<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>博客动态服务管理</title>
    <style>
      :root { color-scheme: light dark; font-family: system-ui, "Microsoft YaHei", sans-serif; }
      body { max-width: 860px; margin: 0 auto; padding: 28px 18px 56px; line-height: 1.7; }
      label { display: grid; gap: 6px; margin: 12px 0; font-weight: 700; }
      input, textarea, select, button { font: inherit; }
      input, textarea, select { width: 100%; padding: 10px 12px; border: 1px solid #9995; border-radius: 8px; }
      textarea { min-height: 150px; resize: vertical; }
      button { min-height: 38px; padding: 0 14px; border: 0; border-radius: 8px; background: #bd3f74; color: #fff; font-weight: 800; }
      section { margin-top: 22px; padding: 18px; border: 1px solid #9995; border-radius: 8px; }
      .hint, output { color: #777; }
    </style>
  </head>
  <body>
    <h1>博客动态服务管理</h1>
    <p class="hint">此页面不保存服务器密钥到仓库。Token 仅保存在当前浏览器本地，用于调用受保护 API。</p>
    <label>管理 Token <input id="token" type="password" autocomplete="current-password" /></label>
    <section>
      <h2>写日记</h2>
      <label>标题 <input id="diary-title" /></label>
      <label>内容 <textarea id="diary-content"></textarea></label>
      <button data-action="diary">保存私密日记</button>
    </section>
    <section>
      <h2>公开动态</h2>
      <label>标题 <input id="life-title" /></label>
      <label>状态
        <select id="life-status">
          <option value="draft">草稿</option>
          <option value="published">公开发布</option>
        </select>
      </label>
      <label>内容 <textarea id="life-content"></textarea></label>
      <button data-action="life">保存动态</button>
    </section>
    <output id="result"></output>
    <script>
      const tokenInput = document.querySelector("#token");
      const result = document.querySelector("#result");
      tokenInput.value = localStorage.getItem("blog-dynamic-admin-token") || "";
      tokenInput.addEventListener("change", () => localStorage.setItem("blog-dynamic-admin-token", tokenInput.value));
      const postJson = async (path, body) => {
        const response = await fetch(path, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + tokenInput.value
          },
          body: JSON.stringify(body)
        });
        const data = await response.json();
        if (!response.ok || !data.ok) throw new Error(data.error || "请求失败");
        return data;
      };
      document.querySelector("[data-action='diary']").addEventListener("click", async () => {
        try {
          await postJson("/api/diary", {
            title: document.querySelector("#diary-title").value,
            content: document.querySelector("#diary-content").value
          });
          result.textContent = "私密日记已保存。";
        } catch (error) {
          result.textContent = error.message;
        }
      });
      document.querySelector("[data-action='life']").addEventListener("click", async () => {
        try {
          await postJson("/api/life", {
            title: document.querySelector("#life-title").value,
            status: document.querySelector("#life-status").value,
            content: document.querySelector("#life-content").value
          });
          result.textContent = "动态已保存。";
        } catch (error) {
          result.textContent = error.message;
        }
      });
    </script>
  </body>
</html>`;

const handleRequest = async (request, response) => {
  applyCors(request, response);

  if (request.method === "OPTIONS") {
    response.writeHead(204);
    response.end();
    return;
  }

  const url = new URL(request.url || "/", publicBaseUrl || `http://${host}:${port}`);

  try {
    if (request.method === "GET" && url.pathname === "/health") {
      sendJson(response, 200, { ok: true, service: "blog-dynamic", time: nowIso() });
      return;
    }
    if (request.method === "GET" && url.pathname === "/admin/") {
      send(response, 200, adminHtml(), htmlHeaders);
      return;
    }
    if (request.method === "GET" && url.pathname === "/api/stats") {
      await handleStatsRead(response, url);
      return;
    }
    if (request.method === "POST" && url.pathname === "/api/stats/pageview") {
      await handleStatsWrite(request, response);
      return;
    }
    if (request.method === "GET" && url.pathname === "/api/life") {
      await handleLifeRead(response, url);
      return;
    }
    if (request.method === "GET" && url.pathname === "/api/life/legacy") {
      await handleLegacyLifeRead(response, url);
      return;
    }
    if (request.method === "GET" && url.pathname === "/api/dynamics") {
      await handleDynamicRead(response, url);
      return;
    }
    if (request.method === "POST" && url.pathname === "/api/dynamics/session") {
      await handleDynamicSessionCreate(request, response);
      return;
    }
    if (request.method === "POST" && url.pathname === "/api/dynamics") {
      await handleDynamicWrite(request, response);
      return;
    }
    if (request.method === "POST" && url.pathname === "/api/life") {
      await handleLifeWrite(request, response);
      return;
    }
    if (request.method === "GET" && url.pathname === "/api/diary") {
      await handleDiaryRead(request, response, url);
      return;
    }
    if (request.method === "POST" && url.pathname === "/api/diary/session") {
      await handleDiarySessionCreate(request, response);
      return;
    }
    if (request.method === "POST" && url.pathname === "/api/diary") {
      await handleDiaryWrite(request, response);
      return;
    }
    if (request.method === "GET" && url.pathname.startsWith("/uploads/")) {
      await handleUploadRead(response, url);
      return;
    }
    sendError(response, 404, "Not found.");
  } catch (error) {
    sendError(response, error.status || (error.message === "Request body is too large." ? 413 : 500), error.message || "Server error.");
  }
};

const server = createServer((request, response) => {
  void handleRequest(request, response);
});

server.listen(port, host, () => {
  console.log(`blog dynamic service listening on http://${host}:${port}`);
  console.log(`data directory: ${dataDir}`);
});
