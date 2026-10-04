import { Router } from "express";
import rateLimit from "express-rate-limit";
import * as C from "../controllers/admin.controller.js";
import { authenticate, adminOnly } from "../middleware/auth.js";
import { upload } from "../services/image.service.js";
import { wrap, ok } from "../utils/errors.js";
export const admin = Router();
admin.post(
  "/login",
  rateLimit({
    windowMs: 900000,
    limit: 20,
    skip: () => process.env.NODE_ENV === "test",
    message: { error: true, message: "Too many attempts" },
  }),
  wrap(C.login),
);
admin.use(authenticate, adminOnly);
admin.get("/me", (r, s) => ok(s, r.user));
admin.get("/dashboard", wrap(C.dashboard));
admin.get("/products", wrap(C.listProducts));
admin.post("/products", wrap(C.saveProduct));
admin.put("/products/:id", wrap(C.saveProduct));
admin.delete("/products/:id", wrap(C.deleteProduct));
admin.get("/categories", wrap(C.listCategories));
admin.post("/categories", wrap(C.saveCategory));
admin.put("/categories/:id", wrap(C.saveCategory));
admin.delete("/categories/:id", wrap(C.deleteCategory));
admin.get("/customers", wrap(C.customers));
admin.get("/orders", wrap(C.listOrders));
admin.get("/orders/:id", wrap(C.orderDetail));
admin.patch("/orders/:id/status", wrap(C.updateStatus));
admin.post("/images", upload.single("image"), wrap(C.image));
admin.get("/tickets", wrap(C.listTickets));
admin.get("/tickets/:id/messages", wrap(C.ticketMessages));
admin.post("/tickets/:id/messages", wrap(C.replyTicket));
admin.get("/requests", wrap(C.requests));
admin.patch("/requests/:id", wrap(C.updateRequest));
admin.get("/content/:kind", wrap(C.listContent));
admin.post("/content/:kind", wrap(C.saveContent));
admin.put("/content/:kind/:id", wrap(C.saveContent));
admin.delete("/content/:kind/:id", wrap(C.deleteContent));
