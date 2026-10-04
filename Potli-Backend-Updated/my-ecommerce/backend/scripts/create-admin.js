import { createInterface } from "node:readline/promises";
import { stdin, stdout } from "node:process";
import bcrypt from "bcryptjs";
import mongoose from "mongoose";
import { z } from "zod";
import { User } from "../src/models/index.js";
import { connectDatabase } from "../src/config/database.js";
const prompt = createInterface({ input: stdin, output: stdout });
try {
  const email = z
    .string()
    .email()
    .parse((await prompt.question("Admin email: ")).trim().toLowerCase());
  const username = z
    .string()
    .min(2)
    .max(100)
    .parse((await prompt.question("Admin name: ")).trim());
  // Read from environment for automation; interactive input remains local to your terminal.
  const password = z
    .string()
    .min(12)
    .max(72)
    .parse(
      process.env.ADMIN_PASSWORD ||
        (await prompt.question(
          "Admin password (12+ characters; visible in terminal): ",
        )),
    );
  await connectDatabase();
  if (await User.exists({ email }))
    throw new Error("Email exists. Choose a separate admin email.");
  await User.create({
    username,
    email,
    password: await bcrypt.hash(password, 12),
    role: "admin",
  });
  console.log("Administrator created. Sign in to http://localhost:5173");
} finally {
  prompt.close();
  await mongoose.disconnect();
}
