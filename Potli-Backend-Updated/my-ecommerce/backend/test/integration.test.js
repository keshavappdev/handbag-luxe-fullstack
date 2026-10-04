import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { MongoMemoryReplSet } from "mongodb-memory-server";
import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import request from "supertest";
let repl,
  app,
  M,
  adminToken,
  customerToken,
  otherToken,
  categoryId,
  productId,
  addressId,
  orderId;
const post = (path, body = {}, token = customerToken) =>
  request(app)
    .post(`/api/v1/${path}`)
    .set("Authorization", `Bearer ${token || ""}`)
    .send(body);
const admin = (method, path, body) =>
  request(app)
    [method](`/api/admin${path}`)
    .set("Authorization", `Bearer ${adminToken}`)
    .send(body);
before(
  async () => {
    process.env.NODE_ENV = "test";
    process.env.JWT_SECRET = "test-secret-only-012345678901234567890123456789";
    repl = await MongoMemoryReplSet.create({
      replSet: { count: 1 },
      binary: { version: process.env.TEST_MONGODB_VERSION || "7.0.14" },
    });
    process.env.MONGODB_URI = repl.getUri("potli_test");
    ({ app } = await import("../src/app.js"));
    M = await import("../src/models/index.js");
    const { connectDatabase } = await import("../src/config/database.js");
    await connectDatabase();
    await M.User.create({
      username: "Admin",
      email: "admin@example.test",
      password: await bcrypt.hash("StrongPassword123", 12),
      role: "admin",
    });
    const a = await request(app)
      .post("/api/admin/login")
      .send({ email: "admin@example.test", password: "StrongPassword123" });
    assert.equal(a.status, 200);
    adminToken = a.body.token;
  },
  { timeout: 180000 },
);
after(async () => {
  await mongoose.disconnect();
  await repl?.stop();
});
test("registration, login and role boundary", async () => {
  const r = await post("register_user", {
    name: "Customer",
    email: "customer@example.test",
    mobile: "9876543210",
    password: "Password123",
  });
  assert.equal(r.status, 200);
  assert.ok(r.body.token);
  assert.equal(r.body.data[0].password, undefined);
  customerToken = r.body.token;
  const other = await post("register_user", {
    name: "Other",
    email: "other@example.test",
    mobile: "9876543211",
    password: "Password123",
  });
  otherToken = other.body.token;
  assert.equal(
    (await post("login", { mobile: "9876543210", password: "Password123" }))
      .status,
    200,
  );
  assert.equal(
    (
      await request(app)
        .get("/api/admin/products")
        .set("Authorization", `Bearer ${customerToken}`)
    ).status,
    403,
  );
  assert.equal(
    (await post("login", { mobile: { $ne: null }, password: "x" })).status,
    422,
  );
  assert.equal((await post("get_orders", {}, "")).status, 401);
});
test("admin category + upload + product appears in Flutter contract", async () => {
  const c = await admin("post", "/categories", {
    name: "Bags",
    parent_id: null,
  });
  assert.equal(c.status, 201);
  categoryId = c.body.data.id;
  const sharp = (await import("sharp")).default;
  const png = await sharp({
    create: { width: 50, height: 50, channels: 3, background: "#886644" },
  })
    .png()
    .toBuffer();
  const img = await request(app)
    .post("/api/admin/images")
    .set("Authorization", `Bearer ${adminToken}`)
    .attach("image", png, "bag.png");
  assert.equal(img.status, 201);
  const p = await admin("post", "/products", {
    name: "Studio Tote",
    sku: "ST-01",
    category_id: categoryId,
    price: 2000,
    stock: 5,
    image: img.body.data.url,
    description: "Bag description",
  });
  assert.equal(p.status, 201);
  productId = p.body.data.id;
  const list = await post("get_products", { search: "Studio" });
  assert.equal(list.body.data[0].id, productId);
  assert.equal(list.body.data[0].variants[0].price, 2000);
  assert.equal(list.body.data[0].category_name, "Bags");
  const imageResponse = await request(app).get(
    new URL(img.body.data.url).pathname,
  );
  assert.equal(imageResponse.status, 200);
  assert.match(imageResponse.headers["content-type"], /webp/);
  assert.equal(
    (await post("get_sections")).body.data[0].product_details[0].id,
    productId,
  );
});
test("cart, wishlist and address ownership", async () => {
  assert.equal(
    (await post("manage_cart", { product_variant_id: productId, qty: 2 }))
      .status,
    200,
  );
  assert.equal((await post("get_user_cart")).body.data[0].qty, 2);
  assert.equal(
    (await post("manage_cart", { product_variant_id: productId, qty: -2 }))
      .status,
    422,
  );
  assert.equal(
    (await post("add_to_favorites", { product_id: productId })).status,
    200,
  );
  assert.equal((await post("get_favorites")).body.data.length, 1);
  const a = await post("add_address", {
    name: "Customer",
    mobile: "9876543210",
    address: "12 Main Road",
    city_name: "Delhi",
    pincode: "110001",
  });
  addressId = a.body.data[0].id;
  assert.equal(
    (await post("delete_address", { id: addressId }, otherToken)).status,
    404,
  );
  assert.equal((await post("get_address", {}, otherToken)).body.data.length, 0);
});
test("server totals, idempotency and inventory", async () => {
  const body = {
    product_variant_id: productId,
    quantity: "2",
    address_id: addressId,
    payment_method: "COD",
    total: "1",
    final_total: "1",
    delivery_charge: "0",
    idempotency_key: "checkout-one",
  };
  const r = await post("place_order", body);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  orderId = r.body.order_id;
  assert.equal(r.body.final_total, 4000);
  assert.equal((await M.Product.findById(productId)).stock, 3);
  const duplicate = await post("place_order", body);
  assert.equal(duplicate.body.order_id, orderId);
  assert.equal((await M.Product.findById(productId)).stock, 3);
  assert.equal((await post("get_user_cart")).body.data.length, 0);
  const invoice = await post("get_invoice_data", { order_id: orderId });
  assert.equal(invoice.body.data.totals.final_total, 4000);
  assert.equal(
    (await post("get_invoice_data", { order_id: orderId }, otherToken)).status,
    404,
  );
  assert.equal(
    (
      await post("update_order_status", {
        order_id: orderId,
        status: "shipped",
      })
    ).status,
    403,
  );
});
test("concurrent checkout cannot oversell; failed transaction rolls back", async () => {
  const b = {
    product_variant_id: productId,
    quantity: "2",
    address_id: addressId,
    payment_method: "COD",
  };
  const results = await Promise.all([
    post("place_order", { ...b, idempotency_key: "race-one" }),
    post("place_order", { ...b, idempotency_key: "race-two" }),
  ]);
  assert.deepEqual(results.map((x) => x.status).sort(), [200, 409]);
  assert.equal((await M.Product.findById(productId)).stock, 1);
  const fail = await post("place_order", {
    ...b,
    quantity: "1",
    wallet_balance_used: "999999",
    idempotency_key: "bad-wallet",
  });
  assert.equal(fail.status, 422);
  assert.equal((await M.Product.findById(productId)).stock, 1);
});
test("order transitions, tracking, return credit issued once", async () => {
  for (const status of ["processed", "shipped", "delivered"])
    assert.equal(
      (await admin("patch", `/orders/${orderId}/status`, { status })).status,
      200,
    );
  assert.equal(
    (await post("get_order_tracking", { order_id: orderId })).body
      .current_status,
    "delivered",
  );
  const order = (await post("get_orders")).body.data.find(
    (o) => o.id === orderId,
  );
  assert.equal(order.order_items[0].active_status, "delivered");
  const r = await post("submit_return_request", {
    order_item_id: order.order_items[0].id,
    return_reason: "Item not suitable",
  });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const rid = r.body.data.id;
  assert.equal(
    (await admin("patch", `/requests/${rid}`, { status: "approved" })).status,
    200,
  );
  assert.equal(
    (await admin("patch", `/requests/${rid}`, { status: "completed" })).status,
    200,
  );
  assert.equal(
    (await admin("patch", `/requests/${rid}`, { status: "completed" })).status,
    409,
  );
  const credits = await post("get_my_potli_credits");
  assert.equal(credits.body.data[0].available_balance, 4000);
  assert.equal((await M.Product.findById(productId)).stock, 3);
  assert.equal(
    (
      await post(
        "validate_credit_code",
        { code: credits.body.data[0].code },
        otherToken,
      )
    ).status,
    422,
  );
});
test("support ticket messages and access controls", async () => {
  const t = await post("add_ticket", {
    ticket_type_id: "orders",
    subject: "Delivery question",
    email: "customer@example.test",
    description: "Please check my order",
  });
  const tid = t.body.data[0].id;
  assert.equal(
    (await post("send_message", { ticket_id: tid, message: "Hello" })).status,
    200,
  );
  assert.equal(
    (await post("get_messages", { ticket_id: tid }, otherToken)).status,
    404,
  );
  assert.equal(
    (
      await admin("post", `/tickets/${tid}/messages`, {
        message: "We are checking",
        status: "2",
      })
    ).status,
    201,
  );
  assert.equal(
    (await post("get_messages", { ticket_id: tid })).body.data.length,
    2,
  );
});
test("unsafe payment requests and email-only social login are rejected", async () => {
  assert.equal(
    (await post("add_transaction", { txn_id: "pay_fake", amount: "1000" }))
      .status,
    422,
  );
  assert.equal(
    (
      await post("update_order_status", {
        order_id: orderId,
        status: "received",
      })
    ).status,
    409,
  );
  assert.equal(
    (
      await post("sign_up", {
        type: "google",
        email: "customer@example.test",
        name: "Customer",
      })
    ).status,
    503,
  );
  assert.equal(
    (
      await request(app)
        .post("/api/webhooks/razorpay")
        .send({ event: "payment.captured" })
    ).status,
    400,
  );
  assert.equal((await post("transactions")).body.balance, 0);
});
