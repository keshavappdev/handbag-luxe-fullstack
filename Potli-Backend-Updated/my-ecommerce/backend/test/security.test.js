import { test } from "node:test";
import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import request from "supertest";
process.env.NODE_ENV = "test";
process.env.JWT_SECRET = "test-secret-012345678901234567890123456789";
process.env.MONGODB_URI = "mongodb://127.0.0.1:27017/unused";
const { app } = await import("../src/app.js");
const { validSignature } = await import("../src/services/payment.service.js");
const { productSchema } = await import("../src/utils/validation.js");
const { productJson } = await import("../src/services/catalog.service.js");
const { shipping } = await import("../src/services/order.service.js");
test("payment signature rejects tampering and malformed input", () => {
  const secret = "unit-secret";
  const payload = "order_abc|pay_abc";
  const signature = createHmac("sha256", secret).update(payload).digest("hex");
  assert.equal(validSignature(payload, signature, secret), true);
  assert.equal(validSignature("order_other|pay_abc", signature, secret), false);
  assert.equal(validSignature(payload, "xyz", secret), false);
});
test("product validation prevents negative stock, invalid pricing and URL schemes", () => {
  const p = {
    name: "Tote",
    sku: "T1",
    category_id: "a".repeat(24),
    price: 100,
    stock: 2,
    image: "https://example.com/bag.webp",
  };
  assert.ok(productSchema.parse(p));
  for (const change of [
    { stock: -1 },
    { price: -1 },
    { special_price: 101 },
    { image: "javascript:alert(1)" },
    { category_id: { $ne: null } },
  ])
    assert.equal(productSchema.safeParse({ ...p, ...change }).success, false);
});
test("serializer matches Flutter product model", () => {
  const p = productJson({
    _id: "a".repeat(24),
    name: "Bag",
    category_id: { _id: "b".repeat(24), name: "Totes" },
    price: 2000,
    special_price: 1800,
    stock: 5,
    allow_personalization: true,
    colors: [{ name: "Black", hex: "#000000" }],
  });
  assert.equal(p.id, "a".repeat(24));
  assert.equal(p.variants[0].id, p.id);
  assert.equal(p.category_name, "Totes");
  assert.equal(p.allow_personalization, "1");
  assert.equal(p.attributes[0].swatche_type[0], "1");
});
test("server shipping policy has exact threshold and express charge", () => {
  assert.equal(shipping(2998), 99);
  assert.equal(shipping(2999), 0);
  assert.equal(shipping(4000, "Express"), 199);
});
test("protected customer/admin routes reject missing token", async () => {
  assert.equal(
    (
      await request(app)
        .post("/api/v1/get_orders")
        .send({ user_id: "a".repeat(24) })
    ).status,
    401,
  );
  assert.equal((await request(app).get("/api/admin/products")).status, 401);
});
test("invalid registration and forged webhook fail before database access", async () => {
  assert.equal(
    (
      await request(app)
        .post("/api/v1/register_user")
        .send({ name: "A", password: "short" })
    ).status,
    422,
  );
  assert.equal(
    (
      await request(app)
        .post("/api/webhooks/razorpay")
        .send({ event: "payment.captured" })
    ).status,
    400,
  );
});
test("CORS rejects unknown browser origin; health accurately reports disconnected database", async () => {
  assert.equal(
    (
      await request(app)
        .get("/health")
        .set("Origin", "https://untrusted.example")
    ).status,
    403,
  );
  assert.equal((await request(app).get("/health")).status, 503);
});

test('populated Mongoose category serialization retains its ID',async()=>{const {Product,Category}=await import('../src/models/index.js');const category=new Category({name:'Totes'});const product=new Product({name:'Bag',category_id:category,price:100,stock:1});const mapped=productJson(product);assert.equal(mapped.category_id,String(category._id));assert.equal(mapped.category_name,'Totes');});
