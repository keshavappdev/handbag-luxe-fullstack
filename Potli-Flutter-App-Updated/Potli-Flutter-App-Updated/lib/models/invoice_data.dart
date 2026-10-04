/// One tax component applied to an item's tax-inclusive price (e.g. CGST,
/// SGST, IGST) — amount already extracted out of that price, not added on
/// top of it.
class InvoiceTaxLine {
  const InvoiceTaxLine({
    required this.title,
    required this.percentage,
    required this.amount,
  });

  final String title;
  final double percentage;
  final double amount;

  factory InvoiceTaxLine.fromJson(Map<String, dynamic> json) {
    return InvoiceTaxLine(
      title: '${json['title'] ?? ''}',
      percentage: double.tryParse('${json['percentage'] ?? 0}') ?? 0,
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
    );
  }
}

class InvoiceItem {
  const InvoiceItem({
    required this.name,
    required this.variant,
    required this.priceExclTax,
    required this.priceInclTax,
    required this.taxBreakdown,
    required this.totalTax,
    required this.quantity,
    required this.subtotal,
  });

  final String name;
  final String variant;
  final double priceExclTax;
  final double priceInclTax;
  final List<InvoiceTaxLine> taxBreakdown;
  final double totalTax;
  final int quantity;
  final double subtotal;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final breakdown = json['tax_breakdown'];
    return InvoiceItem(
      name: '${json['name'] ?? ''}',
      variant: '${json['variant'] ?? ''}',
      priceExclTax: double.tryParse('${json['price_excl_tax'] ?? 0}') ?? 0,
      priceInclTax: double.tryParse('${json['price_incl_tax'] ?? 0}') ?? 0,
      taxBreakdown: breakdown is List
          ? breakdown
                .whereType<Map>()
                .map(
                  (e) => InvoiceTaxLine.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      totalTax: double.tryParse('${json['total_tax'] ?? 0}') ?? 0,
      quantity: int.tryParse('${json['quantity'] ?? 1}') ?? 1,
      subtotal: double.tryParse('${json['subtotal'] ?? 0}') ?? 0,
    );
  }
}

class InvoiceParty {
  const InvoiceParty({
    required this.name,
    required this.address,
    this.email = '',
    this.state = '',
    this.mobile = '',
    this.taxName = '',
    this.taxNumber = '',
  });

  final String name;
  final String address;
  final String email;
  final String state;
  final String mobile;
  final String taxName;
  final String taxNumber;

  factory InvoiceParty.soldByFromJson(Map<String, dynamic> json) {
    return InvoiceParty(
      name: '${json['name'] ?? ''}',
      address: '${json['address'] ?? ''}',
      email: '${json['support_email'] ?? ''}',
      taxName: '${json['tax_name'] ?? ''}',
      taxNumber: '${json['tax_number'] ?? ''}',
    );
  }

  factory InvoiceParty.billToFromJson(Map<String, dynamic> json) {
    return InvoiceParty(
      name: '${json['name'] ?? ''}',
      address: '${json['address'] ?? ''}',
      state: '${json['state'] ?? ''}',
      mobile: '${json['mobile'] ?? ''}',
      email: '${json['email'] ?? ''}',
    );
  }
}

/// Same figures as the on-screen/admin invoice (get_invoice_data mirrors
/// api-order-invoice.php's own arithmetic) — used to build a native PDF
/// that matches it exactly instead of a simplified reconstruction.
class InvoiceData {
  const InvoiceData({
    required this.orderId,
    required this.invoiceNo,
    required this.orderDate,
    required this.currency,
    required this.paymentMethod,
    required this.soldBy,
    required this.billTo,
    required this.items,
    required this.orderTotal,
    required this.deliveryCharge,
    required this.walletBalance,
    this.promoCode,
    required this.promoDiscount,
    required this.specialDiscountPercent,
    required this.specialDiscountAmount,
    required this.finalTotal,
    this.totalPayableCod,
  });

  final String orderId;
  final String invoiceNo;
  final String orderDate;
  final String currency;
  final String paymentMethod;
  final InvoiceParty soldBy;
  final InvoiceParty billTo;
  final List<InvoiceItem> items;
  final double orderTotal;
  final double deliveryCharge;
  final double walletBalance;
  final String? promoCode;
  final double promoDiscount;
  final double specialDiscountPercent;
  final double specialDiscountAmount;
  final double finalTotal;
  final double? totalPayableCod;

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final totals = json['totals'] is Map
        ? Map<String, dynamic>.from(json['totals'])
        : <String, dynamic>{};
    return InvoiceData(
      orderId: '${json['order_id'] ?? ''}',
      invoiceNo: '${json['invoice_no'] ?? ''}',
      orderDate: '${json['order_date'] ?? ''}',
      currency: '${json['currency'] ?? ''}',
      paymentMethod: '${json['payment_method'] ?? ''}',
      soldBy: InvoiceParty.soldByFromJson(
        json['sold_by'] is Map
            ? Map<String, dynamic>.from(json['sold_by'])
            : {},
      ),
      billTo: InvoiceParty.billToFromJson(
        json['bill_to'] is Map
            ? Map<String, dynamic>.from(json['bill_to'])
            : {},
      ),
      items: itemsJson is List
          ? itemsJson
                .whereType<Map>()
                .map((e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      orderTotal: double.tryParse('${totals['order_total'] ?? 0}') ?? 0,
      deliveryCharge: double.tryParse('${totals['delivery_charge'] ?? 0}') ?? 0,
      walletBalance: double.tryParse('${totals['wallet_balance'] ?? 0}') ?? 0,
      promoCode: totals['promo_code'] == null
          ? null
          : '${totals['promo_code']}',
      promoDiscount: double.tryParse('${totals['promo_discount'] ?? 0}') ?? 0,
      specialDiscountPercent:
          double.tryParse('${totals['special_discount_percent'] ?? 0}') ?? 0,
      specialDiscountAmount:
          double.tryParse('${totals['special_discount_amount'] ?? 0}') ?? 0,
      finalTotal: double.tryParse('${totals['final_total'] ?? 0}') ?? 0,
      totalPayableCod: totals['total_payable_cod'] == null
          ? null
          : double.tryParse('${totals['total_payable_cod']}'),
    );
  }
}
