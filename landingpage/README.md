# RepeatLab Landing Page

This is the landing page for RepeatLab, built with Astro and TailwindCSS.

## Development

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

3. Build for production:
```bash
npm run build
```

4. Preview the production build:
```bash
npm run preview
```

## Deployment

### Manual Deployment with Netlify CLI

1. Install Netlify CLI globally (one-time setup):
```bash
npm install -g netlify-cli
```

2. Login to Netlify (one-time setup):
```bash
netlify login
```

3. Link your local project to your Netlify site (one-time setup):
```bash
netlify link
```

4. To deploy:
```bash
# Deploy to draft URL (for testing)
netlify deploy

# Deploy to production
netlify deploy --prod
```

Note: Auto-deployment should be disabled in Netlify dashboard under Build & deploy → Continuous Deployment → Build settings.

## Project Structure

```
/
├── public/
│   └── images/
│   └── fonts/
├── src/
│   ├── components/
│   ├── layouts/
│   ├── pages/
│   └── styles/
└── package.json
```

## Technologies Used

- [Astro](https://astro.build)
- [TailwindCSS](https://tailwindcss.com)
- Inter & Montserrat fonts from Google Fonts 