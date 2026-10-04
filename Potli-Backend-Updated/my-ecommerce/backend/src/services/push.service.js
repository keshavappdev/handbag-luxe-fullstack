import { getApps, initializeApp, applicationDefault } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import { User } from "../models/index.js";
export async function pushOrder(order) {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) return;
  try {
    if (!getApps().length) initializeApp({ credential: applicationDefault() });
    const user = await User.findById(order.user);
    if (!user?.fcmToken) return;
    await getMessaging().send({
      token: user.fcmToken,
      notification: {
        title: "Order update",
        body: `Your order is ${order.status}`,
      },
      data: { order_id: String(order._id) },
      android: { notification: { channelId: "potli_default" } },
    });
  } catch (error) {
    console.error("Push delivery failed:", error.code || error.name);
  }
}
