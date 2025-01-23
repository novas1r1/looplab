/** @type {import('tailwindcss').Config} */
export default {
    content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
    theme: {
        extend: {
            colors: {
                primary: {
                    DEFAULT: '#55d8e1',
                    container: '#00a3ab',
                },
                secondary: {
                    DEFAULT: '#c2c7d0',
                    container: '#30353d',
                },
                surface: {
                    DEFAULT: '#141313',
                    bright: '#3a3939',
                    container: '#201f1f',
                },
                error: '#ffb3ae',
            },
            fontFamily: {
                sans: ['Inter', 'system-ui', 'sans-serif'],
                display: ['Montserrat', 'system-ui', 'sans-serif'],
            },
            typography: {
                invert: {
                    css: {
                        '--tw-prose-body': '#c2c7d0',
                        '--tw-prose-headings': '#55d8e1',
                        '--tw-prose-links': '#55d8e1',
                        '--tw-prose-bold': '#c2c7d0',
                        '--tw-prose-bullets': '#55d8e1',
                        '--tw-prose-hr': '#30353d',
                        '--tw-prose-quotes': '#c2c7d0',
                        '--tw-prose-quote-borders': '#30353d',
                    },
                },
            },
        },
    },
    plugins: [
        require('@tailwindcss/typography'),
    ],
} 