import 'dart:convert';

import 'image_url.dart';

/// A decoded personalization value: the engraved text, and — when a preview
/// snapshot was captured — the relative path to that baked image.
class DecodedPersonalization {
  const DecodedPersonalization({required this.text, required this.image});

  final String text;
  final String image;

  bool get hasImage => image.isNotEmpty;
}

/// `personalization_text` is stored either as a plain string, or as a JSON
/// envelope `{"text":"...","image":"..."}` when a preview snapshot was
/// captured (see decode_personalization() server-side) — this mirrors that
/// same decoding so raw JSON is never shown to the customer.
DecodedPersonalization decodePersonalization(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return const DecodedPersonalization(text: '', image: '');
  if (value.startsWith('{')) {
    final decoded = _tryDecodeJson(value);
    if (decoded != null && decoded.containsKey('text')) {
      return DecodedPersonalization(
        text: '${decoded['text'] ?? ''}',
        image: normalizeImageUrl(decoded['image']),
      );
    }
  }
  return DecodedPersonalization(text: value, image: '');
}

Map<String, dynamic>? _tryDecodeJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
