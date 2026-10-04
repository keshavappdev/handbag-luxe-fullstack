# POTLI Flutter ↔ Backend API Audit

Backend reviewed: `my-ecommerce/backend` supplied with this task.

## Confirmed transport contract

- Mobile base path: `/api/v1/`
- Local backend port in the supplied `.env`: `4000`
- Every mobile API endpoint is `POST`.
- Public endpoints are registered before auth middleware.
- Private endpoints require `Authorization: Bearer <JWT>`.
- Flutter uses URL-encoded form posts, which the backend accepts via `express.urlencoded(...)`.
- Standard success envelope: `{ "error": false, "message": "Success", "data": ... }` with some endpoints adding root fields such as `total`, `order_id`, `final_total`, `balance`, tracking fields, etc.
- Standard error envelope: `{ "error": true, "message": "...", "data": [] }` with non-2xx status codes.

All 54 mobile backend handlers now have a matching Flutter endpoint constant. There are no Flutter-only or backend-only mobile endpoint names in the audited set.

## Product / filter contract

There is no separate Filter endpoint. Filtering is implemented by:

`POST /api/v1/get_products`

Supported fields from the backend implementation:

- `id`
- `category_id`
- `search`
- `min_price`
- `max_price`
- `sort`
- `limit`
- `offset`

Supported `sort` values:

- `newest`
- `price_asc`
- `price_desc`

Category filtering includes descendants. Search is a case-insensitive escaped regex against the product **name**. Price filtering uses the backend product `price` field. Pagination allows 1–200 items per request.

Flutter `ProductService.getProducts()` now passes the backend-supported `min_price`, `max_price`, and `sort` fields, and no longer sends the unsupported legacy `is_detailed_data` field.

## API fixes made in Flutter

1. **Empty POST body handling**
   - Before: `ApiBaseHelper` omitted the body completely when the parameter map was empty.
   - Backend impact: Express leaves `req.body` undefined when no form/JSON body is sent. This can break APIs that intentionally accept an empty body and still inspect `req.body`, including profile fetch through `update_user` and promo preference fetch through `update_promo_preferences`.
   - Fix: Flutter now always sends the parameter map, including `{}`, as a URL-encoded form POST.

2. **Filter API integration**
   - Added Flutter support for `min_price`, `max_price`, and `sort` on `get_products`.
   - Category, search, id, pagination behavior remains unchanged.

3. **Cart personalization clearing**
   - Before: Flutter omitted `personalization_text` when the new value was an empty string.
   - Backend behavior: missing field means "leave existing personalization unchanged"; empty string means "clear it".
   - Fix: Flutter now sends `personalization_text: ""` when the user explicitly clears personalization.

4. **Authentication/profile request fields**
   - `sign_up` now sends only the Google `id_token` that the backend actually verifies.
   - `register_user` no longer sends unsupported `country_code`.
   - `update_user` no longer sends `user_id`; the backend correctly derives the user from the Bearer token.

5. **Order placement request**
   - Removed legacy client-authoritative fields that the supplied backend ignores: submitted totals, tax values, delivery overrides, mobile, `is_wallet_used`, `local_pickup`, and `active_status`.
   - Flutter now sends only the backend-supported order fields. Server pricing, shipping, discount, stock, wallet/credit use, and order state remain authoritative.
   - Zero-payable Razorpay-selected orders are not redundantly marked received; the backend already creates them as paid/received when payable is zero.

6. **Payment endpoints**
   - Added explicit constants for `create_wallet_order` and `verify_payment` instead of constructing those URLs inline.
   - Wallet payment confirmation now sends only the fields the backend verifies: payment id, Razorpay order id, and signature.

7. **Other request cleanup**
   - `get_category_collection_items` now sends only the backend-required `sub_category_id`; the parent `category_id` remains local to the Flutter fallback logic and is no longer sent as an ignored request field.
   - Removed unsupported `pincode_name` from address requests.
   - `get_sections` no longer sends ignored `limit` / `p_limit` fields.
   - `get_settings` no longer sends an ignored `type` field.
   - Ticket status/message requests no longer send ignored legacy fields.
   - Wallet transaction reads no longer send ignored `transaction_type`.
   - Delivery charge and promo validation no longer send client totals; the backend derives totals from the authenticated cart.

8. **Local image URL compatibility**
   - The supplied backend development config returns local uploaded images using `PUBLIC_URL=http://localhost:4000`.
   - Android emulators reach the host through `10.0.2.2`, so Flutter now rebases only loopback image URLs onto the configured `API_BASE_URL` origin. External/production image URLs are left unchanged.

## Base URL

Flutter default:

`http://10.0.2.2:4000/api/v1/`

This correctly targets a backend running on the development machine from an Android emulator. For iOS simulator, physical devices, staging, or production, provide the reachable backend URL with:

`--dart-define=API_BASE_URL=https://your-host/api/v1/`

The backend itself mounts mobile routes at `/api/v1`, so that path is correct.

## Confirmed unchanged integrations

The endpoint names and response mapping for categories/subcategories, product detail, search, sections, sliders, favorites, cart, addresses, orders, tracking, invoice, notifications, returns/exchanges, store credit, support tickets/messages, FCM, settings, wallet, Razorpay order creation, and payment verification are consistent with the supplied backend after the fixes above.



## Verification notes

- Backend source JavaScript syntax checks passed with `node --check`.
- Static endpoint-name comparison passed: 54 Flutter constants ↔ 54 backend mobile handlers, no differences.
- The supplied backend test dependencies contain a platform-specific `sharp` binary that cannot load in this Linux environment, so the backend Node test suite could not be executed here without reinstalling platform-specific optional dependencies.
- A Flutter SDK is not installed in this execution environment, so `flutter analyze` / device builds could not be run here. Changes were kept to API/service/controller integration and do not alter the visual UI.
