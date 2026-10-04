import mongoose from "mongoose";
import { Category } from "../src/models/index.js";
import { connectDatabase } from "../src/config/database.js";
await connectDatabase();
const root = await Category.findOneAndUpdate(
  { slug: "bags" },
  {
    $setOnInsert: {
      name: "Bags",
      level: 1,
      parent_id: null,
      image: "",
      banner: "",
    },
  },
  { upsert: true, new: true },
);
for (const name of ["Tote Bags", "Shoulder Bags", "Sling Bags", "Clutches"]) {
  const slug = name.toLowerCase().replaceAll(" ", "-");
  const group = await Category.findOneAndUpdate(
    { slug },
    {
      $setOnInsert: {
        name,
        level: 2,
        parent_id: root._id,
        image: "",
        banner: "",
      },
    },
    { upsert: true, new: true },
  );
  await Category.findOneAndUpdate(
    { slug: `${slug}-collection` },
    {
      $setOnInsert: {
        name: `${name} Collection`,
        level: 3,
        parent_id: group._id,
        image: "",
        banner: "",
      },
    },
    { upsert: true },
  );
}
console.log(
  "Category hierarchy seeded. Add real products and images in the admin. No dummy products or accounts were created.",
);
await mongoose.disconnect();
