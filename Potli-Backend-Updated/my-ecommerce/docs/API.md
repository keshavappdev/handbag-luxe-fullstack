# API reference

## Conventions

Mobile base: `http://localhost:4000/api/v1/`. Admin base: `http://localhost:4000/api/admin`.

Every mobile endpoint uses **POST** and accepts URL-encoded form fields (the Flutter contract) or JSON. Unless marked public, send `Authorization: Bearer YOUR_TOKEN`. Identity is always taken from the token; arbitrary `user_id` fields do not grant access.

Success: `{error:false,message:"Success",data:...}`. Validation/authorization/state failures return non-2xx statuses with `{error:true,message:"...",data:[]}`. MongoDB ObjectIds are strings. Mobile `product_variant_id` equals the product ID because one product is one SKU.

## Authentication and profile

| Endpoint | Access | Fields / output |
| --- | --- | --- |
| `register_user` | Public | name, email, mobile, password (8–72 chars); returns token and data:[user] |
| `login` | Public | mobile, password; returns token and data:[user] |
| `sign_up` | Public | id_token from Google; optional profile hints ignored for identity |
| `update_user` | User | Optional username, email, mobile; empty body fetches profile |
| `update_fcm` | User | fcm_id |
| `update_promo_preferences` | User | Optional subscribe_promo_email / subscribe_promo_whatsapp: "0" or "1" |

Public registration does not accept `role`. Password hashes are excluded from all JSON output. JWT is HS256 with issuer/audience validation. No production account is preconfigured.

## Catalog / homepage

| Endpoint | Access | Fields / output |
| --- | --- | --- |
| `get_products` | Public | Optional id, category_id, search, min_price, max_price, sort, limit, offset. sort = newest / price_asc / price_desc. data:[product], total |
| `get_categories` | Public | Root categories |
| `get_subcategories_by_category_id` | Public | category_id → direct children |
| `get_category_collection_items` | Public | sub_category_id → children; category_id accepted for Flutter compatibility |
| `get_sections` | Public | Featured sections with product_details; latest-products section when unconfigured |
| `get_slider_images` | Public | Ordered homepage campaign images |
| `get_complete_the_look` | Public | product_id → up to 8 related active products in same category |
| `get_personalization_settings` | Public | Enabled, heading, description, max_characters=20 |
| `get_settings` | Public | payment_method with COD and configured Razorpay visibility/public key |
| `save_personalization_preview` | User | image: base64 data URI for JPEG/PNG/WebP → data.path URL |

Product output includes id, name, category_id/name, description, material, dimensions, price, special_price, stock, image, other_images, sku, tags, variants, attributes and engraving settings. `variants[0].id` matches the product ID. Attributes use the existing Flutter color-swatch format.

Pagination defaults to 50 records and permits 1–200. Category filters include descendants. Search text is escaped before use in a regex. Sort fields are allowlisted.

## Shopping state and addresses

| Endpoint | Fields / output |
| --- | --- |
| `get_user_cart` | data:[{product,qty,personalization_text}] |
| `manage_cart` | product_variant_id, qty (1–99), optional personalization_text; sets quantity |
| `remove_from_cart` | product_variant_id |
| `get_favorites` | Product list |
| `add_to_favorites` / `remove_from_favorites` | product_id |
| `get_address` | User addresses |
| `add_address` | name, mobile, address, city_name, pincode; optional state, country, landmark, type, is_default |
| `update_address` | id plus same address fields |
| `delete_address` | id |
| `get_delivery_charge` | address_id; rates calculated from server cart; returns shipping_options.standard/express and COD/non-COD charges |
| `validate_promo_code` | promo_code; server cart determines eligible total; data:[{final_discount}] |
| `validate_credit_code` | code; owned active credit only |

Addresses are Indian-format with six-digit pincodes. `is_default` is a display field; the provided Flutter checkout selects the address explicitly. Cart additions do not reserve stock.

## Orders

`place_order` accepts:

```json
{
  "product_variant_id": "PRODUCT_OBJECT_ID_1,PRODUCT_OBJECT_ID_2",
  "quantity": "1,2",
  "address_id": "ADDRESS_OBJECT_ID",
  "payment_method": "COD",
  "shipping_type": "Standard",
  "idempotency_key": "unique-checkout-attempt-id"
}
```

Replace the explanatory identifiers with actual IDs returned by the API. Optional: promo_code, credit_code, wallet_balance_used, personalization_text (JSON string mapping product IDs to text/preview envelopes). An `Idempotency-Key` HTTP header can be used instead of the body field. Keep the same key for a network retry; use a new key for a new order.

Client-submitted totals, tax amounts and delivery charges are not authoritative. The server loads active products and their prices, validates the owned address, deducts stock, applies discounts and balances, creates the snapshot order and clears the cart transactionally. It returns root `order_id` and `final_total`.

| Endpoint | Fields / output |
| --- | --- |
| `get_orders` | Optional limit/offset; newest first, Flutter order_items format |
| `update_order_status` | order_id/status. Customer cancellation allowed for awaiting/received; received acknowledgment requires already verified paid order |
| `delete_order` | order_id; compatibility alias for cancellation, never destructive deletion |
| `get_order_tracking` | order_id; root current_status, courier fields and timeline; source="order" |
| `get_invoice_data` | order_id; seller, buyer, items and totals from stored snapshot |
| `get_invoice_html` | order_id; escaped HTML in data |
| `get_notifications` | Most recent 100 owned notifications |

Normal fulfilment: received → processed → shipped → delivered. Awaiting means payment is pending. Cancellation before shipment restores stock and used wallet/credit once. Admin cannot mark an unpaid awaiting online order received simply by changing its status.

## Payments and wallet

| Endpoint | Fields / output |
| --- | --- |
| `razorpay_create_order` | order_id → Razorpay order id, amount in paise, currency |
| `create_wallet_order` | amount, positive whole INR up to 100000 → provider order |
| `verify_payment` | payment_id, razorpay_order_id, signature; order owner is verified |
| `add_transaction` | Compatibility alias for verified payment; accepts txn_id as payment_id; never trusts claimed amount/status |
| `transactions` | Wallet balance at root, data:[credit/debit ledger entries] |

Webhook: **POST `/api/webhooks/razorpay`**, raw JSON + `x-razorpay-signature`. Only properly signed `payment.captured` events settle payments. The order/top-up amount must match. Repeats are idempotent. Late captured payments for cancelled orders become wallet credit once. External payment tests require your account.

## Returns / exchanges / support

| Endpoint | Fields / output |
| --- | --- |
| `submit_return_request` | order_item_id, return_reason, optional customer_notes |
| `submit_exchange_request` | order_item_id, exchange_for_variant_id, exchange_reason, optional customer_notes |
| `get_my_return_requests` / `get_my_exchange_requests` | Owned requests and status labels |
| `get_exchange_variants` | order_item_id → equal-price available product options |
| `get_my_potli_credits` | Owned credit codes, balances and expiry |
| `get_ticket_types` | Public; orders/general |
| `add_ticket` | ticket_type_id, subject, email, description |
| `get_tickets` | Optional limit/offset |
| `edit_ticket` | ticket_id, status "3"=resolved / "5"=reopened |
| `get_messages` | ticket_id; chronological, up to 200 |
| `send_message` | ticket_id, message; multipart supports up to five attachments[] images |

Returns require delivered, returnable, non-personalized items within the configured window. Only one return/exchange request per order item is allowed. Completion after physical inspection restores inventory and issues proportionally discounted merchandise store credit, excluding shipping. Equal-price exchanges deduct replacement stock. Credits are private to their user.

## Admin REST endpoints

`POST /login` accepts email/password. All other endpoints require an authenticated admin. Creation returns 201 where appropriate; edits generally return 200.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | /me | Current admin |
| GET | /dashboard | Counts, collected cash/online revenue, low stock |
| GET / POST | /products | List / create product |
| PUT / DELETE | /products/:id | Full validated edit / archive |
| GET / POST | /categories | List / create category |
| PUT / DELETE | /categories/:id | Edit / delete empty category |
| POST | /images | Multipart image field → data.url |
| GET | /customers | Paginated customers |
| GET | /orders | Paginated orders |
| GET | /orders/:id | Detail, shipping snapshot and history |
| PATCH | /orders/:id/status | status; optional tracking_id, tracking_url, courier_agency |
| GET | /tickets | Latest 200 tickets |
| GET / POST | /tickets/:id/messages | Conversation / reply with message and status |
| GET | /requests | Latest 200 returns/exchanges |
| PATCH | /requests/:id | status: approved/rejected/completed, transition checked |
| GET / POST | /content/:kind | List / create slides, sections or promos |
| PUT / DELETE | /content/:kind/:id | Edit / remove content |

Product write fields: name, category_id, description, material, dimensions, image, other_images, price, special_price, stock, sku, brand, tags, active, allow_personalization, personalize_image, personalize_text_x/y/width/color, colors:[{name,hex}], is_returnable. UI forms supply the defaults. Whole-INR sale price must be zero or less than regular price.

Category writes: name, parent_id (null for root), image, banner. Maximum level 3; an existing category's parent is immutable to prevent hierarchy cycles.

Slide writes: title, subtitle, button_text, type (`products`/`categories`/`default`), type_id, image, link, position. Section writes: title, short_description, style (`default`/`style_1`…`style_4`), products:[ObjectId], position. Promo writes: code, percent, minimum, expires, active.

`GET /health` returns 200 only when MongoDB is connected. `GET /uploads/:filename` serves local, re-encoded uploaded images.
