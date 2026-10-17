# Public Repository Credential Review

Scope: all supplied admin/backend files in the input ZIP; it does not include the separate mobile app, deployment environment, or pre-existing Git history.

- Removed `backend/.env` (contained one active-format JWT signing key and a local loopback-only MongoDB URI).
- Removed `admin-panel/.env` (contained a development API URL, no secret).
- Retained safe `.env.example` templates and strengthened `.gitignore`.
- No hardcoded admin login was found. `npm run admin` prompts for the credentials.
- Blank Cloudinary/Razorpay/Google/Firebase configuration fields were not real credentials.
- Unit tests contain deliberately fake passwords and test JWT strings; these remain to preserve coverage.
- Local MongoDB connection string has no password and points at loopback; it is not a production credential.
- **Rotate the JWT signing key from the original ZIP** if it has ever been used and revoke existing sessions.
- **Cannot validate** production secret stores, historic Git commits or external account status from source alone.
