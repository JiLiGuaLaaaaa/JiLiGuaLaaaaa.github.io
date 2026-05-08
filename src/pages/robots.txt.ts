import { siteConfig } from "@/config/site";

export function GET() {
  return new Response(
    `User-agent: *\nAllow: /\n\nSitemap: ${siteConfig.url}/sitemap-index.xml\n`,
    {
      headers: {
        "content-type": "text/plain; charset=utf-8"
      }
    }
  );
}
