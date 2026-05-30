import rss from '@astrojs/rss';
import { getCollection, type CollectionEntry } from 'astro:content';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
  const posts = (
    await getCollection('posts', ({ data }: CollectionEntry<'posts'>) => !data.draft)
  ).sort(
    (a: CollectionEntry<'posts'>, b: CollectionEntry<'posts'>) =>
      b.data.publishedAt.valueOf() - a.data.publishedAt.valueOf(),
  );

  return rss({
    title: 'stonemegan.dev',
    description:
      "What working with AI actually looks like — from a Sydney nurse, an ECT, and an indie dev.",
    site: context.site ?? 'https://stonemegan.dev',
    items: posts.map((p: CollectionEntry<'posts'>) => ({
      title: p.data.title,
      description: p.data.description,
      pubDate: p.data.publishedAt,
      link: `/blog/${p.data.slug}/`,
      categories: [p.data.category],
    })),
    customData: '<language>en-au</language>',
  });
}
