import { readFile, writeFile } from "node:fs/promises";
import { randomBytes } from "node:crypto";
try {
  await writeFile(
    ".env",
    (await readFile(".env.example", "utf8")).replace(
      "JWT_SECRET=REPLACE_WITH_A_RANDOM_SECRET_OF_AT_LEAST_32_CHARACTERS\n",
      `JWT_SECRET=${randomBytes(48).toString("hex")}\n`,
    ),
    { flag: "wx", mode: 0o600 },
  );
  console.log(
    "Created .env with a unique JWT secret. Review PUBLIC_URL before using a phone.",
  );
} catch (e) {
  if (e.code === "EEXIST") console.log(".env already exists; no changes made.");
  else throw e;
}
