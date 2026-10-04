import '../../models/app_notification.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class NotificationService {
  NotificationService(this._api);

  final ApiBaseHelper _api;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _api.post(getNotificationApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
