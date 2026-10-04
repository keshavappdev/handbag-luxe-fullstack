# React admin panel

Read `../README.md` for setup and first-admin creation.

```bash
npm ci
cp .env.example .env
npm run dev
```

Open http://localhost:5173. Configure `VITE_API_URL` with the Express admin base URL. Production: `npm run build`; deploy `dist` to your static host. Never place private keys in Vite environment variables.
