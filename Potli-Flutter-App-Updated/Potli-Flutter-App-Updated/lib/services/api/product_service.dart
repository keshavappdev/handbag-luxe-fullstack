import '../../models/product.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class PersonalizationSettings {
  const PersonalizationSettings({
    required this.enabled,
    required this.heading,
    required this.description,
    required this.maxCharacters,
  });

  final bool enabled;
  final String heading;
  final String description;
  final int maxCharacters;

  static const _defaults = PersonalizationSettings(
    enabled: true,
    heading: 'Add your personal touch',
    description: "Engrave a mix of emoji, text and numbers to make it unmistakably yours.",
    maxCharacters: 20,
  );

  factory PersonalizationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return _defaults;
    return PersonalizationSettings(
      enabled: '${json['enabled'] ?? '1'}' != '0',
      heading: '${json['heading'] ?? _defaults.heading}',
      description: '${json['description'] ?? _defaults.description}',
      maxCharacters:
          int.tryParse('${json['max_characters'] ?? ''}') ??
          _defaults.maxCharacters,
    );
  }
}

class ProductService {
  ProductService(this._api);

  final ApiBaseHelper _api;

  Future<PersonalizationSettings> getPersonalizationSettings() async {
    final response = await _api.post(getPersonalizationSettingsApi, const {});
    final data = response is Map ? response['data'] : null;
    return PersonalizationSettings.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }

  /// Uploads the baked engraving preview (a data:image/... URI) and returns
  /// the relative path the backend stored it under (matches what web's
  /// decode_personalization() envelope expects as `image`), or null on
  /// failure — callers fall back to a text-only personalization in that case.
  Future<String?> savePersonalizationPreview(String dataUrl) async {
    try {
      final response = await _api.post(savePersonalizationPreviewApi, {
        'image': dataUrl,
      });
      final data = response is Map ? response['data'] : null;
      final path = data is Map ? data['path'] : null;
      return path is String && path.isNotEmpty ? path : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Product>> getCompleteTheLook(String productId) async {
    final response = await _api.post(getCompleteTheLookApi, {
      'product_id': productId,
    });
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    String? id,
    int? minPrice,
    int? maxPrice,
    String? sort,
    int limit = 200,
    int offset = 0,
  }) async {
    final response = await _api.post(getProductApi, {
      if (categoryId != null) kCategoryId: categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (id != null) kId: id,
      if (minPrice != null) 'min_price': '$minPrice',
      if (maxPrice != null) 'max_price': '$maxPrice',
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      'limit': '$limit',
      'offset': '$offset',
    });

    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
