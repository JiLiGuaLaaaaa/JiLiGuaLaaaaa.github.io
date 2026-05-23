/// <reference types="astro/client" />

interface ImportMetaEnv {
  readonly PUBLIC_DYNAMIC_API_BASE?: string;
  readonly PUBLIC_DYNAMIC_ADMIN_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
