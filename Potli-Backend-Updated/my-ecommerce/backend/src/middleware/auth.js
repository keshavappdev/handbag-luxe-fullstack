import jwt from "jsonwebtoken";
import { User } from "../models/index.js";
import { env } from "../config/env.js";
import { AppError, wrap } from "../utils/errors.js";
export const authenticate = wrap(async (req, res, next) => {
  const token = req.headers.authorization?.startsWith("Bearer ")
    ? req.headers.authorization.slice(7)
    : "";
  let payload;
  try {
    payload = jwt.verify(token, env.JWT_SECRET, {
      algorithms: ["HS256"],
      issuer: "potli",
      audience: "potli-app",
    });
  } catch {
    throw new AppError(401, "Please sign in again");
  }
  req.user = await User.findById(payload.sub);
  if (!req.user) throw new AppError(401, "Account no longer exists");
  next();
});
export const adminOnly = (req, res, next) =>
  req.user?.role === "admin"
    ? next()
    : next(new AppError(403, "Administrator access required"));
export const signToken = (user) =>
  jwt.sign({}, env.JWT_SECRET, {
    subject: String(user._id),
    expiresIn: env.JWT_EXPIRES_IN,
    issuer: "potli",
    audience: "potli-app",
    algorithm: "HS256",
  });
