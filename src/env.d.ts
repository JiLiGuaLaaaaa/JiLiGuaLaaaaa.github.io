/// <reference types="astro/client" />

interface ImportMetaEnv {
  readonly PUBLIC_DYNAMIC_API_BASE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
