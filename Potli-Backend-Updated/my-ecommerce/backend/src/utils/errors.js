export class AppError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}
export function assert(condition, status, message) {
  if (!condition) throw new AppError(status, message);
}
export const wrap = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);
export const ok = (res, data = [], extra = {}, status = 200) =>
  res.status(status).json({ error: false, message: "Success", data, ...extra });
export function errorHandler(err, req, res, next) {
  let status = err.status || 500,
    message = err.message;
  if (err.name === "ZodError") {
    status = 422;
    message = err.issues
      .map((x) => `${x.path.join(".")}: ${x.message}`)
      .join("; ");
  }
  if (err.code === 11000) {
    status = 409;
    message = "A record with these unique details already exists";
  }
  if (err.name === "CastError" || err.name === "ValidationError") {
    status = 422;
    message = "Invalid data or identifier";
  }
  if (err.name === "MulterError") {
    status = 422;
    message = "Upload exceeds file count or size limits";
  }
  if (status >= 500) {
    console.error(err.name, err.message);
    message = "Server error. Please try again.";
  }
  res.status(status).json({ error: true, message, data: [] });
}
