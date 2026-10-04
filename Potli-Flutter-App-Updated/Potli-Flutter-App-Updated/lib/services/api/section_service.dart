import '../../models/home_section.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class SectionService {
  SectionService(this._api);

  final ApiBaseHelper _api;

  Future<List<HomeSection>> getSections() async {
    final response = await _api.post(getSectionApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => HomeSection.fromJson(Map<String, dynamic>.from(e)))
        .where((section) => section.products.isNotEmpty)
        .toList();
  }
}
