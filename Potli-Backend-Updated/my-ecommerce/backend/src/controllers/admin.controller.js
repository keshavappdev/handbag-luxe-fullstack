import { z } from "zod";
import * as M from "../models/index.js";
import * as auth from "../services/auth.service.js";
import {
  productSchema,
  categorySchema,
  id,
  page,
  url,
} from "../utils/validation.js";
import { assert, ok } from "../utils/errors.js";
import { changeStatus, orderJson } from "../services/order.service.js";
import { resolveRequest } from "../services/customer.service.js";
import { pushOrder } from "../services/push.service.js";
import { storeImage } from "../services/image.service.js";
const slug = (name) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
export const login = async (r, s) => {
  const x = await auth.login(r.body, true);
  ok(s, x.data, { token: x.token });
};
export const dashboard = async (r, s) => {
  const [products, customers, orders, pending, lowStock, sales] =
    await Promise.all([
      M.Product.countDocuments({ active: true }),
      M.User.countDocuments({ role: "customer" }),
      M.Order.countDocuments(),
      M.Order.countDocuments({ status: { $in: ["received", "processed"] } }),
      M.Product.find({ active: true, stock: { $lte: 5 } })
        .select("name stock")
        .limit(10),
      M.Order.aggregate([
        { $match: { payment_status: "paid", status: { $ne: "cancelled" } } },
        { $group: { _id: null, total: { $sum: "$final_total" } } },
      ]),
    ]);
  ok(s, {
    products,
    customers,
    orders,
    pending,
    revenue: sales[0]?.total || 0,
    lowStock,
  });
};
export const listProducts = async (r, s) => {
  const { limit, offset } = page(r.query);
  ok(
    s,
    await M.Product.find()
      .populate("category_id")
      .sort("-createdAt")
      .skip(offset)
      .limit(limit),
    { total: await M.Product.countDocuments() },
  );
};
export const saveProduct = async (r, s) => {
  const b = productSchema.parse(r.body);
  assert(
    await M.Category.exists({ _id: b.category_id }),
    422,
    "Category not found",
  );
  if (r.params.id) {
    const p = await M.Product.findByIdAndUpdate(
      id.parse(r.params.id),
      { $set: b },
      { new: true, runValidators: true },
    );
    assert(p, 404, "Product not found");
    ok(s, p);
  } else
    ok(
      s,
      await M.Product.create({
        ...b,
        slug: `${slug(b.name)}-${Date.now().toString(36)}`,
      }),
      {},
      201,
    );
};
export const deleteProduct = async (r, s) => {
  const p = await M.Product.findByIdAndUpdate(
    id.parse(r.params.id),
    { $set: { active: false } },
    { new: true },
  );
  assert(p, 404, "Product not found");
  ok(s, p);
};
export const listCategories = async (r, s) =>
  ok(s, await M.Category.find().sort("level name"));
export const saveCategory = async (r, s) => {
  const b = categorySchema.parse(r.body);
  let level = 1;
  if (b.parent_id) {
    const parent = await M.Category.findById(b.parent_id);
    assert(parent && parent.level < 3, 422, "Parent must be level 1 or 2");
    level = parent.level + 1;
  }
  if (r.params.id) {
    const existing = await M.Category.findById(id.parse(r.params.id));
    assert(existing, 404, "Category not found");
    assert(
      String(existing.parent_id || "") === String(b.parent_id || ""),
      422,
      "Existing category parent cannot be changed",
    );
    Object.assign(existing, b);
    ok(s, await existing.save());
  } else
    ok(
      s,
      await M.Category.create({
        ...b,
        level,
        slug: `${slug(b.name)}-${Date.now().toString(36)}`,
      }),
      {},
      201,
    );
};
export const deleteCategory = async (r, s) => {
  const value = id.parse(r.params.id);
  assert(
    !(await M.Product.exists({ category_id: value })) &&
      !(await M.Category.exists({ parent_id: value })),
    409,
    "Move products and delete child categories first",
  );
  assert(await M.Category.findByIdAndDelete(value), 404, "Category not found");
  ok(s);
};
export const customers = async (r, s) => {
  const { limit, offset } = page(r.query);
  ok(
    s,
    await M.User.find({ role: "customer" })
      .select("-fcmToken -googleSub")
      .sort("-createdAt")
      .skip(offset)
      .limit(limit),
    { total: await M.User.countDocuments({ role: "customer" }) },
  );
};
export const listOrders = async (r, s) => {
  const { limit, offset } = page(r.query);
  ok(
    s,
    await M.Order.find()
      .populate("user", "username email mobile")
      .sort("-createdAt")
      .skip(offset)
      .limit(limit),
    { total: await M.Order.countDocuments() },
  );
};
export const orderDetail = async (r, s) => {
  const order = await M.Order.findById(id.parse(r.params.id)).populate(
    "user",
    "username email mobile",
  );
  assert(order, 404, "Order not found");
  ok(s, { ...(await orderJson(order)), shippingAddress: order.address });
};
export const updateStatus = async (r, s) => {
  const b = z
    .object({
      status: z.enum(["processed", "shipped", "delivered", "cancelled"]),
      tracking_id: z.string().max(100).optional(),
      tracking_url: url.optional(),
      courier_agency: z.string().max(100).optional(),
    })
    .parse(r.body);
  const { status, ...tracking } = b;
  const order = await changeStatus(r.params.id, status, r.user, tracking);
  void pushOrder(order);
  ok(s, order);
};
export const image = async (r, s) =>
  ok(s, { url: await storeImage(r.file?.buffer) }, {}, 201);
export const listTickets = async (r, s) =>
  ok(
    s,
    await M.Ticket.find()
      .populate("user", "username email")
      .sort("-createdAt")
      .limit(200),
  );
export const ticketMessages = async (r, s) =>
  ok(
    s,
    await M.Message.find({ ticket: id.parse(r.params.id) })
      .sort("createdAt")
      .limit(200),
  );
export const replyTicket = async (r, s) => {
  const ticket = await M.Ticket.findById(id.parse(r.params.id));
  assert(ticket, 404, "Ticket not found");
  const b = z
    .object({
      message: z.string().trim().min(1).max(3000),
      status: z.enum(["1", "2", "3", "4", "5"]).default("2"),
    })
    .parse(r.body);
  const message = await M.Message.create({
    ticket: ticket._id,
    user: r.user._id,
    user_type: "admin",
    name: r.user.username,
    message: b.message,
  });
  ticket.status = b.status;
  await ticket.save();
  ok(s, message, {}, 201);
};
export const requests = async (r, s) =>
  ok(
    s,
    await M.Request.find()
      .populate("user", "username email")
      .sort("-createdAt")
      .limit(200),
  );
export const updateRequest = async (r, s) =>
  ok(s, await resolveRequest(r.params.id, r.body.status));
const content = {
  slides: {
    model: M.Slide,
    schema: z.object({
      title: z.string().max(150),
      subtitle: z.string().max(300).default(""),
      button_text: z.string().max(50).default("SHOP NOW"),
      type: z.enum(["products", "categories", "default"]).default("default"),
      type_id: z.string().max(100).default(""),
      image: z.string().url(),
      link: url.default(""),
      position: z.coerce.number().int().default(0),
    }),
  },
  sections: {
    model: M.Section,
    schema: z.object({
      title: z.string().min(1).max(150),
      short_description: z.string().max(300).default(""),
      style: z
        .enum(["default", "style_1", "style_2", "style_3", "style_4"])
        .default("style_1"),
      products: z.array(id).max(100),
      position: z.coerce.number().int().default(0),
    }),
  },
  promos: {
    model: M.Promo,
    schema: z.object({
      code: z
        .string()
        .min(3)
        .max(40)
        .transform((v) => v.toUpperCase()),
      percent: z.coerce.number().int().min(1).max(100),
      minimum: z.coerce.number().int().nonnegative().default(0),
      expires: z.coerce.date(),
      active: z.boolean().default(true),
    }),
  },
};
export const listContent = async (r, s) => {
  const c = content[r.params.kind];
  assert(c, 404, "Unknown resource");
  ok(s, await c.model.find().sort("-createdAt").limit(200));
};
export const saveContent = async (r, s) => {
  const c = content[r.params.kind];
  assert(c, 404, "Unknown resource");
  const b = c.schema.parse(r.body);
  if (r.params.kind === "sections") {
    assert(
      (await M.Product.countDocuments({ _id: { $in: b.products } })) ===
        new Set(b.products).size,
      422,
      "Invalid product selection",
    );
  }
  const x = r.params.id
    ? await c.model.findByIdAndUpdate(
        id.parse(r.params.id),
        { $set: b },
        { new: true, runValidators: true },
      )
    : await c.model.create(b);
  assert(x, 404, "Not found");
  ok(s, x);
};
export const deleteContent = async (r, s) => {
  const c = content[r.params.kind];
  assert(c, 404, "Unknown resource");
  assert(
    await c.model.findByIdAndDelete(id.parse(r.params.id)),
    404,
    "Not found",
  );
  ok(s);
};
