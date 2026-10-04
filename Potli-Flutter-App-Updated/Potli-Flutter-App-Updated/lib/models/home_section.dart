import 'product.dart';

/// One admin-configured entry from the CMS `sections` table (get_sections) —
/// "Featured Sections" in Admin, each with a title, a chosen layout style,
/// and the specific products the admin picked for it.
class HomeSection {
  const HomeSection({
    required this.id,
    required this.title,
    required this.style,
    required this.products,
    this.shortDescription = '',
  });

  final String id;
  final String title;
  final String shortDescription;

  /// Raw value from Admin -> Featured Sections: "default", "style_1",
  /// "style_2", "style_3" or "style_4". In the reference app all four
  /// numbered styles render as the same 2-column square product grid
  /// (only trivial padding/radius differences) — "default" is the odd one
  /// out, a full-width stack of tall cards — so [isGridStyle] is what
  /// callers should actually branch on.
  final String style;

  final List<Product> products;

  bool get isGridStyle => style.startsWith('style_');

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final details = json['product_details'];
    final products = details is List
        ? details
              .whereType<Map>()
              .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <Product>[];
    return HomeSection(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      shortDescription: '${json['short_description'] ?? ''}',
      style: '${json['style'] ?? ''}'.trim(),
      products: products,
    );
  }
}
