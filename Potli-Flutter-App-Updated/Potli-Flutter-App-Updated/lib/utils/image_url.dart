import '../services/api/api_constants.dart';

/// Normalizes backend-provided image/banner values and treats a bare domain
/// as an empty image value so image fallbacks behave correctly.
String normalizeImageUrl(dynamic raw) {
  final value = '${raw ?? ''}';
  if (value.isEmpty) return '';
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return value;
  final hasRealPath = uri.path.isNotEmpty && uri.path != '/';
  if (!hasRealPath && uri.query.isEmpty) return '';

  // In local development the Node backend's PUBLIC_URL is commonly
  // http://localhost:4000, while an Android emulator reaches that same
  // server through 10.0.2.2. Rebase only loopback URLs onto API_BASE_URL;
  // production/external image URLs remain untouched.
  if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
    final apiUri = Uri.tryParse(baseUrl);
    if (apiUri != null && apiUri.hasScheme && apiUri.host.isNotEmpty) {
      return uri
          .replace(
            scheme: apiUri.scheme,
            host: apiUri.host,
            port: apiUri.hasPort ? apiUri.port : null,
          )
          .toString();
    }
  }
  return value;
}
