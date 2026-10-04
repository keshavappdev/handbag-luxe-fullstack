import '../../models/category_node.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class CategoryService {
  CategoryService(this._api);

  final ApiBaseHelper _api;

  Future<List<CategoryNode>> getTopCategories() async {
    final response = await _api.post(getCatApi, const {});
    return _parseList(response, level: 1);
  }

  Future<List<CategoryNode>> getSubCategories(String categoryId) async {
    final response = await _api.post(getSubcatApi, {kCategoryId: categoryId});
    return _parseList(response, level: 2);
  }

  Future<List<CategoryNode>> getCollectionItems(
    String categoryId,
    String subCategoryId,
  ) async {
    final response = await _api.post(getCategoryCollectionItemsApi, {
      kSubCategoryId: subCategoryId,
    });
    final items = _parseList(response, level: 3);
    if (items.isNotEmpty) return items;
    final parents = await getSubCategories(categoryId);
    final match = parents.where((c) => c.id == subCategoryId).toList();
    return match;
  }

  List<CategoryNode> _parseList(dynamic response, {required int level}) {
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (e) =>
              CategoryNode.fromJson(Map<String, dynamic>.from(e), level: level),
        )
        .toList();
  }
}
