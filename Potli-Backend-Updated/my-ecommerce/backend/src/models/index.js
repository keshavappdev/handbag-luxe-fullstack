import mongoose from "mongoose";
const { Schema, model } = mongoose;
const ref = (name) => ({ type: Schema.Types.ObjectId, ref: name });
const options = {
  timestamps: true,
  toJSON: {
    virtuals: true,
    transform: (_d, r) => {
      r.id = String(r._id);
      delete r._id;
      delete r.__v;
      delete r.password;
      return r;
    },
  },
};
function make(name, shape, indexes = []) {
  const s = new Schema(shape, options);
  for (const [fields, opts] of indexes) s.index(fields, opts);
  return model(name, s);
}
export const User = make("User", {
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  mobile: { type: String, unique: true, sparse: true },
  password: { type: String, select: false },
  googleSub: { type: String, unique: true, sparse: true },
  role: { type: String, enum: ["customer", "admin"], default: "customer" },
  balance: { type: Number, default: 0, min: 0 },
  subscribe_promo_email: { type: String, default: "0" },
  subscribe_promo_whatsapp: { type: String, default: "0" },
  fcmToken: String,
});
export const Category = make("Category", {
  name: String,
  slug: { type: String, unique: true },
  parent_id: { ...ref("Category"), default: null },
  level: Number,
  image: String,
  banner: String,
});
export const Product = make(
  "Product",
  {
    name: String,
    slug: { type: String, unique: true },
    category_id: ref("Category"),
    description: String,
    material: String,
    dimensions: String,
    image: String,
    other_images: [String],
    price: Number,
    special_price: Number,
    stock: { type: Number, min: 0 },
    sku: { type: String, unique: true },
    brand: String,
    tags: [String],
    active: { type: Boolean, default: true },
    allow_personalization: Boolean,
    personalize_image: String,
    personalize_text_x: Number,
    personalize_text_y: Number,
    personalize_text_width: Number,
    personalize_text_color: String,
    colors: [{ name: String, hex: String, _id: false }],
    is_returnable: Boolean,
  },
  [
    [{ category_id: 1, active: 1 }, {}],
    [{ createdAt: -1 }, {}],
  ],
);
export const Address = make(
  "Address",
  {
    user: ref("User"),
    name: String,
    mobile: String,
    address: String,
    city_name: String,
    pincode: String,
    state: String,
    country: String,
    landmark: String,
    type: String,
    is_default: String,
  },
  [[{ user: 1 }, {}]],
);
export const Cart = make("Cart", {
  user: { ...ref("User"), unique: true },
  items: [
    {
      product: ref("Product"),
      quantity: { type: Number, min: 1, max: 99 },
      personalization_text: { type: String, default: "" },
      _id: false,
    },
  ],
});
export const Wishlist = make("Wishlist", {
  user: { ...ref("User"), unique: true },
  products: [ref("Product")],
});
export const Order = make(
  "Order",
  {
    user: ref("User"),
    idempotencyKey: String,
    items: [
      {
        product: ref("Product"),
        name: String,
        image: String,
        quantity: Number,
        price: Number,
        is_returnable: Boolean,
        personalization_text: String,
      },
    ],
    address: Schema.Types.Mixed,
    total: Number,
    delivery_charge: Number,
    promo_discount: { type: Number, default: 0 },
    credit_used: { type: Number, default: 0 },
    credit: ref("Credit"),
    wallet_used: { type: Number, default: 0 },
    final_total: Number,
    shipping_type: String,
    payment_method: String,
    payment_status: { type: String, default: "unpaid" },
    status: { type: String, default: "received" },
    razorpayOrderId: String,
    paymentId: String,
    tracking_id: String,
    tracking_url: String,
    courier_agency: String,
    history: [{ status: String, date: Date, _id: false }],
  },
  [
    [{ user: 1, createdAt: -1 }, {}],
    [
      { user: 1, idempotencyKey: 1 },
      {
        unique: true,
        partialFilterExpression: { idempotencyKey: { $type: "string" } },
      },
    ],
  ],
);
export const Ticket = make("Ticket", {
  user: ref("User"),
  ticket_type_id: String,
  subject: String,
  email: String,
  description: String,
  status: { type: String, default: "1" },
});
export const Message = make("Message", {
  ticket: ref("Ticket"),
  user: ref("User"),
  user_type: String,
  name: String,
  message: String,
  attachments: [{ media: String, type: String, _id: false }],
});
export const Request = make("Request", {
  user: ref("User"),
  order: ref("Order"),
  order_item_id: { type: String, unique: true },
  kind: { type: String, enum: ["return", "exchange"] },
  reason: String,
  customer_notes: String,
  product_name: String,
  product_image: String,
  exchange_for_variant_id: ref("Product"),
  price_difference: { type: Number, default: 0 },
  status: { type: String, default: "pending" },
});
export const Credit = make("Credit", {
  user: ref("User"),
  code: { type: String, unique: true },
  original_value: Number,
  available_balance: { type: Number, min: 0 },
  expiry_date: Date,
  status: { type: String, default: "active" },
  request: { ...ref("Request"), unique: true, sparse: true },
});
export const Transaction = make("Transaction", {
  user: ref("User"),
  type: String,
  amount: Number,
  message: String,
  paymentId: { type: String, unique: true, sparse: true },
  order: ref("Order"),
});
export const Topup = make("Topup", {
  user: ref("User"),
  amount: Number,
  razorpayOrderId: { type: String, unique: true },
  paid: { type: Boolean, default: false },
});
export const Notification = make("Notification", {
  user: ref("User"),
  title: String,
  message: String,
  order: ref("Order"),
});
export const Slide = make("Slide", {
  title: String,
  subtitle: String,
  button_text: String,
  type: String,
  type_id: String,
  image: String,
  link: String,
  position: { type: Number, default: 0 },
});
export const Section = make("Section", {
  title: String,
  short_description: String,
  style: String,
  products: [ref("Product")],
  position: { type: Number, default: 0 },
});
export const Promo = make("Promo", {
  code: { type: String, unique: true },
  percent: { type: Number, min: 1, max: 100 },
  minimum: { type: Number, default: 0 },
  expires: Date,
  active: { type: Boolean, default: true },
});
