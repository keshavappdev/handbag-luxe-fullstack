import 'api_base_helper.dart';
import 'api_constants.dart';

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.message,
    required this.date,
  });

  final String id;
  final String type;
  final double amount;
  final String message;
  final String date;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? ''}',
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      message: '${json['message'] ?? ''}',
      date: '${json['date_created'] ?? json['date_added'] ?? ''}',
    );
  }
}

class WalletService {
  WalletService(this._api);

  final ApiBaseHelper _api;

  /// The `transactions` endpoint (with no filters) doubles as the only way
  /// to read the signed-in user's current wallet balance — there's no
  /// dedicated "get profile" endpoint, but this one derives the balance
  /// server-side from the auth token and returns it directly.
  Future<double> getBalance() async {
    final response = await _api.post(getWalTranApi, const {});
    if (response is! Map) return 0;
    return double.tryParse('${response['balance'] ?? 0}') ?? 0;
  }

  Future<List<WalletTransaction>> getTransactions() async {
    final response = await _api.post(getWalTranApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Creates the backend-owned Razorpay order for a wallet top-up.
  Future<Map<String, dynamic>> createTopup(double amount) async {
    final response = await _api.post(
      createWalletOrderApi,
      {'amount': amount.toStringAsFixed(0)},
    );
    return Map<String, dynamic>.from(response['data']);
  }

  Future<bool> creditWallet({
    required String paymentId,
    required String razorpayOrderId,
    required String signature,
  }) async {
    try {
      final response = await _api.post(addTransactionApi, {
        'payment_id': paymentId,
        'razorpay_order_id': razorpayOrderId,
        'signature': signature,
      });
      return response is Map && response['error'] != true;
    } catch (_) {
      return false;
    }
  }
}
