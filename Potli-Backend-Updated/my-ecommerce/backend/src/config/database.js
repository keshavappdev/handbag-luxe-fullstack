import mongoose from "mongoose";
import { env } from "./env.js";
export async function connectDatabase() {
  mongoose.set("strictQuery", true);
  await mongoose.connect(env.MONGODB_URI, { serverSelectionTimeoutMS: 10000 });
  const hello = await mongoose.connection.db.admin().command({ hello: 1 });
  if (!hello.setName && hello.msg !== "isdbgrid")
    throw new Error(
      "MongoDB replica set required. Run docker compose up -d and wait for mongo-init.",
    );
  for (const model of Object.values(mongoose.models)) await model.init();
}
