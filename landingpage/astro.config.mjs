import tailwind from '@astrojs/tailwind';
import { defineConfig } from 'astro/config';

export default defineConfig({
    integrations: [tailwind()],
    // New v5 recommended settings
    prefetch: {
        prefetchAll: true
    },
    build: {
        inlineStylesheets: 'auto'
    },
    site: 'https://repeatlab.app', // Replace with your actual domain
    compressHTML: true,
    // Enable service worker for offline support
    serviceWorker: true,
}); 