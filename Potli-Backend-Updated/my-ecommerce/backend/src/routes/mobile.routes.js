import { Router } from "express";
import rateLimit from "express-rate-limit";
import {
  publicHandlers,
  privateHandlers,
} from "../controllers/mobile.controller.js";
import { authenticate } from "../middleware/auth.js";
import { upload } from "../services/image.service.js";
import { wrap } from "../utils/errors.js";
export const mobile = Router();
const authLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: "draft-8",
  legacyHeaders: false,
  skip: () => process.env.NODE_ENV === "test",
  message: { error: true, message: "Too many attempts. Try again later." },
});
for (const [path, handler] of Object.entries(publicHandlers))
  mobile.post(
    `/${path}`,
    ...(["login", "register_user", "sign_up"].includes(path)
      ? [authLimit]
      : []),
    wrap(handler),
  );
mobile.use(authenticate);
for (const [path, handler] of Object.entries(privateHandlers))
  mobile.post(
    `/${path}`,
    ...(path === "send_message" ? [upload.array("attachments[]", 5)] : []),
    wrap(handler),
  );
