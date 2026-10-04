import mongoose from "mongoose";
import { createHmac, timingSafeEqual } from "node:crypto";
import { z } from "zod";
import { Order, Topup, User, Transaction } from "../models/index.js";
import { env, onlinePayments } from "../config/env.js";
import { assert } from "../utils/errors.js";
import { ownedOrder } from "./order.service.js";
export async function razorpay(path, body) {
  assert(onlinePayments, 503, "Razorpay is not configured");
  const response = await fetch(`https://api.razorpay.com/v1/${path}`, {
    method: body ? "POST" : "GET",
    headers: {
      Authorization: `Basic ${Buffer.from(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`).toString("base64")}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(15000),
  });
  assert(response.ok, 502, "Payment provider request failed");
  return response.json();
}
export async function createPayment(user, b) {
  const order = await ownedOrder(user, b.order_id);
  assert(
    order.status === "awaiting" && order.final_total > 0,
    409,
    "Order does not require payment",
  );
  if (order.razorpayOrderId) return razorpay(`orders/${order.razorpayOrderId}`);
  const remote = await razorpay("orders", {
    amount: Math.round(order.final_total * 100),
    currency: "INR",
    receipt: String(order._id),
  });
  const saved = await Order.findOneAndUpdate(
    { _id: order._id, razorpayOrderId: { $exists: false }, status: "awaiting" },
    { $set: { razorpayOrderId: remote.id } },
    { new: true },
  );
  if (!saved) {
    const fresh = await Order.findById(order._id);
    assert(fresh?.razorpayOrderId, 409, "Order changed; reload");
    return razorpay(`orders/${fresh.razorpayOrderId}`);
  }
  return remote;
}
export async function createTopup(user, b) {
  const amount = z.coerce.number().int().min(1).max(100000).parse(b.amount);
  const remote = await razorpay("orders", {
    amount: amount * 100,
    currency: "INR",
    notes: { user: String(user._id), purpose: "wallet" },
  });
  await Topup.create({ user: user._id, amount, razorpayOrderId: remote.id });
  return remote;
}
export function validSignature(value, signature, secret) {
  if (!/^[a-f\d]{64}$/i.test(signature || "")) return false;
  return timingSafeEqual(
    Buffer.from(
      createHmac("sha256", secret).update(value).digest("hex"),
      "hex",
    ),
    Buffer.from(signature, "hex"),
  );
}
export async function confirmPayment(user, b) {
  const pid = z
      .string()
      .regex(/^pay_[A-Za-z0-9]+$/)
      .parse(b.payment_id || b.txn_id),
    remoteId = z
      .string()
      .regex(/^order_[A-Za-z0-9]+$/)
      .parse(b.razorpay_order_id);
  assert(
    validSignature(`${remoteId}|${pid}`, b.signature, env.RAZORPAY_KEY_SECRET),
    400,
    "Invalid payment signature",
  );
  const payment = await razorpay(`payments/${pid}`);
  assert(
    payment.order_id === remoteId &&
      payment.currency === "INR" &&
      payment.status === "captured",
    409,
    "Payment is not captured yet. Retry after capture or contact support.",
  );
  return settlePayment(payment, user._id);
}
export async function settlePayment(payment, userId) {
  return mongoose.connection.transaction(async (session) => {
    const filter = {
      razorpayOrderId: payment.order_id,
      ...(userId ? { user: userId } : {}),
    };
    const order = await Order.findOne(filter).session(session);
    if (order) {
      assert(
        payment.amount === Math.round(order.final_total * 100),
        409,
        "Payment amount mismatch",
      );
      if (["paid", "credited_to_wallet"].includes(order.payment_status))
        return order;
      if (order.status === "cancelled") {
        order.payment_status = "credited_to_wallet";
        order.paymentId = payment.id;
        await order.save({ session });
        await User.updateOne(
          { _id: order.user },
          { $inc: { balance: order.final_total } },
          { session },
        );
        await Transaction.create(
          [
            {
              user: order.user,
              type: "credit",
              amount: order.final_total,
              message:
                "Payment received after cancellation; credited to wallet",
              paymentId: payment.id,
              order: order._id,
            },
          ],
          { session },
        );
        return order;
      }
      assert(
        order.status === "awaiting",
        409,
        "Order is no longer awaiting payment",
      );
      order.payment_status = "paid";
      order.paymentId = payment.id;
      order.status = "received";
      order.history.push({ status: "received", date: new Date() });
      await order.save({ session });
      await Transaction.create(
        [
          {
            user: order.user,
            type: "payment",
            amount: order.final_total,
            message: "Razorpay order payment",
            paymentId: payment.id,
            order: order._id,
          },
        ],
        { session },
      );
      return order;
    }
    const topup = await Topup.findOne(filter).session(session);
    assert(topup, 404, "Payment reference not found");
    assert(
      payment.amount === topup.amount * 100,
      409,
      "Top-up amount mismatch",
    );
    if (topup.paid) return topup;
    topup.paid = true;
    await topup.save({ session });
    await User.updateOne(
      { _id: topup.user },
      { $inc: { balance: topup.amount } },
      { session },
    );
    await Transaction.create(
      [
        {
          user: topup.user,
          type: "credit",
          amount: topup.amount,
          message: "Wallet top-up",
          paymentId: payment.id,
        },
      ],
      { session },
    );
    return topup;
  });
}
