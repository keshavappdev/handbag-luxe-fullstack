import '../utils/image_url.dart';

class CategoryNode {
  const CategoryNode({
    required this.id,
    required this.name,
    required this.slug,
    required this.level,
    this.image = '',
    this.banner = '',
    this.parentId,
    this.subParentId,
  });

  final String id;
  final String name;
  final String slug;
  final int level;
  final String image;
  final String banner;
  final String? parentId;
  final String? subParentId;

  factory CategoryNode.fromJson(Map<String, dynamic> json, {int level = 1}) {
    return CategoryNode(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      slug: '${json['slug'] ?? ''}',
      level: (json['level'] as num?)?.toInt() ?? level,
      image: normalizeImageUrl(json['image']),
      banner: normalizeImageUrl(json['banner']),
      parentId: json['parent_id'] == null ? null : '${json['parent_id']}',
      subParentId: json['sub_parent_id'] == null
          ? null
          : '${json['sub_parent_id']}',
    );
  }
}
