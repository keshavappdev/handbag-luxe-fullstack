import '../../models/invoice_data.dart';
import '../../models/order_summary.dart';
import '../../models/order_tracking.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class OrderResult {
  const OrderResult({
    required this.success,
    required this.message,
    this.orderId,
    this.payable,
  });

  final bool success;
  final String message;
  final String? orderId;
  final int? payable;
}

class RazorpayOrderResult {
  const RazorpayOrderResult({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
  });

  final String razorpayOrderId;
  final int amount;
  final String currency;
}

class OrderService {
  OrderService(this._api);

  final ApiBaseHelper _api;

  Future<OrderResult> placeOrder({
    required String idempotencyKey,
    required List<String> variantIds,
    required List<int> quantities,
    required String addressId,
    required String paymentMethod,
    String shippingType = 'Standard',
    String? promoCode,
    String? creditCode,
    int walletAmountUsed = 0,
    // JSON object keyed by product_variant_id, e.g. {"123":"EWEWWE😆"} —
    // the backend decodes this and validates personalization per product.
    String? personalizationText,
  }) async {
    final response = await _api.post(placeOrderApi, {
      'idempotency_key': idempotencyKey,
      'product_variant_id': variantIds.join(','),
      'quantity': quantities.join(','),
      'address_id': addressId,
      'payment_method': paymentMethod,
      'wallet_balance_used': '$walletAmountUsed',
      'shipping_type': shippingType,
      if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
      if (creditCode != null && creditCode.isNotEmpty)
        'credit_code': creditCode,
      if (personalizationText != null && personalizationText.isNotEmpty)
        'personalization_text': personalizationText,
    });
    if (response is! Map) {
      return const OrderResult(
        success: false,
        message: 'Unexpected server response',
      );
    }
    final error = response['error'] == true;
    return OrderResult(
      success: !error,
      message: '${response['message'] ?? ''}',
      orderId: response['order_id'] == null ? null : '${response['order_id']}',
      payable: (response['final_total'] as num?)?.toInt(),
    );
  }

  /// Invoice HTML for an order — same server-rendered page the website and
  /// old app show. get_invoice_html actually returns a normal JSON
  /// envelope with the rendered HTML nested in `data` (not a raw HTML
  /// response), so this goes through the usual JSON-decoding post(), not
  /// postForHtml.
  Future<String> getInvoiceHtml(String orderId) async {
    final response = await _api.post(getInvoiceHTML, {'order_id': orderId});
    if (response is! Map || response['error'] == true) {
      throw Exception(
        '${response is Map ? response['message'] : 'Unexpected server response'}',
      );
    }
    final html = response['data'];
    if (html is! String || html.isEmpty) {
      throw Exception(
        '${response['message'] ?? 'No invoice available for this order'}',
      );
    }
    return html;
  }

  /// Same figures as getInvoiceHtml's rendered page, as structured data —
  /// used to build the app's own native PDF invoice with exact GST/tax
  /// parity instead of a simplified reconstruction from OrderSummary.
  Future<InvoiceData?> getInvoiceData(String orderId) async {
    final response = await _api.post(getInvoiceDataApi, {'order_id': orderId});
    if (response is! Map || response['error'] == true) return null;
    final data = response['data'];
    if (data is! Map || data.isEmpty) return null;
    return InvoiceData.fromJson(Map<String, dynamic>.from(data));
  }

  /// Real-time delivery status for the order-detail "Track Package"
  /// button — live Shiprocket tracking when the order has a shipment on
  /// file, otherwise the order's own status history. Never throws for a
  /// missing/unshippable order; returns null so the UI can show a plain
  /// "tracking unavailable" message instead of an error screen.
  Future<OrderTracking?> getOrderTracking(String orderId) async {
    final response = await _api.post(getOrderTrackingApi, {
      'order_id': orderId,
    });
    if (response is! Map || response['error'] == true) return null;
    return OrderTracking.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<OrderSummary>> getOrders() async {
    final result = <OrderSummary>[];
    for (var offset = 0; ; offset += 200) {
      final response = await _api.post(getOrderApi, {
        'limit': '200',
        'offset': '$offset',
      });
      final data = response is Map ? response['data'] : null;
      if (data is! List) break;
      result.addAll(
        data.whereType<Map>().map(
          (e) => OrderSummary.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
      if (data.length < 200) break;
    }
    return result;
  }

  /// Creates a Razorpay-side order for the given (already-placed, pending)
  /// order — the amount is fixed server-side from the order total, so it
  /// can't be tampered with from the client before the SDK checkout opens.
  Future<RazorpayOrderResult?> createRazorpayOrder(String orderId) async {
    final response = await _api.post(razorpayCreateOrderApi, {
      'order_id': orderId,
    });
    if (response is! Map || response['error'] == true) return null;
    final data = response['data'];
    if (data is! Map || data['id'] == null) return null;
    return RazorpayOrderResult(
      razorpayOrderId: '${data['id']}',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: '${data['currency'] ?? 'INR'}',
    );
  }

  /// Verifies a successful Razorpay payment on the server. The backend
  /// derives the owned order/top-up from the verified Razorpay order id.
  Future<bool> confirmOnlinePayment({
    required String paymentId,
    required String razorpayOrderId,
    required String signature,
  }) async {
    try {
      final response = await _api.post(verifyPaymentApi, {
        'payment_id': paymentId,
        'razorpay_order_id': razorpayOrderId,
        'signature': signature,
      });
      return response is Map && response['error'] != true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes a pending order after a failed/cancelled online payment —
  /// mirrors the old app's behaviour of not leaving an unpaid order behind.
  Future<void> cancelPendingOrder(String orderId) async {
    try {
      await _api.post(deleteOrderApi, {'order_id': orderId});
    } catch (_) {
      /* Order remains visible for support reconciliation. */
    }
  }
}
