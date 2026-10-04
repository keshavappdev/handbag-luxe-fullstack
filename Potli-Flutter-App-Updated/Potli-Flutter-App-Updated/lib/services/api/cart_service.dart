import '../../models/shipping.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class CartService {
  CartService(this._api);

  final ApiBaseHelper _api;

  /// Real delivery-charge + Standard/Express options for [addressId], mirroring
  /// the website's checkout pricing. Returns null on error (caller should fall
  /// back to a flat estimate).
  Future<DeliveryChargeResult?> getDeliveryCharge({
    required String addressId,
  }) async {
    final response = await _api.post(getAppDeliveryChargeApi, {
      'address_id': addressId,
    });
    if (response is! Map || response['error'] == true) return null;
    return DeliveryChargeResult.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> manageCart({
    required String variantId,
    required int quantity,
    String? personalizationText,
  }) {
    return _api.post(manageCartApi, {
      'product_variant_id': variantId,
      'qty': '$quantity',
      if (personalizationText != null)
        'personalization_text': personalizationText,
    });
  }

  Future<void> removeFromCart(String variantId) {
    return _api.post(removeFromCartApi, {'product_variant_id': variantId});
  }

  /// Validates a promo code against the authenticated user's server cart.
  /// The backend calculates the eligible total and returns final_discount.
  Future<PromoCodeResult?> validatePromoCode({
    required String promoCode,
  }) async {
    final response = await _api.post(validatePromoApi, {
      'promo_code': promoCode,
    });
    if (response is! Map) return null;
    final error = response['error'] == true;
    final data = response['data'];
    final row = data is List && data.isNotEmpty
        ? data.first
        : (data is Map ? data : null);
    final discount = row is Map
        ? double.tryParse('${row['final_discount'] ?? ''}')
        : null;
    return PromoCodeResult(
      success: !error,
      message: '${response['message'] ?? ''}',
      discount: (!error ? discount : null) ?? 0,
    );
  }

  /// Validates a Potli Credit code — a separate mechanism from both
  /// promo codes and wallet balance (store credit issued for an approved
  /// return, redeemed via its own one-time code). Only the available
  /// balance is checked/returned here; the actual redemption happens
  /// server-side in Order_model::place_order() once the order is placed
  /// with this code attached, same pattern as promo codes.
  Future<CreditCodeResult?> validateCreditCode(String code) async {
    final response = await _api.post(validateCreditCodeApi, {'code': code});
    if (response is! Map) return null;
    final error = response['error'] == true;
    final data = response['data'];
    final balance = data is Map
        ? double.tryParse('${data['available_balance'] ?? ''}')
        : null;
    return CreditCodeResult(
      success: !error,
      message: '${response['message'] ?? ''}',
      availableBalance: (!error ? balance : null) ?? 0,
    );
  }
}

class PromoCodeResult {
  const PromoCodeResult({
    required this.success,
    required this.message,
    required this.discount,
  });

  final bool success;
  final String message;
  final double discount;
}

class CreditCodeResult {
  const CreditCodeResult({
    required this.success,
    required this.message,
    required this.availableBalance,
  });

  final bool success;
  final String message;
  final double availableBalance;
}
