import mongoose from "mongoose";
import { z } from "zod";
import { randomBytes } from "node:crypto";
import {
  Cart,
  Wishlist,
  Product,
  Order,
  Request,
  Credit,
} from "../models/index.js";
import { id, quantity } from "../utils/validation.js";
import { assert } from "../utils/errors.js";
import { env } from "../config/env.js";
import { productJson } from "./catalog.service.js";
export async function cart(user) {
  const c = await Cart.findOne({ user: user._id }).populate({
    path: "items.product",
    populate: { path: "category_id" },
  });
  return (c?.items || [])
    .filter((i) => i.product?.active)
    .map((i) => ({
      product: productJson(i.product),
      qty: i.quantity,
      personalization_text: i.personalization_text,
    }));
}
export async function updateCart(user, b, remove = false) {
  const productId = id.parse(b.product_variant_id);
  if (remove)
    return Cart.updateOne(
      { user: user._id },
      { $pull: { items: { product: productId } } },
    );
  const p = await Product.findOne({ _id: productId, active: true });
  assert(p, 404, "Product not found");
  const qty = remove ? 0 : quantity.parse(b.qty);
  assert(qty <= p.stock, 409, "Insufficient stock");
  const text =
    b.personalization_text === undefined
      ? undefined
      : z.string().max(3000).parse(b.personalization_text);
  assert(!text || p.allow_personalization, 422, "Personalization unavailable");
  await Cart.updateOne(
    { user: user._id },
    { $setOnInsert: { items: [] } },
    { upsert: true },
  );
  if (remove)
    return Cart.updateOne(
      { user: user._id },
      { $pull: { items: { product: productId } } },
    );
  const update = { "items.$.quantity": qty };
  if (text !== undefined) update["items.$.personalization_text"] = text;
  const result = await Cart.updateOne(
    { user: user._id, "items.product": productId },
    { $set: update },
  );
  if (!result.matchedCount)
    await Cart.updateOne(
      { user: user._id, "items.product": { $ne: productId } },
      {
        $push: {
          items: {
            product: productId,
            quantity: qty,
            personalization_text: text || "",
          },
        },
      },
    );
}
export async function favorites(user) {
  const w = await Wishlist.findOne({ user: user._id }).populate({
    path: "products",
    match: { active: true },
    populate: { path: "category_id" },
  });
  return (w?.products || []).map(productJson);
}
export async function favorite(user, b, remove = false) {
  const productId = id.parse(b.product_id);
  assert(
    await Product.exists({ _id: productId, active: true }),
    404,
    "Product not found",
  );
  await Wishlist.updateOne(
    { user: user._id },
    remove
      ? { $pull: { products: productId } }
      : { $addToSet: { products: productId } },
    { upsert: true },
  );
}
export async function submitRequest(user, b, kind) {
  const itemId = id.parse(b.order_item_id);
  const order = await Order.findOne({ user: user._id, "items._id": itemId });
  assert(
    order?.status === "delivered",
    409,
    "Only delivered orders are eligible",
  );
  const item = order.items.id(itemId);
  assert(
    item.is_returnable && !item.personalization_text,
    422,
    "This item is not eligible for return/exchange",
  );
  const date = order.history.find((x) => x.status === "delivered")?.date;
  assert(
    date && Date.now() - date.getTime() <= env.RETURN_WINDOW_DAYS * 86400000,
    422,
    "Return window has ended",
  );
  const reason = z.string().trim().min(3).max(500).parse(b[`${kind}_reason`]);
  let replacement = null;
  if (kind === "exchange") {
    replacement = await Product.findOne({
      _id: id.parse(b.exchange_for_variant_id),
      active: true,
      stock: { $gt: 0 },
    });
    assert(replacement, 409, "Replacement unavailable");
    assert(
      (replacement.special_price || replacement.price) === item.price,
      422,
      "Choose an equal-price replacement",
    );
  }
  return Request.create({
    user: user._id,
    order: order._id,
    order_item_id: itemId,
    kind,
    reason,
    customer_notes: z.string().max(2000).default("").parse(b.customer_notes),
    product_name: item.name,
    product_image: item.image,
    exchange_for_variant_id: replacement?._id,
  });
}
export const requestJson = (r) => ({
  ...r.toJSON(),
  order_id: String(r.order),
  return_reason: r.reason,
  exchange_reason: r.reason,
  status_label: r.status,
  date_created: r.createdAt.toISOString(),
});
export async function resolveRequest(requestId, status) {
  assert(
    ["approved", "rejected", "completed"].includes(status),
    422,
    "Invalid request status",
  );
  return mongoose.connection.transaction(async (session) => {
    const r = await Request.findById(id.parse(requestId)).session(session);
    assert(r, 404, "Request not found");
    assert(
      (r.status === "pending" && ["approved", "rejected"].includes(status)) ||
        (r.status === "approved" && status === "completed"),
      409,
      "Invalid request transition",
    );
    if (status === "completed") {
      const order = await Order.findById(r.order).session(session);
      const item = order.items.id(r.order_item_id);
      await Product.updateOne(
        { _id: item.product },
        { $inc: { stock: item.quantity } },
        { session },
      );
      if (r.kind === "return") {
        // Allocate discounted merchandise value proportionally. Never refund shipping or more than paid.
        const value = Math.max(
          0,
          Math.floor(
            (item.price *
              item.quantity *
              (order.total - order.promo_discount)) /
              order.total,
          ),
        );
        await Credit.create(
          [
            {
              user: r.user,
              request: r._id,
              code: `KF-${randomBytes(8).toString("hex").toUpperCase()}`,
              original_value: value,
              available_balance: value,
              expiry_date: new Date(Date.now() + 365 * 86400000),
            },
          ],
          { session },
        );
      } else {
        const replacement = await Product.findOneAndUpdate(
          {
            _id: r.exchange_for_variant_id,
            active: true,
            stock: { $gte: item.quantity },
          },
          { $inc: { stock: -item.quantity } },
          { session },
        );
        assert(replacement, 409, "Replacement stock unavailable");
      }
    }
    r.status = status;
    return r.save({ session });
  });
}
