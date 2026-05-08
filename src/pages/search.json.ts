import { getPostSlug, getPublishedPosts } from "@/lib/posts";

export async function GET() {
  const posts = await getPublishedPosts();

  return new Response(
    JSON.stringify(
      posts.map((post) => ({
        title: post.data.title,
        description: post.data.description,
        url: `/blog/${getPostSlug(post)}/`,
        tags: post.data.tags,
        pubDate: post.data.pubDate.toISOString().slice(0, 10)
      }))
    ),
    {
      headers: {
        "content-type": "application/json; charset=utf-8"
      }
    }
  );
}
