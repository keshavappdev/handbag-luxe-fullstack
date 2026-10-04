import "dotenv/config";
import { z } from "zod";
const schema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
  PORT: z.coerce.number().int().min(1).max(65535).default(4000),
  MONGODB_URI: z.string().min(1),
  JWT_SECRET: z
    .string()
    .min(32, "JWT_SECRET must contain at least 32 characters"),
  JWT_EXPIRES_IN: z.string().default("7d"),
  ADMIN_ORIGINS: z.string().default("http://localhost:5173"),
  PUBLIC_URL: z.string().url().default("http://localhost:4000"),
  IMAGE_STORAGE: z.enum(["local", "cloudinary"]).default("local"),
  CLOUDINARY_CLOUD_NAME: z.string().default(""),
  CLOUDINARY_API_KEY: z.string().default(""),
  CLOUDINARY_API_SECRET: z.string().default(""),
  GOOGLE_CLIENT_IDS: z.string().default(""),
  RAZORPAY_KEY_ID: z.string().default(""),
  RAZORPAY_KEY_SECRET: z.string().default(""),
  RAZORPAY_WEBHOOK_SECRET: z.string().default(""),
  SHOP_NAME: z.string().default("POTLI"),
  SHOP_ADDRESS: z.string().default(""),
  SUPPORT_EMAIL: z.string().default(""),
  SHIPPING_STANDARD: z.coerce.number().int().nonnegative().default(99),
  SHIPPING_EXPRESS: z.coerce.number().int().nonnegative().default(199),
  FREE_SHIPPING_THRESHOLD: z.coerce.number().int().nonnegative().default(2999),
  RETURN_WINDOW_DAYS: z.coerce.number().int().positive().default(14),
});
export const env = schema.parse(process.env);
if (
  env.IMAGE_STORAGE === "cloudinary" &&
  !(
    env.CLOUDINARY_CLOUD_NAME &&
    env.CLOUDINARY_API_KEY &&
    env.CLOUDINARY_API_SECRET
  )
)
  throw new Error("Set all three Cloudinary credentials");
export const onlinePayments = Boolean(
  env.RAZORPAY_KEY_ID && env.RAZORPAY_KEY_SECRET,
);
