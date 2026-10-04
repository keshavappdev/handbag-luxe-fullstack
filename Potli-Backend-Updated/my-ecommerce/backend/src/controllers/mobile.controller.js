import { z } from "zod";
import * as M from "../models/index.js";
import * as auth from "../services/auth.service.js";
import * as catalog from "../services/catalog.service.js";
import * as customer from "../services/customer.service.js";
import * as orders from "../services/order.service.js";
import * as payments from "../services/payment.service.js";
import { storeImage } from "../services/image.service.js";
import { env, onlinePayments } from "../config/env.js";
import { id, addressSchema, page } from "../utils/validation.js";
import { assert, ok } from "../utils/errors.js";
const reply = (res, x) =>
  ok(
    res,
    x.data || [],
    Object.fromEntries(Object.entries(x).filter(([k]) => k !== "data")),
  );
const creditJson = (c) => ({
  ...c.toJSON(),
  issue_date: c.createdAt.toISOString(),
});
const ticketJson = (t) => ({
  ...t.toJSON(),
  ticket_type: t.ticket_type_id === "orders" ? "Orders" : "General",
  date_created: t.createdAt.toISOString(),
});
const messageJson = (m) => ({
  ...m.toJSON(),
  user_id: String(m.user),
  date_created: m.createdAt.toISOString(),
});
async function ticketFor(user, value) {
  const t = await M.Ticket.findOne({ _id: id.parse(value), user: user._id });
  assert(t, 404, "Ticket not found");
  return t;
}
export const publicHandlers = {
  login: async (r, s) => reply(s, await auth.login(r.body)),
  register_user: async (r, s) => reply(s, await auth.register(r.body)),
  sign_up: async (r, s) => reply(s, await auth.google(r.body)),
  get_products: async (r, s) => reply(s, await catalog.products(r.body)),
  get_categories: async (r, s) =>
    ok(s, await M.Category.find({ parent_id: null }).sort("name")),
  get_subcategories_by_category_id: async (r, s) =>
    ok(
      s,
      await M.Category.find({ parent_id: id.parse(r.body.category_id) }).sort(
        "name",
      ),
    ),
  get_category_collection_items: async (r, s) =>
    ok(
      s,
      await M.Category.find({
        parent_id: id.parse(r.body.sub_category_id),
      }).sort("name"),
    ),
  get_sections: async (r, s) => ok(s, await catalog.sections()),
  get_slider_images: async (r, s) => ok(s, await catalog.slides()),
  get_settings: async (r, s) =>
    ok(s, {
      payment_method: {
        cod_method: "1",
        razorpay_payment_method: onlinePayments ? "1" : "0",
        razorpay_key_id: onlinePayments ? env.RAZORPAY_KEY_ID : "",
      },
    }),
  get_personalization_settings: async (r, s) =>
    ok(s, {
      enabled: "1",
      heading: "Add your personal touch",
      description: "Make it unmistakably yours.",
      max_characters: 20,
    }),
  get_complete_the_look: async (r, s) => {
    const p = await M.Product.findById(id.parse(r.body.product_id));
    assert(p, 404, "Product not found");
    ok(
      s,
      (
        await M.Product.find({
          category_id: p.category_id,
          active: true,
          _id: { $ne: p._id },
        })
          .populate("category_id")
          .limit(8)
      ).map(catalog.productJson),
    );
  },
  get_ticket_types: async (r, s) =>
    ok(s, [
      { id: "orders", title: "Orders" },
      { id: "general", title: "General" },
    ]),
};
export const privateHandlers = {
  update_user: async (r, s) => ok(s, await auth.profile(r.user, r.body)),
  update_fcm: async (r, s) => {
    r.user.fcmToken = z
      .string()
      .max(4096)
      .parse(r.body.fcm_id || r.body.fcm_token);
    await r.user.save();
    ok(s);
  },
  update_promo_preferences: async (r, s) => {
    for (const key of ["subscribe_promo_email", "subscribe_promo_whatsapp"])
      if (r.body[key] !== undefined)
        r.user[key] = z.enum(["0", "1"]).parse(r.body[key]);
    await r.user.save();
    ok(s, {
      subscribe_promo_email: r.user.subscribe_promo_email,
      subscribe_promo_whatsapp: r.user.subscribe_promo_whatsapp,
    });
  },
  get_user_cart: async (r, s) => ok(s, await customer.cart(r.user)),
  manage_cart: async (r, s) => {
    await customer.updateCart(r.user, r.body);
    ok(s);
  },
  remove_from_cart: async (r, s) => {
    await customer.updateCart(r.user, r.body, true);
    ok(s);
  },
  get_favorites: async (r, s) => ok(s, await customer.favorites(r.user)),
  add_to_favorites: async (r, s) => {
    await customer.favorite(r.user, r.body);
    ok(s);
  },
  remove_from_favorites: async (r, s) => {
    await customer.favorite(r.user, r.body, true);
    ok(s);
  },
  get_address: async (r, s) =>
    ok(
      s,
      (await M.Address.find({ user: r.user._id }).sort("createdAt")).map(
        (x) => ({ ...x.toJSON(), city: x.city_name }),
      ),
    ),
  add_address: async (r, s) => {
    const b = addressSchema.parse(r.body);
    const a = await M.Address.create({ ...b, user: r.user._id });
    ok(s, [{ ...a.toJSON(), city: a.city_name }]);
  },
  update_address: async (r, s) => {
    const b = addressSchema.parse(r.body);
    const a = await M.Address.findOneAndUpdate(
      { _id: id.parse(r.body.id), user: r.user._id },
      { $set: b },
      { new: true, runValidators: true },
    );
    assert(a, 404, "Address not found");
    ok(s, [a]);
  },
  delete_address: async (r, s) => {
    const a = await M.Address.findOneAndDelete({
      _id: id.parse(r.body.id),
      user: r.user._id,
    });
    assert(a, 404, "Address not found");
    ok(s);
  },
  get_delivery_charge: async (r, s) => {
    assert(
      await M.Address.exists({
        _id: id.parse(r.body.address_id),
        user: r.user._id,
      }),
      404,
      "Address not found",
    );
    const lines = await customer.cart(r.user);
    const total = lines.reduce(
      (n, i) => n + (i.product.special_price || i.product.price) * i.qty,
      0,
    );
    const standard = orders.shipping(total),
      express = orders.shipping(total, "Express");
    const option = (charge, days) => ({
      delivery_charge_with_cod: charge,
      delivery_charge_without_cod: charge,
      estimated_delivery_days: days,
    });
    ok(s, [], {
      ...option(standard, 5),
      shipping_options: {
        standard: option(standard, 5),
        express: option(express, 2),
      },
    });
  },
  validate_promo_code: async (r, s) => {
    const lines = await customer.cart(r.user),
      total = lines.reduce(
        (n, i) => n + (i.product.special_price || i.product.price) * i.qty,
        0,
      );
    ok(s, [
      { final_discount: await orders.promoDiscount(r.body.promo_code, total) },
    ]);
  },
  validate_credit_code: async (r, s) => {
    const c = await M.Credit.findOne({
      user: r.user._id,
      code: z.string().max(100).parse(r.body.code),
      status: "active",
      expiry_date: { $gt: new Date() },
      available_balance: { $gt: 0 },
    });
    assert(c, 422, "Invalid, expired or exhausted credit code");
    ok(s, creditJson(c));
  },
  get_my_potli_credits: async (r, s) =>
    ok(
      s,
      (await M.Credit.find({ user: r.user._id }).sort("-createdAt")).map(
        creditJson,
      ),
    ),
  place_order: async (r, s) => {
    const order = await orders.placeOrder(
      r.user,
      r.body,
      r.get("Idempotency-Key"),
    );
    ok(s, [], { order_id: String(order._id), final_total: order.final_total });
  },
  get_orders: async (r, s) => {
    const { limit, offset } = page(r.body);
    const all = await M.Order.find({ user: r.user._id })
      .sort("-createdAt")
      .skip(offset)
      .limit(limit);
    ok(s, await Promise.all(all.map(orders.orderJson)));
  },
  update_order_status: async (r, s) => {
    const o = await orders.ownedOrder(r.user, r.body.order_id);
    if (r.body.status === "received") {
      assert(
        o.payment_status === "paid" && o.status === "received",
        409,
        "Payment must be verified on the server",
      );
      ok(s);
      return;
    }
    await orders.changeStatus(o._id.toString(), r.body.status, r.user);
    ok(s);
  },
  delete_order: async (r, s) => {
    await orders.changeStatus(r.body.order_id, "cancelled", r.user);
    ok(s);
  },
  get_order_tracking: async (r, s) => {
    const o = await orders.ownedOrder(r.user, r.body.order_id);
    ok(s, [], {
      source: "order",
      current_status: o.status,
      tracking_id: o.tracking_id || "",
      tracking_url: o.tracking_url || "",
      courier_agency: o.courier_agency || "",
      shipping_type: o.shipping_type,
      timeline: o.history.map((h) => ({
        status: h.status,
        date: h.date.toISOString(),
      })),
    });
  },
  get_invoice_html: async (r, s) => {
    const invoice = orders.invoice(
      await orders.ownedOrder(r.user, r.body.order_id),
    );
    const escape = (value) =>
      String(value).replace(
        /[&<>"']/g,
        (c) =>
          ({
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#39;",
          })[c],
      );
    const rows = invoice.items
      .map(
        (i) =>
          `<tr><td>${escape(i.name)}</td><td>${i.quantity}</td><td>INR ${i.price_incl_tax}</td><td>INR ${i.subtotal}</td></tr>`,
      )
      .join("");
    ok(
      s,
      `<!doctype html><html><head><meta charset="utf-8"><title>Invoice</title></head><body><h1>${escape(invoice.sold_by.name)}</h1><h2>${escape(invoice.invoice_no)}</h2><p>${escape(invoice.bill_to.name)}<br>${escape(invoice.bill_to.address)}</p><table><thead><tr><th>Item</th><th>Quantity</th><th>Price</th><th>Subtotal</th></tr></thead><tbody>${rows}</tbody></table><p>Shipping: INR ${invoice.totals.delivery_charge}</p><p>Payable: INR ${invoice.totals.final_total}</p></body></html>`,
    );
  },
  get_invoice_data: async (r, s) =>
    ok(s, orders.invoice(await orders.ownedOrder(r.user, r.body.order_id))),
  razorpay_create_order: async (r, s) =>
    ok(s, await payments.createPayment(r.user, r.body)),
  create_wallet_order: async (r, s) =>
    ok(s, await payments.createTopup(r.user, r.body)),
  verify_payment: async (r, s) => {
    await payments.confirmPayment(r.user, r.body);
    ok(s);
  },
  add_transaction: async (r, s) => {
    await payments.confirmPayment(r.user, r.body);
    ok(s);
  },
  transactions: async (r, s) =>
    ok(
      s,
      (
        await M.Transaction.find({
          user: r.user._id,
          type: { $in: ["credit", "debit"] },
        })
          .sort("-createdAt")
          .limit(200)
      ).map((t) => ({
        ...t.toJSON(),
        date_created: t.createdAt.toISOString(),
      })),
      { balance: r.user.balance },
    ),
  get_notifications: async (r, s) =>
    ok(
      s,
      (
        await M.Notification.find({ user: r.user._id })
          .sort("-createdAt")
          .limit(100)
      ).map((n) => ({ ...n.toJSON(), date_sent: n.createdAt.toISOString() })),
    ),
  save_personalization_preview: async (r, s) => {
    const data = z.string().max(7000000).parse(r.body.image);
    assert(
      /^data:image\/(png|jpeg|webp);base64,/.test(data),
      422,
      "Invalid image",
    );
    ok(s, {
      path: await storeImage(Buffer.from(data.split(",")[1], "base64")),
    });
  },
  submit_return_request: async (r, s) =>
    ok(s, await customer.submitRequest(r.user, r.body, "return")),
  submit_exchange_request: async (r, s) =>
    ok(s, await customer.submitRequest(r.user, r.body, "exchange")),
  get_my_return_requests: async (r, s) =>
    ok(
      s,
      (
        await M.Request.find({ user: r.user._id, kind: "return" }).sort(
          "-createdAt",
        )
      ).map(customer.requestJson),
    ),
  get_my_exchange_requests: async (r, s) =>
    ok(
      s,
      (
        await M.Request.find({ user: r.user._id, kind: "exchange" }).sort(
          "-createdAt",
        )
      ).map(customer.requestJson),
    ),
  get_exchange_variants: async (r, s) => {
    const o = await M.Order.findOne({
      user: r.user._id,
      "items._id": id.parse(r.body.order_item_id),
    });
    assert(o, 404, "Order item not found");
    const item = o.items.id(r.body.order_item_id);
    ok(
      s,
      (await M.Product.find({ active: true, stock: { $gt: 0 } }).limit(200))
        .filter((p) => (p.special_price || p.price) === item.price)
        .map((p) => ({
          id: String(p._id),
          label: p.name,
          price: p.special_price || p.price,
          stock: p.stock,
        })),
    );
  },
  get_tickets: async (r, s) => {
    const { limit, offset } = page(r.body);
    ok(
      s,
      (
        await M.Ticket.find({ user: r.user._id })
          .sort("-createdAt")
          .skip(offset)
          .limit(limit)
      ).map(ticketJson),
    );
  },
  add_ticket: async (r, s) => {
    const b = z
      .object({
        ticket_type_id: z.enum(["orders", "general"]),
        subject: z.string().min(3).max(150),
        email: z.string().email(),
        description: z.string().min(3).max(3000),
      })
      .parse(r.body);
    ok(s, [ticketJson(await M.Ticket.create({ ...b, user: r.user._id }))]);
  },
  edit_ticket: async (r, s) => {
    const t = await ticketFor(r.user, r.body.ticket_id);
    t.status = z.enum(["3", "5"]).parse(r.body.status);
    await t.save();
    ok(s);
  },
  get_messages: async (r, s) => {
    const t = await ticketFor(r.user, r.body.ticket_id);
    ok(
      s,
      (
        await M.Message.find({ ticket: t._id }).sort("createdAt").limit(200)
      ).map(messageJson),
    );
  },
  send_message: async (r, s) => {
    const t = await ticketFor(r.user, r.body.ticket_id);
    assert(t.status !== "4", 409, "Ticket is closed");
    const message = z.string().max(3000).default("").parse(r.body.message);
    assert(
      message.trim() || r.files?.length,
      422,
      "Enter a message or attach an image",
    );
    const attachments = [];
    for (const f of r.files || [])
      attachments.push({ media: await storeImage(f.buffer), type: "image" });
    const m = await M.Message.create({
      ticket: t._id,
      user: r.user._id,
      user_type: "user",
      name: r.user.username,
      message,
      attachments,
    });
    ok(s, messageJson(m));
  },
};
