class PaymentMethodInfo {
  const PaymentMethodInfo({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  static List<PaymentMethodInfo> fromSettingsJson(Map<String, dynamic> json) {
    bool isOn(String key) => '${json[key] ?? '0'}' == '1';
    return [
      PaymentMethodInfo(label: 'Cash on Delivery', enabled: isOn('cod_method')),
      PaymentMethodInfo(
        label: 'Razorpay (Cards / UPI / Netbanking)',
        enabled: isOn('razorpay_payment_method'),
      ),
      PaymentMethodInfo(
        label: 'Direct Bank Transfer',
        enabled: isOn('direct_bank_transfer'),
      ),
      PaymentMethodInfo(
        label: 'PayPal',
        enabled: isOn('paypal_payment_method'),
      ),
      PaymentMethodInfo(
        label: 'Stripe',
        enabled: isOn('stripe_payment_method'),
      ),
      PaymentMethodInfo(label: 'Paytm', enabled: isOn('paytm_payment_method')),
      PaymentMethodInfo(
        label: 'PhonePe',
        enabled: isOn('phonepe_payment_method'),
      ),
      PaymentMethodInfo(
        label: 'Google Pay',
        enabled: isOn('google_pay_payment_method'),
      ),
    ].where((method) => method.enabled).toList();
  }
}
