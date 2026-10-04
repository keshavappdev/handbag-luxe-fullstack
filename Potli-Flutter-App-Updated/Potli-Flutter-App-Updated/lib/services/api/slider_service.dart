import '../../models/home_slide.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class SliderService {
  SliderService(this._api);

  final ApiBaseHelper _api;

  Future<List<HomeSlide>> getHomeSlides() async {
    final response = await _api.post(getSliderApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => HomeSlide.fromJson(Map<String, dynamic>.from(e)))
        .where((slide) => slide.image.isNotEmpty)
        .toList();
  }
}
