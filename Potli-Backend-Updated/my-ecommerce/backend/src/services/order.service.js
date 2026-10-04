import mongoose from "mongoose";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import {
  Address,
  Product,
  Order,
  Cart,
  User,
  Credit,
  Promo,
  Transaction,
  Request,
  Notification,
} from "../models/index.js";
import { id, quantity } from "../utils/validation.js";
import { assert } from "../utils/errors.js";
import { env, onlinePayments } from "../config/env.js";
export const shipping = (total, type = "Standard") =>
  type === "Express"
    ? env.SHIPPING_EXPRESS
    : total >= env.FREE_SHIPPING_THRESHOLD
      ? 0
      : env.SHIPPING_STANDARD;
export async function promoDiscount(code, total, session) {
  if (!code) return 0;
  const promo = await Promo.findOne({
    code: String(code).toUpperCase(),
    active: true,
    expires: { $gt: new Date() },
  }).session(session || null);
  assert(
    promo && total >= promo.minimum,
    422,
    "Promo code is invalid, expired, or minimum not reached",
  );
  return Math.floor((total * promo.percent) / 100);
}
export async function ownedOrder(user, orderId, session) {
  const order = await Order.findOne({
    _id: id.parse(orderId),
    user: user._id,
  }).session(session || null);
  assert(order, 404, "Order not found");
  return order;
}
export async function placeOrder(user, b, key) {
  const ids = z
    .string()
    .max(3000)
    .parse(b.product_variant_id)
    .split(",")
    .map((x) => id.parse(x));
  const quantities = z
    .string()
    .max(1000)
    .parse(b.quantity)
    .split(",")
    .map((x) => quantity.parse(x));
  assert(
    ids.length &&
      ids.length <= 50 &&
      ids.length === quantities.length &&
      new Set(ids).size === ids.length,
    422,
    "Invalid or duplicate cart items",
  );
  const addressId = id.parse(b.address_id),
    method = z.enum(["COD", "razorpay"]).parse(b.payment_method),
    type = z
      .enum(["Standard", "Express"])
      .default("Standard")
      .parse(b.shipping_type);
  const idem = z
    .string()
    .min(8)
    .max(100)
    .parse(key || b.idempotency_key || randomUUID());
  let personalization = {};
  if (b.personalization_text) {
    try {
      personalization = JSON.parse(b.personalization_text);
    } catch {
      assert(false, 422, "Invalid personalization");
    }
    personalization = z.record(z.string().max(3000)).parse(personalization);
  }
  return mongoose.connection.transaction(async (session) => {
    const existing = await Order.findOne({
      user: user._id,
      idempotencyKey: idem,
    }).session(session);
    if (existing) return existing;
    const address = await Address.findOne({
      _id: addressId,
      user: user._id,
    }).session(session);
    assert(address, 404, "Address not found");
    const items = [];
    let total = 0;
    for (let i = 0; i < ids.length; i++) {
      const p = await Product.findOneAndUpdate(
        { _id: ids[i], active: true, stock: { $gte: quantities[i] } },
        { $inc: { stock: -quantities[i] } },
        { new: true, session },
      );
      assert(p, 409, "A product is unavailable or has insufficient stock");
      const text = personalization[ids[i]] || "";
      assert(
        !text || p.allow_personalization,
        422,
        "This product does not support personalization",
      );
      if (text) {
        let raw = text;
        try {
          raw = JSON.parse(text).text || "";
        } catch {}
        assert(
          [...raw].length <= 20,
          422,
          "Personalization is limited to 20 characters",
        );
      }
      const price = p.special_price > 0 ? p.special_price : p.price;
      items.push({
        product: p._id,
        name: p.name,
        image: p.image,
        quantity: quantities[i],
        price,
        is_returnable: p.is_returnable,
        personalization_text: text,
      });
      total += price * quantities[i];
    }
    const delivery = shipping(total, type),
      discount = await promoDiscount(b.promo_code, total, session);
    let payable = total + delivery - discount,
      creditUsed = 0,
      credit = null;
    if (b.credit_code) {
      credit = await Credit.findOne({
        user: user._id,
        code: z.string().max(100).parse(b.credit_code),
        status: "active",
        expiry_date: { $gt: new Date() },
      }).session(session);
      assert(
        credit && credit.available_balance > 0,
        422,
        "Invalid or exhausted credit code",
      );
      creditUsed = Math.min(credit.available_balance, payable);
      credit.available_balance -= creditUsed;
      await credit.save({ session });
      payable -= creditUsed;
    }
    const wallet = z.coerce
      .number()
      .int()
      .nonnegative()
      .max(payable)
      .default(0)
      .parse(b.wallet_balance_used);
    if (wallet) {
      const debited = await User.findOneAndUpdate(
        { _id: user._id, balance: { $gte: wallet } },
        { $inc: { balance: -wallet } },
        { session },
      );
      assert(debited, 409, "Insufficient wallet balance");
      payable -= wallet;
    }
    assert(
      method !== "razorpay" || onlinePayments || payable === 0,
      422,
      "Online payments are not configured. Choose Cash on Delivery.",
    );
    const status =
      method === "razorpay" && payable > 0 ? "awaiting" : "received";
    const [order] = await Order.create(
      [
        {
          user: user._id,
          idempotencyKey: idem,
          items,
          address: address.toObject(),
          total,
          delivery_charge: delivery,
          promo_discount: discount,
          credit: credit?._id,
          credit_used: creditUsed,
          wallet_used: wallet,
          final_total: payable,
          shipping_type: type,
          payment_method: method,
          payment_status: payable === 0 ? "paid" : "unpaid",
          status,
          history: [{ status, date: new Date() }],
        },
      ],
      { session },
    );
    if (wallet)
      await Transaction.create(
        [
          {
            user: user._id,
            type: "debit",
            amount: wallet,
            message: "Order purchase",
            order: order._id,
          },
        ],
        { session },
      );
    await Cart.updateOne(
      { user: user._id },
      { $set: { items: [] } },
      { session },
    );
    return order;
  });
}
export async function orderJson(order) {
  const requests = await Request.find({ order: order._id });
  const x = order.toJSON();
  return {
    ...x,
    active_status: x.status,
    date_added: order.createdAt.toISOString(),
    address: [
      x.address.name,
      x.address.address,
      x.address.city_name,
      x.address.state,
      x.address.pincode,
    ]
      .filter(Boolean)
      .join(", "),
    url: x.tracking_url || "",
    order_items: order.items.map((item) => {
      const r = requests.find((r) => r.order_item_id === String(item._id));
      return {
        id: String(item._id),
        name: item.name,
        image: item.image,
        quantity: item.quantity,
        price: item.price,
        active_status: order.status,
        product_is_returnable: item.is_returnable ? "1" : "0",
        personalization_text: item.personalization_text,
        return_request_submitted: r?.kind === "return" ? r.status : "",
        exchange_request_submitted: r?.kind === "exchange" ? r.status : "",
      };
    }),
  };
}
const transitions = {
  awaiting: ["cancelled"],
  received: ["processed", "cancelled"],
  processed: ["shipped", "cancelled"],
  shipped: ["delivered"],
  delivered: [],
  cancelled: [],
};
export async function changeStatus(orderId, status, actor, tracking = {}) {
  return mongoose.connection.transaction(async (session) => {
    const order = await Order.findById(id.parse(orderId)).session(session);
    assert(order, 404, "Order not found");
    assert(
      actor.role === "admin" || String(order.user) === String(actor._id),
      404,
      "Order not found",
    );
    if (order.status === status) return order;
    assert(
      actor.role === "admin" ||
        (status === "cancelled" &&
          ["awaiting", "received"].includes(order.status)),
      403,
      "This transition requires an administrator",
    );
    assert(
      transitions[order.status]?.includes(status),
      409,
      `Cannot change ${order.status} to ${status}`,
    );
    // Awaiting online payment must be reconciled, not cancelled while a charge may complete.

    if (status === "cancelled") {
      assert(
        order.payment_method !== "razorpay" || order.payment_status !== "paid",
        409,
        "Paid online orders require a verified refund first",
      );
      for (const item of order.items)
        await Product.updateOne(
          { _id: item.product },
          { $inc: { stock: item.quantity } },
          { session },
        );
      if (order.credit_used)
        await Credit.updateOne(
          { _id: order.credit },
          { $inc: { available_balance: order.credit_used } },
          { session },
        );
      if (order.wallet_used) {
        await User.updateOne(
          { _id: order.user },
          { $inc: { balance: order.wallet_used } },
          { session },
        );
        await Transaction.create(
          [
            {
              user: order.user,
              type: "credit",
              amount: order.wallet_used,
              message: "Cancelled order refund",
              order: order._id,
            },
          ],
          { session },
        );
      }
    }
    Object.assign(order, tracking);
    order.status = status;
    if (status === "delivered" && order.payment_method === "COD")
      order.payment_status = "paid";
    order.history.push({ status, date: new Date() });
    await order.save({ session });
    await Notification.create(
      [
        {
          user: order.user,
          title: "Order update",
          message: `Your order is ${status}`,
          order: order._id,
        },
      ],
      { session },
    );
    return order;
  });
}
export function invoice(order) {
  return {
    order_id: String(order._id),
    invoice_no: `KF-${String(order._id).slice(-10).toUpperCase()}`,
    order_date: order.createdAt.toISOString(),
    currency: "INR",
    payment_method: order.payment_method,
    sold_by: {
      name: env.SHOP_NAME,
      address: env.SHOP_ADDRESS,
      support_email: env.SUPPORT_EMAIL,
    },
    bill_to: {
      ...order.address,
      address: [
        order.address.address,
        order.address.city_name,
        order.address.pincode,
      ].join(", "),
    },
    items: order.items.map((i) => ({
      name: i.name,
      variant: "",
      price_excl_tax: i.price,
      price_incl_tax: i.price,
      tax_breakdown: [],
      total_tax: 0,
      quantity: i.quantity,
      subtotal: i.price * i.quantity,
    })),
    totals: {
      order_total: order.total,
      delivery_charge: order.delivery_charge,
      wallet_balance: order.wallet_used + order.credit_used,
      promo_discount: order.promo_discount,
      final_total: order.final_total,
      total_payable_cod: order.payment_method === "COD" ? order.final_total : 0,
    },
  };
}
