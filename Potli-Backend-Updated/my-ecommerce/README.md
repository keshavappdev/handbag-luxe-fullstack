# POTLI — Flutter + Express + MongoDB + React

This project is the backend and admin workspace for the **Potli** Flutter application. The existing Flutter architecture, screens and navigation remain compatible with these APIs. Products, categories, stock, customers, carts, wishlists, addresses, orders and supporting account features use the new Node.js API.

**Start with local Cash on Delivery checkout.** You do not need Cloudinary, Razorpay, Google OAuth or Firebase credentials for the core shopping flow. Real third-party integrations require your own accounts and credentials; no shared/demo credentials are included.

## 1. What's included

```text
my-ecommerce/
├── mobile-app/       Existing Flutter customer application, integrated
├── backend/          Express API, Mongoose models, services, tests, setup scripts
├── admin-panel/      React/Vite administration application
├── docker-compose.yml  Local MongoDB replica set
└── docs/             API reference, source analysis, verification report
```

Admin → authenticated Express API → MongoDB. The Flutter app fetches the same products through `/api/v1/get_products`. Uploads return an image URL; MongoDB stores that URL. **Adding a product never requires editing Flutter source.** Tap Home again, reopen the collection, or restart the app to fetch changes. This is API refresh, not a WebSocket live feed.

Features include:

- Mobile/password registration and login, JWT, profile, optional verified Google sign-in.
- Three-level category hierarchy, products, gallery images, search, pricing, stock, tags and optional engraving.
- Guest/local cart and wishlist; signed-in data stored on the server and reloaded. Guest selections merge on login; logout clears local customer data.
- Addresses, COD orders, order history, status timeline and native invoice data.
- Transactional inventory, server totals, checkout idempotency, shipping and promo rules.
- Support tickets with image attachments, returns/exchanges and return credit codes.
- Optional Razorpay checkout and wallet top-ups, signed callbacks and webhook verification.
- Admin product/category CRUD, uploads, orders, customers, homepage content, support replies, returns and promotions.

Read `docs/VERIFICATION.md` for exactly what was tested. The system is source-complete for the documented local flow, but a full end-to-end mobile/database run could not be certified in the build environment.

## 2. Required software

Install these on your development computer:

1. **Node.js 22 or newer** (Node 24 LTS is suitable), including npm. Get the installer from https://nodejs.org/en/download. On your Mac, use the macOS installer for your processor. Reopen Terminal afterward.
2. **Docker Desktop**, https://www.docker.com/products/docker-desktop/. Open the app and wait for Docker to start. Docker runs MongoDB, so you do not need a separate MongoDB installation with this option.
3. **Flutter stable** with Dart 3.3 or newer. Use your existing recent Flutter SDK. Run `flutter doctor` and resolve Android/Xcode setup issues.
4. Android Studio/emulator or a physical Android phone. For iOS, macOS, Xcode and CocoaPods are required.
5. A code editor such as VS Code.

Check installation:

```bash
node --version
npm --version
docker --version
docker compose version
flutter doctor
```

All commands below run in Terminal. Each long-running server needs its own Terminal window. Do not paste the directory tree above as a command.

## 3. Start MongoDB

Unzip the project and open a Terminal **inside `my-ecommerce`**:

```bash
docker compose up -d
docker compose ps -a
docker compose logs mongo-init
```

`mongo-init` runs once, initializes replication, and exits. This is normal. Allow approximately 15–30 seconds for the database to become primary. Confirm:

```bash
docker compose exec mongo mongosh --quiet --eval 'db.hello().isWritablePrimary'
```

The result should be `true`.

A replica set is required because checkout changes stock, wallet/credit, cart and order together in a MongoDB transaction. The provided Compose file runs a **single local replica-set member**. MongoDB listens on your computer's loopback address only. This local no-password configuration is for development; do not expose it to the internet.

The database is `potli`. Docker stores its data in the `mongo-data` volume. `docker compose stop` preserves your data. Avoid `docker compose down -v` unless you intend to erase the database.

### Alternative: MongoDB Atlas

Create your own Atlas cluster at https://www.mongodb.com/atlas, create a database user, and allow your computer's IP. Copy its driver connection string into `MONGODB_URI` in `backend/.env`, including the database name `potli`. Atlas supports transactions. Encode special characters in the database password. With Atlas, skip Docker commands. Do not commit this connection string.

## 4. Install and configure backend

```bash
cd backend
npm ci
npm run setup
```

`setup` creates `.env` from `.env.example` with a random JWT secret. It never overwrites an existing `.env`. Open `backend/.env` in your editor.

For the default Docker setup:

```dotenv
PORT=4000
MONGODB_URI=mongodb://127.0.0.1:27017/potli?replicaSet=rs0&directConnection=true
ADMIN_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
PUBLIC_URL=http://localhost:4000
IMAGE_STORAGE=local
```

Keep the generated `JWT_SECRET`. It must be at least 32 characters and private. JWTs expire after seven days by default; sign in again after expiry. Profile ownership comes from the JWT, never a submitted `user_id`.

### Set the image hostname before uploading

`PUBLIC_URL` becomes part of every locally uploaded image URL. It must be reachable by the customer device:

| Device | Example PUBLIC_URL | Flutter API_BASE_URL |
| --- | --- | --- |
| Android emulator | `http://10.0.2.2:4000` | `http://10.0.2.2:4000/api/v1/` |
| iOS simulator | `http://localhost:4000` | `http://localhost:4000/api/v1/` |
| Physical phone + computer on same Wi-Fi | `http://192.168.1.10:4000` | `http://192.168.1.10:4000/api/v1/` |

Replace `192.168.1.10` with your computer's actual LAN IP from Wi-Fi settings. A physical phone's `localhost` refers to the phone, not your Mac. Using the Mac LAN IP is usually best when testing several device types and the admin browser together. An admin browser cannot normally open Android's `10.0.2.2`, so prefer the LAN IP if you need both previews.

Changing `PUBLIC_URL` does not rewrite already-saved image URLs. Upload those images again, or use Cloudinary URLs when switching environments.

### Other environment settings

| Variable | Purpose |
| --- | --- |
| `NODE_ENV` | `development`, `test`, or `production` |
| `JWT_EXPIRES_IN` | Token lifetime, default `7d` |
| `ADMIN_ORIGINS` | Exact allowed browser origins, comma separated |
| `IMAGE_STORAGE` | `local` or `cloudinary` |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Your cloud image account |
| `GOOGLE_CLIENT_IDS` | Accepted Google OAuth client IDs, comma separated |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Your Razorpay test/live credentials |
| `RAZORPAY_WEBHOOK_SECRET` | Secret you configure for the payment webhook |
| `GOOGLE_APPLICATION_CREDENTIALS` | Optional path to your Firebase service account JSON |
| `SHOP_NAME`, `SHOP_ADDRESS`, `SUPPORT_EMAIL` | Invoice seller details |
| `SHIPPING_STANDARD`, `SHIPPING_EXPRESS` | Whole-INR shipping fees, defaults 99 / 199 |
| `FREE_SHIPPING_THRESHOLD` | Free standard shipping threshold, default 2999 |
| `RETURN_WINDOW_DAYS` | Return/exchange eligibility window, default 14 |

## 5. Create the first admin and seed categories

Still inside `backend`:

```bash
npm run admin
npm run seed
```

The admin command asks for email, name and a password of at least 12 characters. The interactive password is visible in your local terminal; use a private terminal. No default password exists. It refuses to replace an existing account. Registration through Flutter can create only customer accounts.

The seed command creates Bags → bag types → collections. It is safe to run repeatedly. It does **not** invent products, stock or customer accounts. Upload your actual bags through the admin.

Start the API:

```bash
npm run dev
```

Keep this terminal open. In a browser, open http://localhost:4000/health. You should see `{"status":"ok"}`. For a non-watching process, use `npm start`.

## 6. Start the React admin panel

Open another Terminal inside `my-ecommerce`:

```bash
cd admin-panel
npm ci
cp .env.example .env
npm run dev
```

On Windows PowerShell, use `Copy-Item .env.example .env` instead of `cp`.

Open http://localhost:5173. Sign in with the account created by `npm run admin`. The default `VITE_API_URL=http://localhost:4000/api/admin` is correct when the browser runs on your development computer.

The admin token is kept in tab-scoped session storage. Signing out or closing the session removes it. All admin routes independently check the database role; hiding a button is not the access-control mechanism.

## 7. Add your first product

1. Open **Categories**. The seeded hierarchy is already available. Add images for category tiles if desired.
2. Open **Products → Add product**.
3. Enter the name and a unique SKU, select a category, enter a positive whole-INR price and stock quantity.
4. Upload the main bag image. Optional gallery images are supported. JPEG/PNG/WebP, up to 5 MB per image. The backend decodes and re-encodes images to WebP.
5. Add description, material, dimensions and approved tags such as `New Drop` or `Bestseller`.
6. Leave **Published** enabled and click **Save product**.

“Archive” removes a product from customer listings without destroying order history. Editing it and checking Published restores it. A category cannot be deleted while it contains products or child categories.

Color swatches are descriptive options for the **same stock-tracked SKU**, matching the original Flutter model. If two bags require separate stock/pricing, create separate products/SKUs. Engraving is controlled per product; personalized order items are excluded from returns.

**Homepage** lets you upload campaign images and select featured products. With no custom featured sections, the backend supplies the latest 24 active products automatically. The original bundled editorial images remain fallbacks, not hardcoded saleable products.

## 8. Configure and run Flutter

Open another Terminal inside `my-ecommerce`:

```bash
cd mobile-app
flutter pub get
flutter devices
```

Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1/
```

iOS simulator:

```bash
cd ios
pod install
cd ..
flutter run --dart-define=API_BASE_URL=http://localhost:4000/api/v1/
```

Physical Android phone:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000/api/v1/
```

Use your real LAN address and keep the final `/` in `/api/v1/`. Allow incoming port 4000 in your computer firewall only for your local network. On iOS, allow the local-network prompt. For physical iOS devices where ATS rejects plain IP HTTP, use an HTTPS development endpoint and set `PUBLIC_URL` and `API_BASE_URL` to it. Do not disable ATS globally in a release build.

Android debug builds allow local HTTP; release builds retain HTTPS enforcement. Existing application IDs and signing setup are preserved. The inherited release configuration uses debug signing: configure your own upload signing before a store release.

Firebase is disabled by default (`ENABLE_FIREBASE=false`) so it cannot block local shopping. Existing client configuration files are retained as source context; do not assume they grant access to the old backend or Firebase project.

### Verify the complete local flow

1. Add a product in React admin with stock at least 2.
2. Open Flutter → Continue as Guest → Menu or Search. Search the product name.
3. Confirm its image, price and stock come from the admin entry.
4. Register a customer with a unique email/mobile and password of at least 8 characters.
5. Add the product to the bag; set quantity; add an address with a six-digit Indian pincode.
6. Choose **Cash on Delivery**, then place the order.
7. In admin **Orders**, open that order and confirm address, item, quantity and server-calculated total.
8. Update `received → processed → shipped → delivered`. Optionally enter tracking details with the transition.
9. Reopen Flutter Order History / Track Package. The updated status and timeline should appear.
10. Confirm stock decreased. Sign out/in to verify server-backed cart/wishlist isolation.

The project retains the original India/INR checkout assumptions. Prices and balances use whole rupees. Shipping uses configured flat rates, not live Shiprocket quotes. Tracking uses admin-entered courier data and order history. Postal autofill still uses the pre-existing public pincode lookup; you can enter address fields manually if it fails. Invoices show configured prices with no calculated GST; configure accounting/tax requirements before commercial use.

## 9. Cloud image storage

The default local storage is fully functional: uploaded files go to `backend/uploads` and are served from `/uploads`.

For Cloudinary:

1. Create your account at https://cloudinary.com/ and open its API credentials page.
2. Set `IMAGE_STORAGE=cloudinary` and your three Cloudinary variables in `backend/.env`.
3. Restart the backend.
4. Upload images through the admin as usual. The backend uploads to your `potli` folder and stores the returned HTTPS URL in MongoDB.

Never put the Cloudinary secret in React or Flutter. Existing local-image URLs are not migrated automatically. Archiving products retains their images for historic orders; there is no destructive cloud-image deletion operation.

## 10. Optional online payment and wallet

Core checkout works with COD. To enable Razorpay:

1. Use your own Razorpay account and test-mode keys.
2. Configure `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in backend `.env`.
3. Enable automatic capture in your Razorpay account.
4. Configure a public HTTPS webhook at `/api/webhooks/razorpay`, subscribe to `payment.captured`, and set the same `RAZORPAY_WEBHOOK_SECRET` on both sides.
5. Restart the API. Flutter fetches the public key through settings and shows the existing online-payment option.
6. Test payment success, cancellation, delayed capture and a repeated callback before switching to live keys.

The server creates provider orders with the database amount. Flutter sends the payment ID, provider order ID and signature. The backend validates HMAC and fetches the captured payment before updating an order or wallet. Wallet top-ups also have server-created provider orders. Repeated callbacks/webhooks are idempotent.

An order can be cancelled while payment is still pending. If a valid capture arrives after cancellation, the captured amount is credited once to the customer's wallet; it does not resurrect the cancelled stock reservation. Paid online orders cannot be cancelled through the simple status action; delivered-item returns issue store credit after admin completion. Bank/card refund automation is outside this store-credit policy. Unfinished online orders remain visible for support; they are not silently deleted.

Payment credentials and provider-side callbacks were not available in the build environment, so real gateway verification must be completed in your test account.

## 11. Optional Google sign-in and Firebase push

Google:

- Configure your Android/iOS OAuth clients and an appropriate server/web client in your own Google project.
- Put accepted server client IDs in backend `GOOGLE_CLIENT_IDS`.
- Run Flutter with `--dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_CLIENT_ID` in addition to the API URL.
- Register Android SHA fingerprints/iOS URL scheme as required by your project. The app sends an ID token; the backend verifies it with Google. A supplied email alone cannot authenticate.
- Existing password accounts are not silently linked by email. Use the password login for such accounts.

Push:

- Replace the existing Flutter Firebase configuration with your own project using FlutterFire configuration.
- Run with `--dart-define=ENABLE_FIREBASE=true`.
- Set `GOOGLE_APPLICATION_CREDENTIALS` to the local path of your own backend service-account file.
- Configure APNs in Firebase for iOS, request device notification permission, and test on real devices.
- Admin status updates create an in-app notification and attempt FCM delivery. An FCM failure does not roll back an order status.

## 12. API and database

See `docs/API.md` for every implemented endpoint and payload conventions. The mobile adapter uses the old endpoint names **only to preserve the Flutter screens**; its implementation is entirely Express + MongoDB.

The normal success envelope is:

```json
{"error":false,"message":"Success","data":[]}
```

Errors use a non-2xx status and `{"error":true,"message":"...","data":[]}`. Important statuses are 401 (sign-in required), 403 (role), 404 (missing/not owned), 409 (stock/state conflict), 422 (invalid input), and 429 (rate limit).

Models are in `backend/src/models/index.js`. ObjectIds identify users, products, categories and addresses. Each product is one stock-tracked variant, so its product and variant IDs match. Orders snapshot the product name/image/price and shipping address so later edits do not rewrite historical purchases.

Carts and wishlists have one record per user. Orders belong to users; all customer queries scope by authenticated user. Transactions, credits and returns retain references to their associated user/order. Checkout, cancellation and completed returns use database transactions. Server queries are built from validated scalar fields; request objects are not used directly as MongoDB queries.

## 13. Tests and troubleshooting

```bash
cd backend
npm test
npm run test:integration
```

`npm test` runs independent security/contract checks. `test:integration` starts a temporary MongoDB replica set with `mongodb-memory-server`; its first run downloads MongoDB. It tests registration, admin product uploads, Flutter response mapping, address isolation, cart/wishlist, order totals, concurrent stock protection, invoices, returns and support. It does not touch your configured store database.

React:

```bash
cd admin-panel
npm run build
```

Flutter:

```bash
cd mobile-app
flutter analyze
```

| Problem | Fix |
| --- | --- |
| JWT_SECRET error | Run `npm run setup`, or set a random secret of 32+ characters |
| MongoDB connection error | Start Docker, inspect `docker compose logs mongo`, verify URI and primary status |
| Replica set required | Use the provided Compose file or Atlas; standalone MongoDB cannot run transactions |
| Admin cannot call API | Check both servers and VITE_API_URL; restart Vite after changing `.env` |
| Origin not allowed | Add the exact React browser origin to ADMIN_ORIGINS |
| Phone cannot connect | Use computer LAN IP, same Wi-Fi, and check firewall; localhost is not your computer on a phone |
| Images do not load | Check PUBLIC_URL used at upload time; reupload images with a reachable host |
| Google sign-in unavailable | Configure OAuth IDs or use mobile/password login |
| Online payment unavailable | Configure Razorpay keys or use COD |
| No products | Publish a product, assign category, upload image, refresh/reopen collection |
| Category cannot be deleted | Reassign its products and remove child categories first |
| Product archive leaves image files | Intended: images may still be needed by historic orders |

## 14. Deploy later

This delivery does not publish or connect to your existing production store.

- Use a managed Node.js service or a server capable of running Node 22+. Install with `npm ci --omit=dev` and start with `npm start`; set its working directory to `backend`.
- Use MongoDB Atlas with least-privilege database credentials, IP/network restrictions and backups.
- Set `NODE_ENV=production`, a fresh JWT secret, HTTPS PUBLIC_URL and exact admin CORS origins. Store secrets in the hosting provider's environment, not Git.
- Use Cloudinary for persistent image storage, or a persistent upload volume if using local storage. Ephemeral server storage loses images on redeploy.
- Build React with a production `VITE_API_URL=https://your-api-domain/api/admin`; run `npm ci && npm run build` and deploy `dist` to a static host. Vite environment values are compiled into the browser bundle; they must never contain secrets.
- Configure your reverse proxy/load balancer carefully. The API does not blindly trust X-Forwarded-For. If you enable Express trust proxy, set it to the exact trusted proxy topology, not unrestricted `true`.
- Point Flutter release builds at `https://your-api-domain/api/v1/`, configure your own app signing/Firebase/OAuth, and make a device release test.
- Configure the Razorpay HTTPS webhook and live credentials only after successful test-mode verification.
- Set seller/tax details and store policies, verify order/refund procedures, add monitoring and backups, and run the integration suite against the code before real customer use.

## 15. Learning phase — afterward

Once your local flow succeeds, use this codebase in this order: `src/server.js` → `src/app.js` → `routes/` → `controllers/` → `services/` → `models/` → `config/database.js` → `middleware/auth.js` → React `src/api.js` → Flutter `lib/services/api/`. The source analysis and API reference explain file responsibilities without replacing the runnable code with a tutorial.
