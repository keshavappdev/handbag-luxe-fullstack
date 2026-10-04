# Backend

Read `../README.md` for the complete setup guide and `../docs/API.md` for endpoints.

```bash
npm ci
npm run setup
# Start the MongoDB replica set using ../docker-compose.yml first.
npm run admin
npm run seed
npm run dev
```

Tests: `npm test` (independent checks), `npm run test:integration` (temporary real MongoDB replica set).

`src/routes` → `controllers` → `services` → Mongoose models → MongoDB. The API accepts the existing Flutter form-post contracts and separate admin REST routes. Configure all credentials in `.env`; never commit that file.
