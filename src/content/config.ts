import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const postSchema = z.object({
  title: z.string().min(10).max(70),
  slug: z.string().regex(/^[a-z0-9-]+$/),
  description: z.string().min(120).max(170),
  publishedAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
  author: z.enum(['stone', 'megan']),
  category: z.enum(['nurse-ai', 'ece-ai', 'dev-diary']),
  tags: z.array(z.string()).min(2).max(8),
  keywords: z.array(z.string()).min(1).max(10),
  canonical: z.string().url(),
  draft: z.boolean().default(true),
  aiDetectionScore: z.number().min(0).max(100).nullable().default(null),
  heroImage: z.string().startsWith('/'),
  ogImage: z.string().startsWith('/').optional(),
  factChecked: z.boolean().default(false),
  factCheckedAt: z.coerce.date().optional(),
  factCheckNotes: z
    .array(
      z.object({
        line: z.number(),
        claim: z.string(),
        issue: z.string(),
        suggestion: z.string(),
      })
    )
    .default([]),
});

const posts = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/posts' }),
  schema: postSchema,
});

export const collections = { posts };
