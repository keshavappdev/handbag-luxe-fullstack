class ReturnRequest {
  const ReturnRequest({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.productName,
    required this.productImage,
    required this.reason,
    required this.statusLabel,
    required this.dateCreated,
  });

  final String id;
  final String orderId;
  final String orderItemId;
  final String productName;
  final String productImage;
  final String reason;
  final String statusLabel;
  final String dateCreated;

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: '${json['id'] ?? ''}',
      orderId: '${json['order_id'] ?? ''}',
      orderItemId: '${json['order_item_id'] ?? ''}',
      productName: '${json['product_name'] ?? ''}',
      productImage: '${json['product_image'] ?? ''}',
      reason: '${json['return_reason'] ?? ''}',
      statusLabel: '${json['status_label'] ?? ''}',
      dateCreated: '${json['date_created'] ?? ''}',
    );
  }
}

class ExchangeRequest {
  const ExchangeRequest({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.productName,
    required this.productImage,
    required this.reason,
    required this.statusLabel,
    required this.priceDifference,
    required this.dateCreated,
  });

  final String id;
  final String orderId;
  final String orderItemId;
  final String productName;
  final String productImage;
  final String reason;
  final String statusLabel;
  final double priceDifference;
  final String dateCreated;

  factory ExchangeRequest.fromJson(Map<String, dynamic> json) {
    return ExchangeRequest(
      id: '${json['id'] ?? ''}',
      orderId: '${json['order_id'] ?? ''}',
      orderItemId: '${json['order_item_id'] ?? ''}',
      productName: '${json['product_name'] ?? ''}',
      productImage: '${json['product_image'] ?? ''}',
      reason: '${json['exchange_reason'] ?? ''}',
      statusLabel: '${json['status_label'] ?? ''}',
      priceDifference: double.tryParse('${json['price_difference'] ?? 0}') ?? 0,
      dateCreated: '${json['date_created'] ?? ''}',
    );
  }
}

/// A candidate variant (size/colour) to exchange an order item into.
class ExchangeVariantOption {
  const ExchangeVariantOption({
    required this.id,
    required this.label,
    required this.price,
    required this.stock,
  });

  final String id;
  final String label;
  final double price;
  // null = not stock-tracked (always available).
  final int? stock;

  bool get isOutOfStock => stock != null && stock! < 1;

  factory ExchangeVariantOption.fromJson(Map<String, dynamic> json) {
    return ExchangeVariantOption(
      id: '${json['id'] ?? ''}',
      label: '${json['label'] ?? ''}',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      stock: json['stock'] == null ? null : int.tryParse('${json['stock']}'),
    );
  }
}

class PotliCredit {
  const PotliCredit({
    required this.code,
    required this.originalValue,
    required this.availableBalance,
    required this.status,
    required this.issueDate,
    required this.expiryDate,
  });

  final String code;
  final double originalValue;
  final double availableBalance;
  final String status;
  final String issueDate;
  final String expiryDate;

  bool get isActive => status == 'active';

  factory PotliCredit.fromJson(Map<String, dynamic> json) {
    return PotliCredit(
      code: '${json['code'] ?? ''}',
      originalValue: double.tryParse('${json['original_value'] ?? 0}') ?? 0,
      availableBalance:
          double.tryParse('${json['available_balance'] ?? 0}') ?? 0,
      status: '${json['status'] ?? ''}',
      issueDate: '${json['issue_date'] ?? ''}',
      expiryDate: '${json['expiry_date'] ?? ''}',
    );
  }
}
