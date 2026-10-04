import '../utils/personalization.dart';

class OrderItemSummary {
  const OrderItemSummary({
    required this.id,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
    required this.activeStatus,
    required this.isReturnable,
    required this.returnRequestSubmitted,
    required this.exchangeRequestSubmitted,
    required this.personalizationText,
    required this.personalizationImage,
  });

  final String id;
  final String name;
  final String image;
  final int quantity;
  final double price;
  final String activeStatus;
  final bool isReturnable;
  // '' = no request yet; otherwise the request's status code as a string ('0'..'4').
  final String returnRequestSubmitted;
  final String exchangeRequestSubmitted;
  final String personalizationText;
  // A snapshot of the bag photo with the customer's text positioned on it,
  // exactly as they saw it when personalizing — '' if none was captured.
  final String personalizationImage;

  bool get canRequestReturnOrExchange =>
      activeStatus == 'delivered' &&
      isReturnable &&
      returnRequestSubmitted.isEmpty &&
      exchangeRequestSubmitted.isEmpty;

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    final decoded = decodePersonalization(
      '${json['personalization_text'] ?? ''}',
    );

    return OrderItemSummary(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? json['product_name'] ?? ''}',
      image: '${json['image'] ?? ''}',
      quantity: double.tryParse('${json['quantity'] ?? 1}')?.toInt() ?? 1,
      price:
          double.tryParse(
            '${json['special_price'] ?? json['main_price'] ?? json['price'] ?? 0}',
          ) ??
          0,
      activeStatus: '${json['active_status'] ?? ''}',
      isReturnable:
          '${json['product_is_returnable'] ?? json['is_returnable'] ?? ''}' ==
          '1',
      returnRequestSubmitted: '${json['return_request_submitted'] ?? ''}',
      exchangeRequestSubmitted: '${json['exchange_request_submitted'] ?? ''}',
      personalizationText: decoded.text,
      personalizationImage: decoded.image,
    );
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.total,
    required this.finalTotal,
    required this.paymentMethod,
    required this.dateAdded,
    required this.items,
    this.address = '',
    this.deliveryCharge = 0,
    this.shippingType = '',
    this.trackingId = '',
    this.trackingUrl = '',
    this.courierAgency = '',
  });

  final String id;
  final String status;
  final double total;
  final double finalTotal;
  final String paymentMethod;
  final String address;
  final double deliveryCharge;
  final String shippingType;
  // '' when the order hasn't shipped yet / no courier assigned.
  final String trackingId;
  final String trackingUrl;
  final String courierAgency;
  final String dateAdded;
  final List<OrderItemSummary> items;

  bool get hasTracking => trackingUrl.isNotEmpty;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final items = json['order_items'];
    return OrderSummary(
      id: '${json['id'] ?? ''}',
      status: '${json['active_status'] ?? ''}',
      total: double.tryParse('${json['total'] ?? 0}') ?? 0,
      finalTotal:
          double.tryParse('${json['final_total'] ?? json['total'] ?? 0}') ?? 0,
      paymentMethod: '${json['payment_method'] ?? ''}',
      address: '${json['address'] ?? ''}',
      deliveryCharge: double.tryParse('${json['delivery_charge'] ?? 0}') ?? 0,
      shippingType: '${json['shipping_type'] ?? ''}',
      trackingId: '${json['tracking_id'] ?? ''}',
      trackingUrl: '${json['url'] ?? ''}',
      courierAgency: '${json['courier_agency'] ?? ''}',
      dateAdded: '${json['date_added'] ?? ''}',
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (e) =>
                      OrderItemSummary.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
