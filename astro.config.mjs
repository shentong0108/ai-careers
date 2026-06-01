import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://stonemegan.dev',
  output: 'static',
  integrations: [
    mdx(),
    sitemap({
      filter: (page) => !page.includes('/draft/'),
      // Build-time lastmod so Google knows the sitemap (and every page in
      // it) has been refreshed on this deploy. Per-article lastmod from
      // MDX `updatedAt` would be more precise but requires content-collection
      // access inside the integration, which @astrojs/sitemap doesn't expose
      // cleanly. Sitewide build-time lastmod is the next-best signal.
      lastmod: new Date(),
      // Priority + changefreq are weak signals (Google mostly ignores them
      // post-2023) but cost nothing and complete the sitemap shape for
      // smaller engines (Bing, DuckDuckGo's Bing-backed index, Yandex).
      serialize(item) {
        const url = item.url;
        if (url === 'https://stonemegan.dev/' || url.endsWith('/index.html')) {
          item.priority = 1.0;
          item.changefreq = 'weekly';
        } else if (/\/(nurse-ai|ece-ai|dev-diary)\/?$/.test(url)) {
          item.priority = 0.8;
          item.changefreq = 'daily';
        } else if (url.includes('/blog/')) {
          item.priority = 0.7;
          item.changefreq = 'monthly';
        } else if (/\/(privacy|disclaimer)\/?$/.test(url)) {
          item.priority = 0.3;
          item.changefreq = 'yearly';
        } else {
          item.priority = 0.5;
          item.changefreq = 'monthly';
        }
        return item;
      },
    }),
  ],
  build: {
    inlineStylesheets: 'auto',
    assets: '_assets',
  },
  prefetch: {
    prefetchAll: true,
    defaultStrategy: 'viewport',
  },
  vite: {
    resolve: {
      alias: {
        '@': '/src',
      },
    },
  },
});
