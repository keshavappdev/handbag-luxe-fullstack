# Potli Backend Branding Migration Audit

## Scope
The complete backend/admin workspace was scanned for all legacy brand spellings and updated to `Potli` while preserving the existing Express, MongoDB, React admin, API structure, business logic, and folder organization.

## Updated runtime references
- Backend package name: `potli-api`
- Admin package name: `potli-admin`
- MongoDB database example/default URI: `potli`
- JWT issuer: `potli`
- JWT audience: `potli-app`
- Default shop name/brand: `POTLI`
- Cloudinary upload folder: `potli`
- Android FCM notification channel ID sent by Firebase Admin: `potli_default`
- Admin browser session key: `potli.admin`
- Credits API action: `get_my_potli_credits`
- Console/server branding and documentation updated to Potli

## Flutter compatibility
The previously updated Potli Flutter project was cross-checked and contains calls to `get_my_potli_credits`, matching this backend action.

## Important migration notes
1. Existing JWTs issued with the old issuer/audience will no longer validate. Users/admins should sign in again after deployment.
2. Changing the MongoDB URI database name to `potli` means an existing database under the old legacy name is not automatically copied. Migrate/rename existing production data before switching if data must be preserved.
3. New Cloudinary uploads will go to the `potli` folder. Existing image URLs already stored in MongoDB can continue working because they are absolute URLs, but existing Cloudinary assets are not automatically moved.
4. The FCM Android channel is now `potli_default`; the mobile app should create/use that channel if custom Android notification channels are configured client-side.

## Validation performed
- Full source scan for all legacy brand spellings (case-insensitive): **0 matches**.
- Node syntax validation (`node --check`) across backend source, scripts, and tests: passed.
- `package.json` and `package-lock.json` parsing for backend/admin: passed.
- Flutter/backend endpoint cross-check for `get_my_potli_credits`: passed.
- A full `npm test` could not be completed in this execution environment because the uploaded `node_modules` contained a platform-specific Sharp binary, and a clean `npm ci` dependency reinstall timed out. `node_modules` has therefore been excluded from the cleaned source package; run `npm ci` on the target machine before testing/building.

## Recommended local verification
Backend:
```bash
cd backend
npm ci
npm test
npm run test:integration
npm start
```

Admin panel:
```bash
cd admin-panel
npm ci
npm run build
```
