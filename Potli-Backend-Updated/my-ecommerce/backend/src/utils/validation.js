import { z } from "zod";
export const id = z.string().regex(/^[a-f\d]{24}$/i, "Invalid identifier");
export const text = z.string().trim().min(1).max(500);
export const url = z.union([
  z
    .string()
    .url()
    .refine((v) => /^https?:\/\//.test(v), "HTTP(S) URL required"),
  z.literal(""),
]);
export const money = z.coerce.number().int().min(0).max(10000000);
export const quantity = z.coerce.number().int().min(1).max(99);
export const addressSchema = z.object({
  name: text.max(100),
  mobile: z.string().regex(/^\+?[\d -]{7,20}$/),
  address: text,
  city_name: text.max(100),
  pincode: z.string().regex(/^\d{6}$/),
  state: z.string().max(100).default(""),
  country: z.string().max(100).default("India"),
  landmark: z.string().max(200).default(""),
  type: z.string().max(30).default("Home"),
  is_default: z.enum(["0", "1"]).default("0"),
});
export const productSchema = z
  .object({
    name: text.max(160),
    category_id: id,
    description: z.string().max(20000).default(""),
    material: z.string().max(200).default(""),
    dimensions: z.string().max(200).default(""),
    image: z
      .string()
      .url()
      .refine((v) => /^https?:\/\//.test(v)),
    other_images: z.array(url).max(12).default([]),
    price: money.refine((v) => v > 0),
    special_price: money.default(0),
    stock: z.coerce.number().int().min(0).max(1000000),
    sku: text.max(80),
    brand: z.string().max(80).default("POTLI"),
    tags: z.array(z.string().max(50)).max(16).default([]),
    active: z.boolean().default(true),
    allow_personalization: z.boolean().default(false),
    personalize_image: url.default(""),
    personalize_text_x: z.coerce.number().min(0).max(100).default(50),
    personalize_text_y: z.coerce.number().min(0).max(100).default(68),
    personalize_text_width: z.coerce.number().min(1).max(100).default(60),
    personalize_text_color: z
      .string()
      .regex(/^#[a-f\d]{6}$/i)
      .default("#4a3624"),
    colors: z
      .array(
        z.object({
          name: text.max(40),
          hex: z.string().regex(/^#[a-f\d]{6}$/i),
        }),
      )
      .max(20)
      .default([]),
    is_returnable: z.boolean().default(true),
  })
  .refine(
    (x) => !x.special_price || x.special_price < x.price,
    "Sale price must be below price",
  );
export const categorySchema = z.object({
  name: text.max(100),
  parent_id: id.nullable().default(null),
  image: url.default(""),
  banner: url.default(""),
});
export function page(b = {}) {
  return {
    limit: z.coerce.number().int().min(1).max(200).default(50).parse(b.limit),
    offset: z.coerce
      .number()
      .int()
      .min(0)
      .max(100000)
      .default(0)
      .parse(b.offset),
  };
}
export const escaped = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
