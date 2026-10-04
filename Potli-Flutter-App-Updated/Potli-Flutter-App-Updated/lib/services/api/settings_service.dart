import '../../models/payment_method_info.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class SettingsService {
  SettingsService(this._api);

  final ApiBaseHelper _api;

  /// `get_settings` nests the requested settings block under `data` —
  /// e.g. {"error":false,"data":{"payment_method":{...}}} — not at the
  /// response root.
  Future<Map<String, dynamic>?> _fetchPaymentSettings() async {
    final response = await _api.post(getSettingApi, const {});
    final data = response is Map ? response['data'] : null;
    final paymentMethod = data is Map ? data['payment_method'] : null;
    return paymentMethod is Map
        ? Map<String, dynamic>.from(paymentMethod)
        : null;
  }

  Future<List<PaymentMethodInfo>> getPaymentMethods() async {
    final paymentMethod = await _fetchPaymentSettings();
    if (paymentMethod == null) return const [];
    return PaymentMethodInfo.fromSettingsJson(paymentMethod);
  }

  /// Razorpay's publishable key id, or null if Razorpay isn't enabled in the
  /// admin panel. Fetched live rather than hardcoded since it's account-
  /// specific and can change per environment (test/live keys).
  Future<String?> getRazorpayKeyId() async {
    final paymentMethod = await _fetchPaymentSettings();
    if (paymentMethod == null) return null;
    final enabled = '${paymentMethod['razorpay_payment_method'] ?? '0'}' == '1';
    if (!enabled) return null;
    final key = '${paymentMethod['razorpay_key_id'] ?? ''}';
    return key.isEmpty ? null : key;
  }

  /// Reads the signed-in user's promo email/WhatsApp opt-in state. Calling
  /// the update endpoint with an empty body updates nothing and just returns
  /// the current values — there's no separate "get" endpoint for this.
  Future<({bool email, bool whatsapp})> getPromoPreferences() async {
    final response = await _api.post(updatePromoPreferencesApi, const {});
    final data = response is Map ? response['data'] : null;
    final map = data is Map ? data : const {};
    return (
      email: '${map['subscribe_promo_email'] ?? '1'}' == '1',
      whatsapp: '${map['subscribe_promo_whatsapp'] ?? '1'}' == '1',
    );
  }

  Future<bool> updatePromoPreferences({
    required bool email,
    required bool whatsapp,
  }) async {
    final response = await _api.post(updatePromoPreferencesApi, {
      'subscribe_promo_email': email ? '1' : '0',
      'subscribe_promo_whatsapp': whatsapp ? '1' : '0',
    });
    return response is Map && response['error'] != true;
  }
}
