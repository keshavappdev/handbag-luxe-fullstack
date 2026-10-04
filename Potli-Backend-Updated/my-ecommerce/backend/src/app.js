import express from "express";
import helmet from "helmet";
import cors from "cors";
import rateLimit from "express-rate-limit";
import mongoose from "mongoose";
import { env } from "./config/env.js";
import { mobile } from "./routes/mobile.routes.js";
import { admin } from "./routes/admin.routes.js";
import { AppError, errorHandler, wrap, ok, assert } from "./utils/errors.js";
import { validSignature, settlePayment } from "./services/payment.service.js";
export const app = express();
app.disable("x-powered-by");
app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
app.use(
  cors({
    origin: (origin, cb) =>
      !origin || env.ADMIN_ORIGINS.split(",").includes(origin)
        ? cb(null, true)
        : cb(new AppError(403, "Origin not allowed")),
  }),
);
app.post(
  "/api/webhooks/razorpay",
  express.raw({ type: "application/json", limit: "1mb" }),
  wrap(async (r, s) => {
    assert(
      env.RAZORPAY_WEBHOOK_SECRET &&
        validSignature(
          r.body,
          r.get("x-razorpay-signature"),
          env.RAZORPAY_WEBHOOK_SECRET,
        ),
      400,
      "Invalid webhook signature",
    );
    const event = JSON.parse(r.body.toString());
    if (event.event === "payment.captured") {
      const p = event.payload.payment.entity;
      assert(
        p.currency === "INR" && p.status === "captured",
        422,
        "Invalid payment",
      );
      await settlePayment(p);
    }
    ok(s);
  }),
);
app.use(express.json({ limit: "7mb" }));
app.use(express.urlencoded({ extended: false, limit: "7mb" }));
app.use(
  "/uploads",
  express.static("uploads", {
    dotfiles: "deny",
    maxAge: "1d",
    immutable: true,
  }),
);
app.use(
  "/api",
  rateLimit({
    windowMs: 60000,
    limit: 300,
    skip: () => env.NODE_ENV === "test",
    standardHeaders: "draft-8",
    legacyHeaders: false,
    message: { error: true, message: "Too many requests" },
  }),
);
app.get("/health", (r, s) =>
  s.status(mongoose.connection.readyState === 1 ? 200 : 503).json({
    status: mongoose.connection.readyState === 1 ? "ok" : "unavailable",
  }),
);
app.use("/api/admin", admin);
app.use("/api/v1", mobile);
app.use((r, s, next) => next(new AppError(404, "Endpoint not found")));
app.use(errorHandler);
