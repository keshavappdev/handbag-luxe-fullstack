import bcrypt from "bcryptjs";
import { z } from "zod";
import { OAuth2Client } from "google-auth-library";
import { User } from "../models/index.js";
import { signToken } from "../middleware/auth.js";
import { assert } from "../utils/errors.js";
import { env } from "../config/env.js";
const credentials = z.object({
  name: z.string().trim().min(2).max(100),
  email: z
    .string()
    .email()
    .max(254)
    .transform((x) => x.toLowerCase()),
  mobile: z.string().regex(/^\+?\d{7,15}$/),
  password: z.string().min(8).max(72),
});
const result = (user) => ({ token: signToken(user), data: [user.toJSON()] });
export async function register(body) {
  const b = credentials.parse(body);
  const user = await User.create({
    username: b.name,
    email: b.email,
    mobile: b.mobile,
    password: await bcrypt.hash(b.password, 12),
  });
  return result(user);
}
export async function login(body, admin = false) {
  const b = z
    .object({
      mobile: z.string().max(254).optional(),
      email: z.string().email().optional(),
      password: z.string().min(1).max(72),
    })
    .parse(body);
  assert(b.email || b.mobile, 422, "Enter email or mobile");
  const user = await User.findOne(
    b.email ? { email: b.email.toLowerCase() } : { mobile: b.mobile },
  ).select("+password");
  assert(
    user?.password && (await bcrypt.compare(b.password, user.password)),
    401,
    "Invalid credentials",
  );
  assert(!admin || user.role === "admin", 403, "Administrator access required");
  return result(user);
}
export async function google(body) {
  assert(
    env.GOOGLE_CLIENT_IDS,
    503,
    "Google sign-in is not configured; use mobile and password",
  );
  const token = z.string().min(20).max(10000).parse(body.id_token);
  let data;
  try {
    data = (
      await new OAuth2Client().verifyIdToken({
        idToken: token,
        audience: env.GOOGLE_CLIENT_IDS.split(","),
      })
    ).getPayload();
  } catch {
    assert(false, 401, "Invalid Google identity token");
  }
  assert(data.email_verified, 401, "Google email is not verified");
  let user = await User.findOne({ googleSub: data.sub });
  if (!user) {
    assert(
      !(await User.exists({ email: data.email.toLowerCase() })),
      409,
      "This email already has an account. Sign in with your password.",
    );
    user = await User.create({
      username: data.name || data.email,
      email: data.email,
      googleSub: data.sub,
    });
  }
  return result(user);
}
export async function profile(user, b) {
  const changes = z
    .object({
      username: z.string().trim().min(2).max(100).optional(),
      email: z
        .string()
        .email()
        .transform((x) => x.toLowerCase())
        .optional(),
      mobile: z
        .string()
        .regex(/^\+?\d{7,15}$/)
        .optional(),
    })
    .parse(b);
  Object.assign(user, changes);
  return (await user.save()).toJSON();
}
