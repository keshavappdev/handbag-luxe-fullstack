const root = (
  import.meta.env.VITE_API_URL || "http://localhost:4000/api/admin"
).replace(/\/$/, "");
export async function api(path, { method = "GET", body } = {}) {
  const token = sessionStorage.getItem("potli.admin");
  const multipart = body instanceof FormData;
  const response = await fetch(`${root}${path}`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(!multipart && body ? { "Content-Type": "application/json" } : {}),
    },
    body: body ? (multipart ? body : JSON.stringify(body)) : undefined,
  });
  let data;
  try {
    data = await response.json();
  } catch {
    throw new Error("API returned an invalid response. Check VITE_API_URL.");
  }
  if (response.status === 401) {
    sessionStorage.removeItem("potli.admin");
    window.dispatchEvent(new Event("auth-expired"));
  }
  if (!response.ok || data.error)
    throw new Error(data.message || "Request failed");
  return data;
}
export async function upload(file) {
  const body = new FormData();
  body.append("image", file);
  return (await api("/images", { method: "POST", body })).data.url;
}
