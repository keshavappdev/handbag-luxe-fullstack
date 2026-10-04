import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { api, upload } from "./api";
import "./style.css";
const money = (n) =>
  new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(n || 0);
const date = (n) =>
  new Date(n).toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
const tabs = [
  "Overview",
  "Products",
  "Categories",
  "Orders",
  "Customers",
  "Homepage",
  "Support",
  "Returns",
  "Promotions",
];
function App() {
  const [token, setToken] = useState(sessionStorage.getItem("potli.admin"));
  const [tab, setTab] = useState("Overview");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [revision, setRevision] = useState(0);
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    const expired = () => setToken(null);
    window.addEventListener("auth-expired", expired);
    return () => window.removeEventListener("auth-expired", expired);
  }, []);
  async function run(fn, message) {
    setBusy(true);
    setError("");
    try {
      await fn();
      if (message) setNotice(message);
      setRevision((x) => x + 1);
      return true;
    } catch (e) {
      setError(e.message);
      return false;
    } finally {
      setBusy(false);
    }
  }
  if (!token) return <Login onLogin={setToken} />;
  const props = { run, revision, busy, setError };
  return (
    <div className="layout">
      <aside>
        <div className="wordmark">
          POTLI<span>STUDIO / ADMINISTRATION</span>
        </div>
        <nav>
          {tabs.map((t, i) => (
            <button
              key={t}
              className={t === tab ? "active" : ""}
              onClick={() => {
                setTab(t);
                setError("");
                setNotice("");
              }}
            >
              <span className="nav-number">
                {String(i + 1).padStart(2, "0")}
              </span>
              {t}
            </button>
          ))}
        </nav>
        <div className="sidebar-foot">
          UNAPOLOGETICALLY YOU.
          <button
            onClick={() => {
              sessionStorage.removeItem("potli.admin");
              setToken(null);
            }}
          >
            Sign out ↗
          </button>
        </div>
      </aside>
      <main>
        <header>
          <div>
            <span className="eyebrow">THE POTLI WORKSPACE</span>
            <h1>{tab}</h1>
          </div>
          <div className="live">
            <i /> Connected to your store
          </div>
        </header>
        {error && (
          <div role="alert" className="alert error">
            {error}
            <button onClick={() => setError("")}>×</button>
          </div>
        )}
        {notice && (
          <div role="status" className="alert success">
            {notice}
            <button onClick={() => setNotice("")}>×</button>
          </div>
        )}
        {busy && <div className="working">Saving changes…</div>}
        {tab === "Overview" ? (
          <Dashboard {...props} />
        ) : tab === "Products" ? (
          <Products {...props} />
        ) : tab === "Categories" ? (
          <Categories {...props} />
        ) : tab === "Orders" ? (
          <Orders {...props} />
        ) : tab === "Customers" ? (
          <Customers {...props} />
        ) : tab === "Homepage" ? (
          <Homepage {...props} />
        ) : tab === "Support" ? (
          <Support {...props} />
        ) : tab === "Returns" ? (
          <Returns {...props} />
        ) : (
          <Promotions {...props} />
        )}
        <footer>
          KA AF IR ANA / COMMERCE STUDIO{" "}
          <span>Admin changes are served directly to the customer app.</span>
        </footer>
      </main>
    </div>
  );
}
function Login({ onLogin }) {
  const [email, setEmail] = useState(""),
    [password, setPassword] = useState(""),
    [error, setError] = useState(""),
    [busy, setBusy] = useState(false);
  async function submit(e) {
    e.preventDefault();
    setBusy(true);
    try {
      const r = await api("/login", {
        method: "POST",
        body: { email, password },
      });
      sessionStorage.setItem("potli.admin", r.token);
      onLogin(r.token);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className="login">
      <section>
        <span className="eyebrow">POTLI / STUDIO</span>
        <h1>
          Considered design.
          <br />
          Seamless commerce.
        </h1>
        <p>
          Your collection, customers and orders.
          <br />
          One place to bring it all together.
        </p>
        <span className="login-bottom">UNAPOLOGETICALLY YOU.</span>
      </section>
      <form onSubmit={submit}>
        <span className="eyebrow">WELCOME BACK</span>
        <h2>Enter your studio</h2>
        <p>Sign in with your administrator account.</p>
        {error && (
          <p role="alert" className="error">
            {error}
          </p>
        )}
        <Field
          label="Email"
          type="email"
          value={email}
          onChange={setEmail}
          required
        />
        <Field
          label="Password"
          type="password"
          value={password}
          onChange={setPassword}
          required
        />
        <button disabled={busy} className="primary">
          {busy ? "Signing in…" : "Sign in →"}
        </button>
        <small>
          Create your first admin with <code>npm run admin</code> in the
          backend.
        </small>
      </form>
    </div>
  );
}
function Field({ label, onChange, type = "text", ...props }) {
  return (
    <label className="field">
      <span>{label}</span>
      {type === "textarea" ? (
        <textarea {...props} onChange={(e) => onChange(e.target.value)} />
      ) : (
        <input
          {...props}
          type={type}
          onChange={(e) =>
            onChange(
              e.target.type === "checkbox" ? e.target.checked : e.target.value,
            )
          }
        />
      )}
    </label>
  );
}
function Select({ label, children, onChange, ...props }) {
  return (
    <label className="field">
      <span>{label}</span>
      <select {...props} onChange={(e) => onChange(e.target.value)}>
        {children}
      </select>
    </label>
  );
}
function useData(path, revision, setError) {
  const [data, setData] = useState(null);
  useEffect(() => {
    let alive = true;
    setData(null);
    api(path)
      .then((r) => {
        if (alive) setData(r);
      })
      .catch((e) => {
        if (alive) setError(e.message);
      });
    return () => {
      alive = false;
    };
  }, [path, revision]);
  return data;
}
function Empty({ children = "No records yet." }) {
  return <div className="empty">{children}</div>;
}
function Pager({ offset, setOffset, total }) {
  return (
    <div className="pager">
      <button
        disabled={offset === 0}
        onClick={() => setOffset(Math.max(0, offset - 50))}
      >
        ← Previous
      </button>
      <span>
        {offset + 1}–{Math.min(offset + 50, total)} of {total}
      </span>
      <button
        disabled={offset + 50 >= total}
        onClick={() => setOffset(offset + 50)}
      >
        Next →
      </button>
    </div>
  );
}
function Dashboard(p) {
  const r = useData("/dashboard", p.revision, p.setError);
  if (!r) return <Empty>Loading your store…</Empty>;
  const d = r.data;
  return (
    <>
      <div className="intro">
        <div>
          <span className="eyebrow">STORE AT A GLANCE</span>
          <h2>
            A little clarity.
            <br />A lot of possibility.
          </h2>
        </div>
        <p>
          Keep your collection fresh and
          <br />
          every customer in the loop.
        </p>
      </div>
      <div className="stats">
        {[
          ["Active products", d.products],
          ["Customers", d.customers],
          ["Orders", d.orders],
          ["Collected revenue", money(d.revenue)],
        ].map(([label, value]) => (
          <article key={label}>
            <span>{label}</span>
            <strong>{value}</strong>
            <small>
              {label === "Collected revenue"
                ? "Cash / online collected, excluding wallet & credit"
                : "Live from your database"}
            </small>
          </article>
        ))}
      </div>
      <div className="panel">
        <div className="panel-head">
          <h2>Needs your attention</h2>
          <span className="badge">{d.pending} orders to fulfil</span>
        </div>
        <h3>Low stock</h3>
        {d.lowStock.length ? (
          <table>
            <thead>
              <tr>
                <th>Product</th>
                <th>Units remaining</th>
              </tr>
            </thead>
            <tbody>
              {d.lowStock.map((x) => (
                <tr key={x.id}>
                  <td>{x.name}</td>
                  <td>
                    <span className="badge">{x.stock} left</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <Empty>Your active products have healthy stock levels.</Empty>
        )}
      </div>
    </>
  );
}
const blankProduct = {
  name: "",
  category_id: "",
  description: "",
  material: "",
  dimensions: "",
  image: "",
  other_images: [],
  price: 0,
  special_price: 0,
  stock: 0,
  sku: "",
  brand: "POTLI",
  tags: [],
  active: true,
  allow_personalization: false,
  personalize_image: "",
  personalize_text_x: 50,
  personalize_text_y: 68,
  personalize_text_width: 60,
  personalize_text_color: "#4a3624",
  colors: [],
  is_returnable: true,
};
function ImageInput({ label, value, onChange, setError, multiple = false }) {
  const [busy, setBusy] = useState(false);
  async function pick(e) {
    setBusy(true);
    try {
      const urls = [];
      for (const f of Array.from(e.target.files || []))
        urls.push(await upload(f));
      onChange(multiple ? [...value, ...urls] : urls[0] || value);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className="field">
      <span>{label}</span>
      <div className="images">
        {(multiple ? value : [value]).filter(Boolean).map((x, i) => (
          <div key={`${x}${i}`}>
            <img src={x} alt="Product upload" />
            <button
              type="button"
              onClick={() =>
                onChange(multiple ? value.filter((_, n) => n !== i) : "")
              }
            >
              Remove
            </button>
          </div>
        ))}
      </div>
      <input
        aria-label={label}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        multiple={multiple}
        disabled={busy}
        onChange={pick}
      />
      <small>
        {busy ? "Uploading…" : "JPEG, PNG or WebP. Maximum 5 MB each."}
      </small>
    </div>
  );
}
function Products(p) {
  const [offset, setOffset] = useState(0),
    [editing, setEditing] = useState(null);
  const r = useData(
      `/products?limit=50&offset=${offset}`,
      p.revision,
      p.setError,
    ),
    cats = useData("/categories", p.revision, p.setError);
  const [search, setSearch] = useState("");
  const list = (r?.data || []).filter((x) =>
    x.name.toLowerCase().includes(search.toLowerCase()),
  );
  const change = (k, v) => setEditing((x) => ({ ...x, [k]: v }));
  async function save(e) {
    e.preventDefault();
    if (
      await p.run(
        () =>
          api(`/products${editing.id ? `/${editing.id}` : ""}`, {
            method: editing.id ? "PUT" : "POST",
            body: editing,
          }),
        "Product saved. It is available through the customer API.",
      )
    )
      setEditing(null);
  }
  return (
    <>
      <div className="toolbar">
        <p>The collection, curated by you.</p>
        <button
          className="primary"
          onClick={() => setEditing({ ...blankProduct })}
        >
          + Add product
        </button>
      </div>
      <div className="panel">
        <input
          className="search"
          aria-label="Search visible products"
          placeholder="Search this page…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Product</th>
                <th>Category</th>
                <th>Price</th>
                <th>Stock</th>
                <th>Visibility</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {list.map((x) => (
                <tr key={x.id}>
                  <td>
                    <div className="product-cell">
                      <img src={x.image} alt="" />
                      <div>
                        <b>{x.name}</b>
                        <small>{x.sku}</small>
                      </div>
                    </div>
                  </td>
                  <td>{x.category_id?.name}</td>
                  <td>{money(x.special_price || x.price)}</td>
                  <td>{x.stock}</td>
                  <td>
                    <span className="badge">
                      {x.active ? "Published" : "Archived"}
                    </span>
                  </td>
                  <td>
                    <button
                      onClick={() =>
                        setEditing({
                          ...blankProduct,
                          ...x,
                          category_id:
                            x.category_id?.id || x.category_id?._id || "",
                        })
                      }
                    >
                      Edit
                    </button>
                    <button
                      className="danger"
                      disabled={p.busy}
                      onClick={() =>
                        window.confirm(
                          "Archive this product? Order history is preserved.",
                        ) &&
                        p.run(
                          () => api(`/products/${x.id}`, { method: "DELETE" }),
                          "Product archived",
                        )
                      }
                    >
                      Archive
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {!list.length && <Empty>Add your first bag to begin.</Empty>}
        <Pager offset={offset} setOffset={setOffset} total={r?.total || 0} />
      </div>
      {editing && (
        <Modal
          title={editing.id ? "Edit product" : "New product"}
          onClose={() => setEditing(null)}
        >
          <form onSubmit={save}>
            <div className="form-grid">
              <Field
                label="Product name"
                value={editing.name}
                onChange={(v) => change("name", v)}
                required
              />
              <Field
                label="SKU"
                value={editing.sku}
                onChange={(v) => change("sku", v)}
                required
              />
              <Select
                label="Category"
                value={editing.category_id}
                onChange={(v) => change("category_id", v)}
                required
              >
                <option value="">Select category</option>
                {cats?.data.map((c) => (
                  <option key={c.id} value={c.id}>
                    {"— ".repeat(c.level - 1)}
                    {c.name}
                  </option>
                ))}
              </Select>
              <Field
                label="Brand"
                value={editing.brand}
                onChange={(v) => change("brand", v)}
              />
              <Field
                label="Price (whole INR)"
                type="number"
                min="1"
                value={editing.price}
                onChange={(v) => change("price", Number(v))}
                required
              />
              <Field
                label="Sale price (0 = no sale)"
                type="number"
                min="0"
                value={editing.special_price}
                onChange={(v) => change("special_price", Number(v))}
              />
              <Field
                label="Stock"
                type="number"
                min="0"
                value={editing.stock}
                onChange={(v) => change("stock", Number(v))}
                required
              />
              <Field
                label="Material"
                value={editing.material}
                onChange={(v) => change("material", v)}
              />
              <Field
                label="Dimensions"
                value={editing.dimensions}
                onChange={(v) => change("dimensions", v)}
              />
              <Field
                label="Tags, comma separated"
                value={editing.tags.join(",")}
                onChange={(v) =>
                  change(
                    "tags",
                    v.split(",").map((x) => x.trim()),
                  )
                }
              />
            </div>
            <Field
              label="Description"
              type="textarea"
              value={editing.description}
              onChange={(v) => change("description", v)}
            />
            <ImageInput
              label="Main product image"
              value={editing.image}
              onChange={(v) => change("image", v)}
              setError={p.setError}
            />
            <ImageInput
              label="Gallery images"
              multiple
              value={editing.other_images}
              onChange={(v) => change("other_images", v)}
              setError={p.setError}
            />
            <div className="checks">
              {[
                ["active", "Published"],
                ["is_returnable", "Returnable"],
                ["allow_personalization", "Allow engraving"],
              ].map(([k, label]) => (
                <label key={k}>
                  <input
                    type="checkbox"
                    checked={editing[k]}
                    onChange={(e) => change(k, e.target.checked)}
                  />
                  {label}
                </label>
              ))}
            </div>
            {editing.allow_personalization && (
              <>
                <ImageInput
                  label="Personalization base image (optional)"
                  value={editing.personalize_image}
                  onChange={(v) => change("personalize_image", v)}
                  setError={p.setError}
                />
                <div className="form-grid">
                  {[
                    "personalize_text_x",
                    "personalize_text_y",
                    "personalize_text_width",
                  ].map((k) => (
                    <Field
                      key={k}
                      label={k.replaceAll("_", " ")}
                      type="number"
                      min="0"
                      max="100"
                      value={editing[k]}
                      onChange={(v) => change(k, Number(v))}
                    />
                  ))}
                  <Field
                    label="Text color"
                    type="color"
                    value={editing.personalize_text_color}
                    onChange={(v) => change("personalize_text_color", v)}
                  />
                </div>
              </>
            )}
            <h3>Color swatches</h3>
            <p className="muted">
              Display options share this product’s SKU, price and stock.
            </p>
            {editing.colors.map((c, i) => (
              <div className="inline" key={i}>
                <Field
                  label="Color name"
                  value={c.name}
                  onChange={(v) =>
                    change(
                      "colors",
                      editing.colors.map((x, n) =>
                        n === i ? { ...x, name: v } : x,
                      ),
                    )
                  }
                />
                <Field
                  label="Color"
                  type="color"
                  value={c.hex}
                  onChange={(v) =>
                    change(
                      "colors",
                      editing.colors.map((x, n) =>
                        n === i ? { ...x, hex: v } : x,
                      ),
                    )
                  }
                />
                <button
                  type="button"
                  onClick={() =>
                    change(
                      "colors",
                      editing.colors.filter((_, n) => n !== i),
                    )
                  }
                >
                  Remove
                </button>
              </div>
            ))}
            <button
              type="button"
              onClick={() =>
                change("colors", [
                  ...editing.colors,
                  { name: "", hex: "#000000" },
                ])
              }
            >
              + Add swatch
            </button>
            <div className="form-actions">
              <button type="button" onClick={() => setEditing(null)}>
                Cancel
              </button>
              <button className="primary" disabled={p.busy || !editing.image}>
                Save product
              </button>
            </div>
          </form>
        </Modal>
      )}
    </>
  );
}
function Modal({ title, onClose, children }) {
  return (
    <div className="modal-backdrop">
      <section
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className="modal"
      >
        <div className="modal-head">
          <h2>{title}</h2>
          <button aria-label="Close" onClick={onClose}>
            ×
          </button>
        </div>
        {children}
      </section>
    </div>
  );
}
function Categories(p) {
  const r = useData("/categories", p.revision, p.setError);
  const [form, setForm] = useState(null);
  const set = (k, v) => setForm((x) => ({ ...x, [k]: v }));
  async function save(e) {
    e.preventDefault();
    if (
      await p.run(
        () =>
          api(`/categories${form.id ? `/${form.id}` : ""}`, {
            method: form.id ? "PUT" : "POST",
            body: form,
          }),
        "Category saved",
      )
    )
      setForm(null);
  }
  return (
    <>
      <div className="toolbar">
        <p>Three levels: collection → bag type → style.</p>
        <button
          className="primary"
          onClick={() =>
            setForm({ name: "", parent_id: null, image: "", banner: "" })
          }
        >
          + Add category
        </button>
      </div>
      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Level</th>
              <th>Parent</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {r?.data.map((x) => (
              <tr key={x.id}>
                <td>{x.name}</td>
                <td>{x.level}</td>
                <td>
                  {r.data.find((y) => y.id === x.parent_id)?.name || "Root"}
                </td>
                <td>
                  <button onClick={() => setForm(x)}>Edit</button>
                  <button
                    className="danger"
                    onClick={() =>
                      window.confirm("Delete empty category?") &&
                      p.run(
                        () => api(`/categories/${x.id}`, { method: "DELETE" }),
                        "Category deleted",
                      )
                    }
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {form && (
        <Modal title="Category" onClose={() => setForm(null)}>
          <form onSubmit={save}>
            <Field
              label="Name"
              value={form.name}
              onChange={(v) => set("name", v)}
              required
            />
            <Select
              label="Parent"
              value={form.parent_id || ""}
              disabled={!!form.id}
              onChange={(v) => set("parent_id", v || null)}
            >
              <option value="">Root collection</option>
              {r?.data
                .filter((x) => x.level < 3)
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} (level {c.level})
                  </option>
                ))}
            </Select>
            <ImageInput
              label="Category image"
              value={form.image}
              onChange={(v) => set("image", v)}
              setError={p.setError}
            />
            <ImageInput
              label="Category banner"
              value={form.banner}
              onChange={(v) => set("banner", v)}
              setError={p.setError}
            />
            <button className="primary" disabled={p.busy}>
              Save category
            </button>
          </form>
        </Modal>
      )}
    </>
  );
}
function Orders(p) {
  const [offset, setOffset] = useState(0),
    [selected, setSelected] = useState(null),
    [status, setStatus] = useState(""),
    [tracking, setTracking] = useState({
      tracking_id: "",
      tracking_url: "",
      courier_agency: "",
    });
  const r = useData(
    `/orders?limit=50&offset=${offset}`,
    p.revision,
    p.setError,
  );
  async function open(x) {
    await p.run(async () => {
      const d = (await api(`/orders/${x.id}`)).data;
      setSelected(d);
      setStatus("");
      setTracking({
        tracking_id: d.tracking_id || "",
        tracking_url: d.url || "",
        courier_agency: d.courier_agency || "",
      });
    });
  }
  return (
    <>
      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Order</th>
              <th>Customer</th>
              <th>Date</th>
              <th>Payable</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {r?.data.map((x) => (
              <tr key={x.id}>
                <td>#{x.id.slice(-8).toUpperCase()}</td>
                <td>{x.user?.username}</td>
                <td>{date(x.createdAt)}</td>
                <td>{money(x.final_total)}</td>
                <td>
                  <span className="badge">{x.status}</span>
                </td>
                <td>
                  <button onClick={() => open(x)}>View details ↗</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {r?.data.length === 0 && <Empty>No orders yet.</Empty>}
        <Pager offset={offset} setOffset={setOffset} total={r?.total || 0} />
      </div>
      {selected && (
        <Modal
          title={`Order #${selected.id.slice(-8).toUpperCase()}`}
          onClose={() => setSelected(null)}
        >
          <p>
            {selected.user?.username} / {selected.user?.email}
          </p>
          <p>{selected.address}</p>
          <p>{selected.shippingAddress?.mobile}</p>
          <div className="order-meta">
            <span className="badge">{selected.active_status}</span>
            <span>
              {selected.payment_method} · {selected.payment_status}
            </span>
          </div>
          {selected.order_items.map((i) => (
            <div className="order-line" key={i.id}>
              <img src={i.image} alt="" />
              <div>
                <b>{i.name}</b>
                <p>
                  {i.quantity} × {money(i.price)}
                </p>
                {i.personalization_text && (
                  <small>Personalization: {i.personalization_text}</small>
                )}
              </div>
              <strong>{money(i.quantity * i.price)}</strong>
            </div>
          ))}
          <div className="totals">
            <p>
              Merchandise <b>{money(selected.total)}</b>
            </p>
            <p>
              Shipping <b>{money(selected.delivery_charge)}</b>
            </p>
            <p>
              Promotion <b>−{money(selected.promo_discount)}</b>
            </p>
            <p>
              Wallet / credit{" "}
              <b>
                −
                {money(
                  (selected.wallet_used || 0) + (selected.credit_used || 0),
                )}
              </b>
            </p>
            <p>
              Payable <b>{money(selected.final_total)}</b>
            </p>
          </div>
          <form
            onSubmit={async (e) => {
              e.preventDefault();
              if (
                await p.run(
                  () =>
                    api(`/orders/${selected.id}/status`, {
                      method: "PATCH",
                      body: { status, ...tracking },
                    }),
                  "Order status updated",
                )
              )
                setSelected(null);
            }}
          >
            <Select
              label="Next status"
              value={status}
              onChange={setStatus}
              required
            >
              <option value="">Select status</option>
              {(
                {
                  awaiting: ["cancelled"],
                  received: ["processed", "cancelled"],
                  processed: ["shipped", "cancelled"],
                  shipped: ["delivered"],
                }[selected.active_status] || []
              ).map((x) => (
                <option key={x}>{x}</option>
              ))}
            </Select>
            {Object.entries(tracking).map(([k, v]) => (
              <Field
                key={k}
                label={k.replaceAll("_", " ")}
                value={v}
                onChange={(value) => setTracking((x) => ({ ...x, [k]: value }))}
              />
            ))}
            <button className="primary" disabled={!status || p.busy}>
              Update order
            </button>
          </form>
          <h3>Status history</h3>
          {selected.history.map((h, i) => (
            <p key={i}>
              {h.status} — {date(h.date)}
            </p>
          ))}
        </Modal>
      )}
    </>
  );
}
function Customers(p) {
  const [offset, setOffset] = useState(0);
  const r = useData(
    `/customers?limit=50&offset=${offset}`,
    p.revision,
    p.setError,
  );
  return (
    <div className="panel">
      <table>
        <thead>
          <tr>
            <th>Customer</th>
            <th>Email</th>
            <th>Mobile</th>
            <th>Joined</th>
            <th>Wallet</th>
          </tr>
        </thead>
        <tbody>
          {r?.data.map((c) => (
            <tr key={c.id}>
              <td>{c.username}</td>
              <td>{c.email}</td>
              <td>{c.mobile || "—"}</td>
              <td>{date(c.createdAt)}</td>
              <td>{money(c.balance)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <Pager offset={offset} setOffset={setOffset} total={r?.total || 0} />
    </div>
  );
}
function Homepage(p) {
  const [kind, setKind] = useState("slides"),
    [form, setForm] = useState(null);
  const r = useData(`/content/${kind}`, p.revision, p.setError),
    products = useData("/products?limit=200", p.revision, p.setError);
  const set = (k, v) => setForm((x) => ({ ...x, [k]: v }));
  async function save(e) {
    e.preventDefault();
    if (
      await p.run(
        () =>
          api(`/content/${kind}${form.id ? `/${form.id}` : ""}`, {
            method: form.id ? "PUT" : "POST",
            body: form,
          }),
        "Homepage updated",
      )
    )
      setForm(null);
  }
  return (
    <>
      <div className="toolbar">
        <div>
          <button
            className={kind === "slides" ? "selected" : ""}
            onClick={() => setKind("slides")}
          >
            Campaign images
          </button>
          <button
            className={kind === "sections" ? "selected" : ""}
            onClick={() => setKind("sections")}
          >
            Featured sections
          </button>
        </div>
        <button
          className="primary"
          onClick={() =>
            setForm(
              kind === "slides"
                ? {
                    title: "",
                    subtitle: "",
                    button_text: "SHOP NOW",
                    type: "default",
                    type_id: "",
                    image: "",
                    link: "",
                    position: 0,
                  }
                : {
                    title: "",
                    short_description: "",
                    style: "style_1",
                    products: [],
                    position: 0,
                  },
            )
          }
        >
          + Add {kind === "slides" ? "image" : "section"}
        </button>
      </div>
      <div className="panel">
        {r?.data.map((x) => (
          <div className="content-row" key={x.id}>
            {x.image && <img src={x.image} alt="" />}
            <b>{x.title}</b>
            <span>Position {x.position}</span>
            <button onClick={() => setForm(x)}>Edit</button>
            <button
              className="danger"
              onClick={() =>
                window.confirm("Delete this homepage item?") &&
                p.run(
                  () => api(`/content/${kind}/${x.id}`, { method: "DELETE" }),
                  "Deleted",
                )
              }
            >
              Delete
            </button>
          </div>
        ))}
        {!r?.data.length && (
          <Empty>
            {kind === "sections"
              ? "Without custom sections, the homepage automatically uses the latest 24 products."
              : "Add campaign photography for the home page."}
          </Empty>
        )}
      </div>
      {form && (
        <Modal title="Homepage content" onClose={() => setForm(null)}>
          <form onSubmit={save}>
            <Field
              label="Title"
              value={form.title}
              onChange={(v) => set("title", v)}
              required
            />
            <Field
              label="Position"
              type="number"
              value={form.position}
              onChange={(v) => set("position", Number(v))}
            />
            {kind === "slides" ? (
              <>
                <Field
                  label="Subtitle"
                  value={form.subtitle}
                  onChange={(v) => set("subtitle", v)}
                />
                <Field
                  label="Button label"
                  value={form.button_text}
                  onChange={(v) => set("button_text", v)}
                />
                <ImageInput
                  label="Campaign image"
                  value={form.image}
                  onChange={(v) => set("image", v)}
                  setError={p.setError}
                />
                <Select
                  label="Link type"
                  value={form.type}
                  onChange={(v) => set("type", v)}
                >
                  <option value="default">Collection</option>
                  <option value="products">Product</option>
                  <option value="categories">Category</option>
                </Select>
                <Field
                  label="Target product/category ID"
                  value={form.type_id}
                  onChange={(v) => set("type_id", v)}
                />
                <Field
                  label="External link (optional)"
                  value={form.link}
                  onChange={(v) => set("link", v)}
                />
              </>
            ) : (
              <>
                <Field
                  label="Short description"
                  value={form.short_description}
                  onChange={(v) => set("short_description", v)}
                />
                <Select
                  label="Layout"
                  value={form.style}
                  onChange={(v) => set("style", v)}
                >
                  {["default", "style_1", "style_2", "style_3", "style_4"].map(
                    (s) => (
                      <option key={s}>{s}</option>
                    ),
                  )}
                </Select>
                <p>Select products (latest 200):</p>
                <div className="product-select">
                  {products?.data
                    .filter((x) => x.active)
                    .map((x) => (
                      <label key={x.id}>
                        <input
                          type="checkbox"
                          checked={form.products.includes(x.id)}
                          onChange={(e) =>
                            set(
                              "products",
                              e.target.checked
                                ? [...form.products, x.id]
                                : form.products.filter((y) => y !== x.id),
                            )
                          }
                        />
                        {x.name}
                      </label>
                    ))}
                </div>
              </>
            )}
            <button className="primary" disabled={p.busy}>
              Save content
            </button>
          </form>
        </Modal>
      )}
    </>
  );
}
function Support(p) {
  const r = useData("/tickets", p.revision, p.setError);
  const [ticket, setTicket] = useState(null),
    [messages, setMessages] = useState([]),
    [reply, setReply] = useState(""),
    [status, setStatus] = useState("2");
  async function open(t) {
    await p.run(async () => {
      setMessages((await api(`/tickets/${t.id}/messages`)).data);
      setTicket(t);
      setReply("");
    });
  }
  return (
    <>
      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Subject</th>
              <th>Customer</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {r?.data.map((t) => (
              <tr key={t.id}>
                <td>{t.subject}</td>
                <td>{t.user?.email}</td>
                <td>
                  {
                    {
                      1: "Pending",
                      2: "Open",
                      3: "Resolved",
                      4: "Closed",
                      5: "Reopened",
                    }[t.status]
                  }
                </td>
                <td>
                  <button onClick={() => open(t)}>Open conversation</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {ticket && (
        <Modal title={ticket.subject} onClose={() => setTicket(null)}>
          <p>{ticket.description}</p>
          <div className="messages">
            {messages.map((m) => (
              <div className={`message ${m.user_type}`} key={m.id}>
                <b>{m.name}</b>
                <p>{m.message}</p>
                {m.attachments?.map((a) => (
                  <a
                    key={a.media}
                    href={a.media}
                    target="_blank"
                    rel="noreferrer"
                  >
                    View image
                  </a>
                ))}
                <small>{date(m.createdAt)}</small>
              </div>
            ))}
          </div>
          <form
            onSubmit={async (e) => {
              e.preventDefault();
              if (
                await p.run(
                  () =>
                    api(`/tickets/${ticket.id}/messages`, {
                      method: "POST",
                      body: { message: reply, status },
                    }),
                  "Reply sent",
                )
              )
                setTicket(null);
            }}
          >
            <Field
              label="Reply"
              type="textarea"
              value={reply}
              onChange={setReply}
              required
            />
            <Select label="Ticket status" value={status} onChange={setStatus}>
              <option value="2">Open</option>
              <option value="3">Resolved</option>
              <option value="4">Closed</option>
            </Select>
            <button className="primary" disabled={p.busy}>
              Send reply
            </button>
          </form>
        </Modal>
      )}
    </>
  );
}
function Returns(p) {
  const r = useData("/requests", p.revision, p.setError);
  return (
    <div className="panel">
      <p>
        Complete a return only after receiving and inspecting the item.
        Completion restores stock and issues customer credit. Exchange
        completion restores the original stock and deducts replacement stock.
      </p>
      <table>
        <thead>
          <tr>
            <th>Customer / item</th>
            <th>Request</th>
            <th>Reason</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {r?.data.map((x) => (
            <tr key={x.id}>
              <td>
                <b>{x.product_name}</b>
                <small>{x.user?.email}</small>
                <small>Order: {x.order}</small>
                {x.exchange_for_variant_id && (
                  <small>Replacement: {x.exchange_for_variant_id}</small>
                )}
              </td>
              <td>{x.kind}</td>
              <td>
                {x.reason}
                <small>{x.customer_notes}</small>
              </td>
              <td>{x.status}</td>
              <td>
                {(x.status === "pending"
                  ? ["approved", "rejected"]
                  : x.status === "approved"
                    ? ["completed"]
                    : []
                ).map((status) => (
                  <button
                    key={status}
                    disabled={p.busy}
                    onClick={() =>
                      window.confirm(`Mark request ${status}?`) &&
                      p.run(
                        () =>
                          api(`/requests/${x.id}`, {
                            method: "PATCH",
                            body: { status },
                          }),
                        "Request updated",
                      )
                    }
                  >
                    {status}
                  </button>
                ))}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
function Promotions(p) {
  const r = useData("/content/promos", p.revision, p.setError);
  const [form, setForm] = useState(null);
  return (
    <>
      <div className="toolbar">
        <p>Percentage discounts are validated at checkout.</p>
        <button
          className="primary"
          onClick={() =>
            setForm({
              code: "",
              percent: 10,
              minimum: 0,
              expires: "",
              active: true,
            })
          }
        >
          + Add promotion
        </button>
      </div>
      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Code</th>
              <th>Discount</th>
              <th>Minimum</th>
              <th>Expires</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {r?.data.map((x) => (
              <tr key={x.id}>
                <td>{x.code}</td>
                <td>{x.percent}%</td>
                <td>{money(x.minimum)}</td>
                <td>{date(x.expires)}</td>
                <td>
                  <button
                    onClick={() =>
                      setForm({ ...x, expires: x.expires.slice(0, 10) })
                    }
                  >
                    Edit
                  </button>
                  <button
                    onClick={() =>
                      window.confirm("Delete promo?") &&
                      p.run(
                        () =>
                          api(`/content/promos/${x.id}`, { method: "DELETE" }),
                        "Promotion deleted",
                      )
                    }
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {form && (
        <Modal title="Promotion" onClose={() => setForm(null)}>
          <form
            onSubmit={async (e) => {
              e.preventDefault();
              if (
                await p.run(
                  () =>
                    api(`/content/promos${form.id ? `/${form.id}` : ""}`, {
                      method: form.id ? "PUT" : "POST",
                      body: form,
                    }),
                  "Promotion saved",
                )
              )
                setForm(null);
            }}
          >
            {[
              ["code", "Code", "text"],
              ["percent", "Discount %", "number"],
              ["minimum", "Minimum order INR", "number"],
              ["expires", "Expiry date", "date"],
            ].map(([k, label, type]) => (
              <Field
                key={k}
                label={label}
                type={type}
                value={form[k]}
                onChange={(v) => setForm((x) => ({ ...x, [k]: v }))}
                required
              />
            ))}
            <label>
              <input
                type="checkbox"
                checked={form.active}
                onChange={(e) =>
                  setForm((x) => ({ ...x, active: e.target.checked }))
                }
              />{" "}
              Active
            </label>
            <div className="form-actions">
              <button className="primary" disabled={p.busy}>
                Save promotion
              </button>
            </div>
          </form>
        </Modal>
      )}
    </>
  );
}
createRoot(document.getElementById("root")).render(<App />);
