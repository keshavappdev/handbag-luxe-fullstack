class ShippingOption {
  const ShippingOption({
    required this.deliveryChargeWithCod,
    required this.deliveryChargeWithoutCod,
    required this.estimatedDeliveryDays,
  });

  final double deliveryChargeWithCod;
  final double deliveryChargeWithoutCod;
  final int? estimatedDeliveryDays;

  String get etaLabel {
    final days = estimatedDeliveryDays;
    if (days == null || days <= 0) return '';
    return 'Estimated delivery in $days ${days == 1 ? 'day' : 'days'}';
  }

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    return ShippingOption(
      deliveryChargeWithCod:
          double.tryParse('${json['delivery_charge_with_cod'] ?? 0}') ?? 0,
      deliveryChargeWithoutCod:
          double.tryParse('${json['delivery_charge_without_cod'] ?? 0}') ?? 0,
      estimatedDeliveryDays: json['estimated_delivery_days'] == null
          ? null
          : int.tryParse('${json['estimated_delivery_days']}'),
    );
  }
}

class DeliveryChargeResult {
  const DeliveryChargeResult({
    required this.deliveryChargeWithCod,
    required this.deliveryChargeWithoutCod,
    required this.standard,
    required this.express,
  });

  final double deliveryChargeWithCod;
  final double deliveryChargeWithoutCod;
  final ShippingOption? standard;
  final ShippingOption? express;

  bool get hasExpressOption => express != null;
  // Standard present but Express isn't — worth telling the customer why,
  // rather than just silently only offering Standard.
  bool get expressExplicitlyUnavailable => standard != null && express == null;

  factory DeliveryChargeResult.fromJson(Map<String, dynamic> json) {
    final options = json['shipping_options'];
    final standardJson = options is Map ? options['standard'] : null;
    final expressJson = options is Map ? options['express'] : null;
    return DeliveryChargeResult(
      deliveryChargeWithCod:
          double.tryParse('${json['delivery_charge_with_cod'] ?? 0}') ?? 0,
      deliveryChargeWithoutCod:
          double.tryParse('${json['delivery_charge_without_cod'] ?? 0}') ?? 0,
      standard: standardJson is Map
          ? ShippingOption.fromJson(Map<String, dynamic>.from(standardJson))
          : null,
      express: expressJson is Map
          ? ShippingOption.fromJson(Map<String, dynamic>.from(expressJson))
          : null,
    );
  }
}
