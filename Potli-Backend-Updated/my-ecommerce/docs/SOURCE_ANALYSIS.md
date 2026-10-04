# Source analysis and implementation decisions

## Supplied application

The uploaded project contains 60 Dart files. It uses GetX controllers/dependency injection/navigation, GetStorage, HTTP services, Firebase Messaging, Google sign-in, Razorpay, PDF/printing, image picker and WebView dependencies. The checkout and product model use integer INR amounts.

The previous base URL was a remote PHP API. No existing production API was called or migrated. The Node backend starts with an empty store database. Existing photos/editorial assets and the Flutter presentation remain in the source.

| Existing files | Finding | Integration |
| --- | --- | --- |
| `lib/services/api/api_constants.dart` | PHP action-name endpoints | Configurable Node URL; retained only referenced action constants |
| `api_base_helper.dart` | Form POST and bearer token; logged request bodies, including passwords | Same form contract; safe messages; removed sensitive logging; accepts all 2xx |
| `auth_service.dart`, AuthController | Mobile/password auth; social login sent only email/name | Password hashing + JWT; verified Google ID token |
| `product.dart`, ProductService | First variant sets price/stock; optional sale price, tags, colors and engraving | One stock-tracked SKU per product; response includes first variant, image gallery and optional attributes |
| CategoryService, shop/discover views | L1 → L2 → L3 navigation | Category parent references, level validation, hierarchy seed, descendant product filters |
| HomeSection/HomeSlide and HomeView | CMS sections and sliders plus editorial asset fallbacks | Admin-managed homepage content; automatic latest-products section if none configured |
| CartController | Local state restored, writes sent to API, errors swallowed | Server hydration, error feedback, stock check, guest merge, local isolation on sign-out |
| WishlistController | Local IDs; cached products only | Server list/hydration and rollback on rejected changes |
| CheckoutView/OrderService | Client totals; unsafe two-step payment status + transaction submission | Server recalculation, transactional stock, idempotency key, captured-payment verification |
| AddressService | Address CRUD, India pincode | User-scoped MongoDB addresses; address snapshot on order |
| OrderSummary/Tracking/InvoiceData | Status history, courier URL, invoice DTO | Native response mapping, admin-controlled transitions, invoice totals from order snapshot |
| ReturnExchangeService | Delivered-item returns/exchanges and credit codes | Eligibility window, one request per item, admin processing, transactional restock and credit |
| WalletService | Direct payment ID and client amount | Server-created top-up reference, amount verification, unique payment transaction |
| SupportService | Tickets, text messages and optional images | Scoped tickets/messages, admin replies, image uploads |
| PushNotificationService | FCM registration and local notification presentation | Optional own-project Firebase; in-app notifications persist without FCM |
| `main.dart`, StorageService | Firebase required for launch; plaintext token storage | Optional Firebase; platform secure token storage; old backend token/cache migration |

## Server structure

- `src/routes`: method/path registration and authentication gates.
- `src/controllers`: transport mapping, parse accepted fields, serialize responses.
- `src/services`: authentication, catalog, shopping state, transactional ordering, payment verification, image storage, notification delivery.
- `src/models/index.js`: Mongoose schemas, references, unique indexes and JSON transforms. Grouped in one module to make the relationship map easy to inspect.
- `src/config`: validated environment and MongoDB connection requiring transaction support.
- `src/utils`: shared validation and centralized error handling.
- `scripts`: first administrator creation, category seed, environment setup.

## Deliberate scope

No new marketplace, seller, subscription or loyalty system was added. Existing app features determined the endpoints. Unused historical API constants (ratings/FAQs/brands/etc.) were removed rather than implementing unrelated systems.

The original UI models one default variant per product. Color swatches are descriptive; they do not choose a separately stocked variant. Products with separate stock should be separate SKUs. Prices are whole INR. Categories have at most three levels. Return completion issues store credit; it is not a bank-refund integration. Equal-price exchanges are supported; admin handles replacement shipment operationally.

Shipping is configured Standard/Express pricing. Tracking is real persisted order history plus admin-entered courier details, not live Shiprocket data. Existing external policy/website links and pincode autofill remain. The invoice does not calculate GST.

No production data or third-party credentials were available. All optional integrations use environment configuration and fail closed when unconfigured. Core COD checkout and local images do not require them.

## Data consistency

- Role comes from the user document; public registration never accepts a role.
- All customer data reads/writes include authenticated user ownership.
- Zod accepts known scalar/array fields; bodies are not MongoDB filter objects.
- Prices, discount, shipping, wallet and credit are computed/validated server-side.
- Stock is decremented with a guarded update inside a multi-document transaction.
- Checkout idempotency is per-user and indexed. A retry uses the same checkout key.
- Historical orders retain address and product snapshots.
- Cancellation restores inventory and originally debited wallet/credit atomically.
- Captured payment IDs are unique. Callback/webhook repeats cannot double-credit.
- Stock is not reserved merely by adding to a cart.
- Return completion, restock and issuing credit are in one transaction.
