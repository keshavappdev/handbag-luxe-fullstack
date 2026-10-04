import '../../models/return_exchange.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class ServiceResult {
  const ServiceResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class ReturnExchangeService {
  ReturnExchangeService(this._api);

  final ApiBaseHelper _api;

  Future<ServiceResult> submitReturnRequest({
    required String orderItemId,
    required String reason,
    String? otherReason,
    String customerNotes = '',
  }) async {
    final response = await _api.post(submitReturnRequestApi, {
      'order_item_id': orderItemId,
      'return_reason': reason == 'other' ? (otherReason ?? '') : reason,
      'customer_notes': customerNotes,
    });
    if (response is! Map) {
      return const ServiceResult(
        success: false,
        message: 'Unexpected server response',
      );
    }
    final error = response['error'] == true;
    return ServiceResult(
      success: !error,
      message: '${response['message'] ?? ''}',
    );
  }

  Future<List<ReturnRequest>> getMyReturnRequests() async {
    final response = await _api.post(getMyReturnRequestsApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => ReturnRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ExchangeVariantOption>> getExchangeVariants(
    String orderItemId,
  ) async {
    final response = await _api.post(getExchangeVariantsApi, {
      'order_item_id': orderItemId,
    });
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (e) => ExchangeVariantOption.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<ServiceResult> submitExchangeRequest({
    required String orderItemId,
    required String exchangeForVariantId,
    required String reason,
    String? otherReason,
    String customerNotes = '',
  }) async {
    final response = await _api.post(submitExchangeRequestApi, {
      'order_item_id': orderItemId,
      'exchange_for_variant_id': exchangeForVariantId,
      'exchange_reason': reason == 'other' ? (otherReason ?? '') : reason,
      'customer_notes': customerNotes,
    });
    if (response is! Map) {
      return const ServiceResult(
        success: false,
        message: 'Unexpected server response',
      );
    }
    final error = response['error'] == true;
    return ServiceResult(
      success: !error,
      message: '${response['message'] ?? ''}',
    );
  }

  Future<List<ExchangeRequest>> getMyExchangeRequests() async {
    final response = await _api.post(getMyExchangeRequestsApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => ExchangeRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<PotliCredit>> getMyPotliCredits() async {
    final response = await _api.post(getMyPotliCreditsApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => PotliCredit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ServiceResult> validateCreditCode(String code) async {
    final response = await _api.post(validateCreditCodeApi, {'code': code});
    if (response is! Map) {
      return const ServiceResult(
        success: false,
        message: 'Unexpected server response',
      );
    }
    final error = response['error'] == true;
    return ServiceResult(
      success: !error,
      message: '${response['message'] ?? ''}',
    );
  }
}
