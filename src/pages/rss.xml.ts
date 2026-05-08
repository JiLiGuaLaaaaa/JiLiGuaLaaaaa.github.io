import rss from "@astrojs/rss";
import type { APIContext } from "astro";
import { siteConfig } from "@/config/site";
import { getPostSlug, getPublishedPosts } from "@/lib/posts";

export async function GET(context: APIContext) {
  const posts = await getPublishedPosts();

  return rss({
    title: siteConfig.name,
    description: siteConfig.description,
    site: context.site?.toString() ?? siteConfig.url,
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.pubDate,
      link: `/blog/${getPostSlug(post)}/`,
      categories: post.data.tags
    }))
  });
}
