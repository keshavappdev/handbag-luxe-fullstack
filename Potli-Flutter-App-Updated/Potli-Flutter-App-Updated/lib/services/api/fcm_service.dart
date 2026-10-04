import 'api_base_helper.dart';
import 'api_constants.dart';

class FcmService {
  FcmService(this._api);

  final ApiBaseHelper _api;

  Future<void> updateFcmToken(String fcmToken) {
    return _api.post(updateFcmApi, {'fcm_id': fcmToken});
  }
}
