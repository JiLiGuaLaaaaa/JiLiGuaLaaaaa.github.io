import { getCollection, type CollectionEntry } from "astro:content";

export type BlogPost = CollectionEntry<"blog">;

export async function getPublishedPosts() {
  const posts = await getCollection("blog", ({ data }) => !data.draft);
  return posts.sort(
    (a, b) => b.data.pubDate.getTime() - a.data.pubDate.getTime()
  );
}

export function getAllTags(posts: BlogPost[]) {
  const tags = new Map<string, number>();

  for (const post of posts) {
    for (const tag of post.data.tags) {
      tags.set(tag, (tags.get(tag) ?? 0) + 1);
    }
  }

  return [...tags.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => a.name.localeCompare(b.name, "zh-CN"));
}

export function getPostsByTag(posts: BlogPost[], tag: string) {
  return posts.filter((post) => post.data.tags.includes(tag));
}

export function getArchiveGroups(posts: BlogPost[]) {
  const groups = new Map<string, BlogPost[]>();

  for (const post of posts) {
    const year = String(post.data.pubDate.getFullYear());
    const list = groups.get(year) ?? [];
    list.push(post);
    groups.set(year, list);
  }

  return [...groups.entries()]
    .map(([year, items]) => ({ year, items }))
    .sort((a, b) => Number(b.year) - Number(a.year));
}

export function getPostSlug(post: BlogPost) {
  if ("slug" in post && typeof post.slug === "string") {
    return post.slug;
  }

  return post.id.replace(/\.(md|mdx)$/i, "");
}

export function formatDate(date: Date) {
  return new Intl.DateTimeFormat("zh-CN", {
    year: "numeric",
    month: "long",
    day: "numeric"
  }).format(date);
}
