import { Category, Product, Section, Slide } from "../models/index.js";
import { id, page, escaped } from "../utils/validation.js";
import { z } from "zod";
export const productJson = (p) => {
  const x = p.toJSON ? p.toJSON() : p;
  return {
    ...x,
    id: String(x.id || x._id),
    category_name: x.category_id?.name || "",
    category_id: String(x.category_id?._id || x.category_id?.id || x.category_id || ""),
    allow_personalization: x.allow_personalization ? "1" : "0",
    variants: [
      {
        id: String(x.id || x._id),
        price: x.price,
        special_price: x.special_price,
        stock: x.stock,
      },
    ],
    attributes: x.colors?.length
      ? [
          {
            name: "Color",
            value: x.colors.map((c) => c.name),
            swatche_type: x.colors.map(() => "1"),
            swatche_value: x.colors.map((c) => c.hex),
          },
        ]
      : [],
  };
};
export async function descendants(categoryId) {
  const ids = [id.parse(categoryId)];
  for (let n = 0; n < ids.length; n++) {
    const children = await Category.find({ parent_id: ids[n] }).select("_id");
    ids.push(...children.map((x) => String(x._id)));
  }
  return ids;
}
export async function products(b) {
  const { limit, offset } = page(b);
  const filter = { active: true };
  if (b.id) filter._id = id.parse(b.id);
  if (b.category_id)
    filter.category_id = { $in: await descendants(b.category_id) };
  if (b.search)
    filter.name = {
      $regex: escaped(z.string().max(100).parse(b.search)),
      $options: "i",
    };
  if (b.min_price || b.max_price) {
    filter.price = {};
    if (b.min_price)
      filter.price.$gte = z.coerce.number().nonnegative().parse(b.min_price);
    if (b.max_price)
      filter.price.$lte = z.coerce.number().nonnegative().parse(b.max_price);
  }
  const sort = {
    price_asc: { price: 1 },
    price_desc: { price: -1 },
    newest: { createdAt: -1 },
  }[b.sort] || { createdAt: -1 };
  return {
    data: (
      await Product.find(filter)
        .setOptions({ sanitizeFilter: false })
        .populate("category_id")
        .sort(sort)
        .skip(offset)
        .limit(limit)
    ).map(productJson),
    total: await Product.countDocuments(filter).setOptions({
      sanitizeFilter: false,
    }),
  };
}
export async function sections() {
  const all = await Section.find()
    .sort("position")
    .populate({
      path: "products",
      match: { active: true },
      populate: { path: "category_id" },
    });
  if (all.length)
    return all.map((s) => ({
      ...s.toJSON(),
      product_details: s.products.map(productJson),
    }));
  return [
    {
      id: "latest",
      title: "New Arrivals",
      style: "style_1",
      short_description: "Discover the collection",
      product_details: (await products({ limit: 24 })).data,
    },
  ];
}
export async function slides() {
  return Slide.find().sort("position");
}
