import 'package:flutter/material.dart' show Color;

import '../utils/image_url.dart';

/// The approved social-proof badge vocabulary — CMS tags outside this list
/// (used for search/filtering) are not shown as tile badges or highlights.
const List<String> kApprovedSocialProofTags = [
  'Bestseller',
  'Most Viewed',
  'Trending Now',
  'Customer Favourite',
  'New Drop',
  'Limited Edition',
  'Few Left',
  'Back in Stock',
  'Potli Pick',
  'The Statement One',
  'Made to Stand Out',
  'Festive Favourite',
  'Everyday Icon',
  'Day-to-Night',
  'Wedding Guest Pick',
  'Conversation Starter',
];

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.description,
    this.categoryId,
    this.slug,
    this.variantId,
    this.material = '',
    this.dimensions = '',
    this.images = const [],
    this.specialPrice,
    this.rating,
    this.stock,
    this.sku,
    this.brand,
    this.socialProof = const [],
    this.isNew = false,
    this.colorSwatches = const [],
    this.allowPersonalization = false,
    this.personalizeImage = '',
    this.personalizeTextX = 50,
    this.personalizeTextY = 68,
    this.personalizeTextWidth = 60,
    this.personalizeTextColor = '#4a3624',
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final String image;
  final String description;
  final String? categoryId;
  final String? slug;

  /// The default/first product_variant id — required by the cart and order
  /// endpoints, which operate on variants rather than products.
  final String? variantId;

  /// Not modelled by the backend yet; populated from product attributes when
  /// present, otherwise left blank and hidden by the UI.
  final String material;
  final String dimensions;
  final List<String> images;
  final int? specialPrice;
  final double? rating;
  final int? stock;
  final String? sku;
  final String? brand;

  /// Sourced from the backend's free-form `tags` field.
  final List<String> socialProof;
  final bool isNew;

  /// Colour swatch hex values, only populated when the product actually has
  /// a "Color" attribute configured in the CMS — many products won't, so
  /// this is empty by default and the UI must hide the swatch row when it is.
  final List<ColorSwatch> colorSwatches;

  /// Whether the product-detail screen should offer the Personalization
  /// (engraving) card — mirrors the products.allow_personalization flag.
  final bool allowPersonalization;

  /// Base photo the live personalization preview overlays text onto —
  /// falls back to [image] when the CMS hasn't set a dedicated one.
  final String personalizeImage;

  /// Where the engraved text sits on [personalizeImage], as percentages of
  /// its width/height — same convention as the website's live preview.
  final double personalizeTextX;
  final double personalizeTextY;

  /// Max text width as a percentage of the image width, used to auto-shrink
  /// the font so long names still fit.
  final double personalizeTextWidth;
  final String personalizeTextColor;

  factory Product.fromJson(Map<String, dynamic> json) {
    final variants = json['variants'] as List?;
    final firstVariant = (variants != null && variants.isNotEmpty)
        ? variants.first as Map<String, dynamic>
        : null;

    final rawPrice = firstVariant?['price'] ?? json['price'];
    final rawSpecialPrice =
        firstVariant?['special_price'] ?? json['special_price'];
    final price = _toDouble(rawPrice)?.round() ?? 0;
    final specialPriceValue = _toDouble(rawSpecialPrice)?.round();

    final otherImages = json['other_images'];
    final mainImage = normalizeImageUrl(json['image']);
    final images = <String>[
      if (mainImage.isNotEmpty) mainImage,
      if (otherImages is List)
        ...otherImages
            .map((e) => normalizeImageUrl(e))
            .where((e) => e.isNotEmpty),
    ];

    final tags = json['tags'];
    final rawTags = tags is String && tags.isNotEmpty
        ? tags
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : (tags is List ? tags.map((e) => '$e').toList() : const <String>[]);
    final socialProof = kApprovedSocialProofTags
        .where(
          (approved) =>
              rawTags.any((tag) => tag.toLowerCase() == approved.toLowerCase()),
        )
        .toList();

    return Product(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      category: '${json['category_name'] ?? ''}',
      categoryId: json['category_id'] == null ? null : '${json['category_id']}',
      slug: json['slug'] == null ? null : '${json['slug']}',
      variantId: firstVariant?['id'] == null ? null : '${firstVariant!['id']}',
      price: specialPriceValue != null && specialPriceValue > 0
          ? specialPriceValue
          : price,
      specialPrice:
          specialPriceValue != null &&
              specialPriceValue > 0 &&
              specialPriceValue < price
          ? specialPriceValue
          : null,
      image: images.isNotEmpty ? images.first : '',
      images: images,
      description: '${json['description'] ?? json['short_description'] ?? ''}',
      material: '${json['material'] ?? ''}',
      dimensions: '${json['dimensions'] ?? ''}',
      rating: _toDouble(json['rating']),
      stock: _toDouble(json['stock'] ?? firstVariant?['stock'])?.round(),
      sku: json['sku'] == null ? null : '${json['sku']}',
      brand: json['brand'] == null ? null : '${json['brand']}',
      socialProof: socialProof,
      isNew: socialProof.any((label) => label.toLowerCase().contains('new')),
      colorSwatches: _parseColorSwatches(json['attributes']),
      allowPersonalization: '${json['allow_personalization'] ?? ''}' == '1',
      personalizeImage: () {
        final raw = json['personalize_image'];
        final normalized = raw == null ? '' : normalizeImageUrl(raw);
        return normalized.isNotEmpty
            ? normalized
            : (images.isNotEmpty ? images.first : '');
      }(),
      personalizeTextX: _toDouble(json['personalize_text_x']) ?? 50,
      personalizeTextY: _toDouble(json['personalize_text_y']) ?? 68,
      personalizeTextWidth: _toDouble(json['personalize_text_width']) ?? 60,
      personalizeTextColor: '${json['personalize_text_color'] ?? ''}'.isNotEmpty
          ? '${json['personalize_text_color']}'
          : '#4a3624',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static List<ColorSwatch> _parseColorSwatches(dynamic attributes) {
    if (attributes is! List) return const [];
    for (final entry in attributes) {
      if (entry is! Map) continue;
      final name = '${entry['name'] ?? ''}'.toLowerCase();
      if (name != 'color' && name != 'colour') continue;
      final values = entry['value'];
      final swatchTypes = entry['swatche_type'];
      final swatchValues = entry['swatche_value'];
      if (values is! List) continue;
      final swatches = <ColorSwatch>[];
      for (var i = 0; i < values.length; i++) {
        final type = swatchTypes is List && i < swatchTypes.length
            ? '${swatchTypes[i]}'
            : '';
        if (type != '1')
          continue; // only true colour swatches, not text/image options
        final hex = swatchValues is List && i < swatchValues.length
            ? '${swatchValues[i]}'
            : '';
        if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(hex)) continue;
        swatches.add(
          ColorSwatch(
            name: '${values[i]}',
            hex: hex.startsWith('#') ? hex : '#$hex',
          ),
        );
      }
      return swatches;
    }
    return const [];
  }

  Product copyWith({List<ColorSwatch>? colorSwatches}) {
    return Product(
      id: id,
      name: name,
      category: category,
      price: price,
      image: image,
      description: description,
      categoryId: categoryId,
      slug: slug,
      variantId: variantId,
      material: material,
      dimensions: dimensions,
      images: images,
      specialPrice: specialPrice,
      rating: rating,
      stock: stock,
      sku: sku,
      brand: brand,
      socialProof: socialProof,
      isNew: isNew,
      colorSwatches: colorSwatches ?? this.colorSwatches,
      allowPersonalization: allowPersonalization,
      personalizeImage: personalizeImage,
      personalizeTextX: personalizeTextX,
      personalizeTextY: personalizeTextY,
      personalizeTextWidth: personalizeTextWidth,
      personalizeTextColor: personalizeTextColor,
    );
  }
}

class ColorSwatch {
  const ColorSwatch({required this.name, required this.hex});

  final String name;
  final String hex;

  Color get color => Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
}

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.personalizationText,
  });

  final Product product;
  final int quantity;
  final String? personalizationText;
}
