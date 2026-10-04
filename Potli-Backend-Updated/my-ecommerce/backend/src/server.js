import { app } from "./app.js";
import { connectDatabase } from "./config/database.js";
import { env } from "./config/env.js";
import mongoose from "mongoose";
await connectDatabase();
const server = app.listen(env.PORT, "0.0.0.0", () =>
  console.log(`POTLI API listening on port ${env.PORT}`),
);
for (const signal of ["SIGINT", "SIGTERM"])
  process.on(signal, () =>
    server.close(async () => {
      await mongoose.disconnect();
      process.exit(0);
    }),
  );
