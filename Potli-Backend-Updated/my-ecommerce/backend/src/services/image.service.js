import multer from "multer";
import sharp from "sharp";
import { v2 as cloudinary } from "cloudinary";
import { randomUUID } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { env } from "../config/env.js";
import { assert } from "../utils/errors.js";
export const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 5, fields: 20 },
  fileFilter: (_r, f, cb) =>
    cb(null, ["image/jpeg", "image/png", "image/webp"].includes(f.mimetype)),
});
export async function storeImage(buffer) {
  assert(
    buffer?.length && buffer.length <= 5 * 1024 * 1024,
    422,
    "Upload a JPEG, PNG or WebP image up to 5 MB",
  );
  let output;
  try {
    output = await sharp(buffer, { limitInputPixels: 25000000 })
      .rotate()
      .resize({
        width: 2000,
        height: 2000,
        fit: "inside",
        withoutEnlargement: true,
      })
      .webp({ quality: 88 })
      .toBuffer();
  } catch {
    assert(false, 422, "Invalid or oversized image");
  }
  if (env.IMAGE_STORAGE === "cloudinary") {
    cloudinary.config({
      cloud_name: env.CLOUDINARY_CLOUD_NAME,
      api_key: env.CLOUDINARY_API_KEY,
      api_secret: env.CLOUDINARY_API_SECRET,
      secure: true,
    });
    return new Promise((resolve, reject) =>
      cloudinary.uploader
        .upload_stream(
          { folder: "potli", resource_type: "image" },
          (error, result) =>
            error ? reject(error) : resolve(result.secure_url),
        )
        .end(output),
    );
  }
  await mkdir("uploads", { recursive: true });
  const name = `${randomUUID()}.webp`;
  await writeFile(path.join("uploads", name), output);
  return `${env.PUBLIC_URL.replace(/\/$/, "")}/uploads/${name}`;
}
