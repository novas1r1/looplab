import sitemap from '@astrojs/sitemap';
import tailwind from '@astrojs/tailwind';
import { defineConfig } from 'astro/config';

export default defineConfig({
    integrations: [tailwind(), sitemap()],
    prefetch: {
        prefetchAll: true
    },
    build: {
        inlineStylesheets: 'auto'
    },
    site: 'https://repeatlab.netlify.app',
    compressHTML: true,
});
