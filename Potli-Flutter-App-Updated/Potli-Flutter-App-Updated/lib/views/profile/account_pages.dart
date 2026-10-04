import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../models/address.dart';
import '../../models/order_summary.dart';
import '../../models/return_exchange.dart';
import '../../services/api/address_service.dart';
import '../../services/api/notification_service.dart';
import '../../services/api/order_service.dart';
import '../../services/api/return_exchange_service.dart';
import '../../services/api/settings_service.dart';
import '../../services/api/wallet_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';
import 'invoice_view.dart';
import 'order_tracking_view.dart';
import 'return_exchange_sheets.dart';

class _SignInRequired extends StatelessWidget {
  const _SignInRequired();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SIGN IN\nREQUIRED',
            textAlign: TextAlign.center,
            style: context.textTheme.editorialSmall,
          ),
          const SizedBox(height: 16),
          const MicroLabel('SIGN IN TO VIEW THIS PAGE', color: KColors.gray),
          const SizedBox(height: 28),
          FullWidthButton(
            label: 'SIGN IN',
            onPressed: () => Get.offAllNamed(Routes.login),
          ),
          const SizedBox(height: 10),
          FullWidthButton(
            label: 'CREATE ACCOUNT',
            inverse: true,
            onPressed: () => Get.offAllNamed(Routes.register),
          ),
        ],
      ),
    ),
  );
}

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  Future<List<OrderSummary>>? _future;

  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isSignedIn.value) {
      _future = Get.find<OrderService>().getOrders();
    }
  }

  void _reload() => setState(() {
    _future = Get.find<OrderService>().getOrders();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: _future == null
          ? const _SignInRequired()
          : FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
                  children: [
                    Text('MY\nORDERS', style: context.textTheme.editorialSmall),
                    const SizedBox(height: 34),
                    if (orders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: MicroLabel(
                            'NO ORDERS YET',
                            color: KColors.gray,
                          ),
                        ),
                      )
                    else
                      for (final order in orders) ...[
                        _OrderCard(order: order, onChanged: _reload),
                        const SectionDivider(),
                      ],
                  ],
                );
              },
            ),
    );
  }
}

/// Full detail view for a single order — reached by tapping an order card
/// in OrdersView. Built from the same OrderSummary already fetched for the
/// list (no extra API call), reusing the list's own item-row rendering
/// (personalization, Return/Exchange actions) so behaviour stays identical
/// between the two screens.
class OrderDetailView extends StatelessWidget {
  const OrderDetailView({
    super.key,
    required this.order,
    required this.onChanged,
  });
  final OrderSummary order;
  final VoidCallback onChanged;

  Future<void> _openTracking() async {
    final uri = Uri.tryParse(order.trackingUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = order.total;
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
        children: [
          Text('ORDER\n#${order.id}', style: context.textTheme.editorialSmall),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MicroLabel(order.status, color: KColors.gray),
              MicroLabel(order.dateAdded, color: KColors.gray),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.to(() => InvoiceView(order: order)),
                  child: const Text('VIEW INVOICE'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Get.to(() => OrderTrackingView(orderId: order.id)),
                  child: const Text('TRACK PACKAGE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionDivider(),
          const SizedBox(height: 20),
          const MicroLabel('ITEMS'),
          const SizedBox(height: 14),
          for (final item in order.items)
            _OrderItemRow(item: item, orderId: order.id, onChanged: onChanged),
          const SizedBox(height: 20),
          const SectionDivider(),
          const SizedBox(height: 20),
          const MicroLabel('PAYMENT'),
          const SizedBox(height: 12),
          _DetailRow(label: 'METHOD', value: order.paymentMethod.toUpperCase()),
          if (order.shippingType.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              label: 'SHIPPING',
              value: order.shippingType.toUpperCase(),
            ),
          ],
          const SizedBox(height: 20),
          const SectionDivider(),
          const SizedBox(height: 20),
          const MicroLabel('SUMMARY'),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'SUBTOTAL',
            value: '₹${subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'DELIVERY',
            value: order.deliveryCharge == 0
                ? 'COMPLIMENTARY'
                : '₹${order.deliveryCharge.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'TOTAL',
            value: '₹${order.finalTotal.toStringAsFixed(0)}',
            strong: true,
          ),
          if (order.address.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionDivider(),
            const SizedBox(height: 20),
            const MicroLabel('DELIVERY ADDRESS'),
            const SizedBox(height: 12),
            Text(
              order.address,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
          if (order.hasTracking) ...[
            const SizedBox(height: 20),
            const SectionDivider(),
            const SizedBox(height: 20),
            const MicroLabel('TRACKING'),
            const SizedBox(height: 12),
            if (order.courierAgency.isNotEmpty)
              _DetailRow(
                label: 'COURIER',
                value: order.courierAgency.toUpperCase(),
              ),
            if (order.trackingId.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(label: 'TRACKING ID', value: order.trackingId),
            ],
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _openTracking,
              child: const Text('TRACK PACKAGE'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      MicroLabel(label, color: strong ? KColors.black : KColors.gray),
      Text(
        value,
        style: TextStyle(
          fontSize: strong ? 15 : 13,
          fontWeight: strong ? FontWeight.w600 : null,
        ),
      ),
    ],
  );
}

const Map<String, String> _kReturnStatusLabels = {
  '0': 'RETURN REQUESTED',
  '1': 'RETURN APPROVED',
  '2': 'RETURN REJECTED',
  '3': 'RETURN ON HOLD',
  '4': 'COLLECTION UPDATE',
};
const Map<String, String> _kExchangeStatusLabels = {
  '0': 'EXCHANGE REQUESTED',
  '1': 'EXCHANGE APPROVED',
  '2': 'EXCHANGE REJECTED',
};

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onChanged});
  final OrderSummary order;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    // Nested GestureDetectors (the Return/Exchange links below) still
    // get their own taps correctly — Flutter hit-tests to the deepest
    // widget under the finger, it doesn't bubble like a DOM click, so
    // wrapping the whole card doesn't steal taps meant for them.
    onTap: () =>
        Get.to(() => OrderDetailView(order: order, onChanged: onChanged)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER #${order.id}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              MicroLabel(order.status, color: KColors.gray),
            ],
          ),
          const SizedBox(height: 8),
          MicroLabel(order.dateAdded, color: KColors.gray),
          const SizedBox(height: 12),
          for (final item in order.items)
            _OrderItemRow(item: item, orderId: order.id, onChanged: onChanged),
          const SizedBox(height: 8),
          Text(
            '₹${order.finalTotal.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    ),
  );
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.orderId,
    required this.onChanged,
  });
  final OrderItemSummary item;
  final String orderId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final statusLabel = item.returnRequestSubmitted.isNotEmpty
        ? _kReturnStatusLabels[item.returnRequestSubmitted]
        : item.exchangeRequestSubmitted.isNotEmpty
        ? _kExchangeStatusLabels[item.exchangeRequestSubmitted]
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity} x ${item.name}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (item.personalizationText.isNotEmpty ||
                    item.personalizationImage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (item.personalizationImage.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.personalizationImage,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.personalizationText.isNotEmpty)
                          Expanded(
                            child: Text(
                              '✎ Personalized: "${item.personalizationText}"',
                              style: const TextStyle(
                                fontSize: 11,
                                color: KColors.gray,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (statusLabel != null)
            MicroLabel(statusLabel, color: KColors.gray)
          else if (item.canRequestReturnOrExchange) ...[
            _SmallTextButton(
              label: 'Return',
              onTap: () => showReturnRequestSheet(
                context,
                item,
                orderId: orderId,
                onDone: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            _SmallTextButton(
              label: 'Exchange',
              onTap: () => showExchangeRequestSheet(
                context,
                item,
                orderId: orderId,
                onDone: onChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallTextButton extends StatelessWidget {
  const _SmallTextButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}

class AddressBookView extends StatefulWidget {
  const AddressBookView({super.key});

  @override
  State<AddressBookView> createState() => _AddressBookViewState();
}

class _AddressBookViewState extends State<AddressBookView> {
  final _service = Get.find<AddressService>();
  final _signedIn = Get.find<AuthController>().isSignedIn.value;
  Future<List<Address>>? _future;

  @override
  void initState() {
    super.initState();
    if (_signedIn) _future = _service.getAddresses();
  }

  void _reload() => setState(() {
    _future = _service.getAddresses();
  });

  Future<void> _delete(Address address) async {
    await _service.deleteAddress(address.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: !_signedIn
          ? const _SignInRequired()
          : FutureBuilder<List<Address>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final addresses = snapshot.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                  children: [
                    Text(
                      'ADDRESS\nBOOK',
                      style: context.textTheme.editorialSmall,
                    ),
                    const SizedBox(height: 34),
                    if (addresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: MicroLabel(
                            'NO SAVED ADDRESSES',
                            color: KColors.gray,
                          ),
                        ),
                      )
                    else
                      for (final address in addresses) ...[
                        _AddressCard(
                          address: address,
                          onEdit: () async {
                            await Get.toNamed(
                              Routes.addressForm,
                              arguments: address,
                            );
                            _reload();
                          },
                          onDelete: () => _delete(address),
                        ),
                        const SectionDivider(),
                      ],
                  ],
                );
              },
            ),
      bottomNavigationBar: !_signedIn
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FullWidthButton(
                  label: 'ADD NEW ADDRESS',
                  onPressed: () async {
                    await Get.toNamed(Routes.addressForm);
                    _reload();
                  },
                ),
              ),
            ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                address.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (address.isDefault)
              const MicroLabel('DEFAULT', color: KColors.gray),
          ],
        ),
        const SizedBox(height: 8),
        Text(address.mobile, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          '${address.address}${address.landmark.isNotEmpty ? ', ${address.landmark}' : ''}, ${address.city} ${address.pincode}',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            UnderlineAction('EDIT', onTap: onEdit),
            const SizedBox(width: 24),
            UnderlineAction('DELETE', onTap: onDelete),
          ],
        ),
      ],
    ),
  );
}

class PaymentMethodsView extends StatefulWidget {
  const PaymentMethodsView({super.key});

  @override
  State<PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<PaymentMethodsView> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isSignedIn.value) {
      _future = Get.find<SettingsService>().getPaymentMethods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: _future == null
          ? const _SignInRequired()
          : FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final methods = snapshot.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
                  children: [
                    Text(
                      'PAYMENT\nMETHODS',
                      style: context.textTheme.editorialSmall,
                    ),
                    const SizedBox(height: 14),
                    const MicroLabel(
                      'ACCEPTED AT CHECKOUT',
                      color: KColors.gray,
                    ),
                    const SizedBox(height: 30),
                    if (methods.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: MicroLabel(
                            'NO PAYMENT METHODS CONFIGURED',
                            color: KColors.gray,
                          ),
                        ),
                      )
                    else
                      for (final method in methods) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.check, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  method.label,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SectionDivider(),
                      ],
                  ],
                );
              },
            ),
    );
  }
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isSignedIn.value) {
      _future = Get.find<NotificationService>().getNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: _future == null
          ? const _SignInRequired()
          : FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notifications = snapshot.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
                  children: [
                    Text(
                      'NOTIFICATIONS',
                      style: context.textTheme.editorialSmall,
                    ),
                    const SizedBox(height: 34),
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: MicroLabel(
                            'NO NOTIFICATIONS YET',
                            color: KColors.gray,
                          ),
                        ),
                      )
                    else
                      for (final notification in notifications) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              MicroLabel(
                                notification.dateSent,
                                color: KColors.gray,
                              ),
                            ],
                          ),
                        ),
                        const SectionDivider(),
                      ],
                  ],
                );
              },
            ),
    );
  }
}

class PotliCreditsView extends StatefulWidget {
  const PotliCreditsView({super.key});

  @override
  State<PotliCreditsView> createState() => _PotliCreditsViewState();
}

class _PotliCreditsViewState extends State<PotliCreditsView> {
  Future<List<PotliCredit>>? _future;

  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isSignedIn.value) {
      _future = Get.find<ReturnExchangeService>().getMyPotliCredits();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green.shade700;
      case 'redeemed':
        return KColors.gray;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: _future == null
          ? const _SignInRequired()
          : FutureBuilder<List<PotliCredit>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final credits = snapshot.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
                  children: [
                    Text(
                      'POTLI\nCREDITS',
                      style: context.textTheme.editorialSmall,
                    ),
                    const SizedBox(height: 10),
                    const MicroLabel(
                      'THE VALUE IS ALREADY IN YOUR WALLET BALANCE — ENTER THE CODE AT CHECKOUT TO REDEEM IT',
                      color: KColors.gray,
                    ),
                    const SizedBox(height: 30),
                    if (credits.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: MicroLabel(
                            'NO CREDITS YET',
                            color: KColors.gray,
                          ),
                        ),
                      )
                    else
                      for (final credit in credits) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      credit.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    MicroLabel(
                                      credit.isActive
                                          ? 'AVAILABLE: ₹${credit.availableBalance.toStringAsFixed(2)} · VALID TILL ${credit.expiryDate}'
                                          : 'ISSUED ${credit.issueDate}',
                                      color: KColors.gray,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${credit.originalValue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  MicroLabel(
                                    credit.status,
                                    color: _statusColor(credit.status),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SectionDivider(),
                      ],
                  ],
                );
              },
            ),
    );
  }
}

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final _wallet = Get.find<WalletService>();
  bool _signedIn = false;
  double _balance = 0;
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  bool _recharging = false;
  String? _razorpayKeyId;
  Razorpay? _razorpay;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _signedIn = Get.find<AuthController>().isSignedIn.value;
    if (_signedIn) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _wallet.getBalance(),
      _wallet.getTransactions(),
      Get.find<SettingsService>().getRazorpayKeyId(),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = results[0] as double;
      _transactions = results[1] as List<WalletTransaction>;
      _razorpayKeyId = results[2] as String?;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _razorpay?.clear();
    super.dispose();
  }

  void _showAddMoneySheet() {
    final keyId = _razorpayKeyId;
    if (keyId == null) {
      Get.rawSnackbar(message: 'Online payment is not available right now.');
      return;
    }
    _amountController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MicroLabel('ADD MONEY'),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'AMOUNT (₹)'),
            ),
            const SizedBox(height: 20),
            FullWidthButton(
              label: 'PROCEED TO PAY',
              busy: _recharging,
              onPressed: _recharging
                  ? null
                  : () {
                      final amount = double.tryParse(
                        _amountController.text.trim(),
                      );
                      if (amount == null ||
                          amount <= 0 ||
                          amount != amount.roundToDouble()) {
                        Get.rawSnackbar(
                          message: 'Enter a positive whole-rupee amount.',
                        );
                        return;
                      }
                      Navigator.of(sheetContext).pop();
                      _startRecharge(amount, keyId);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecharge(double amount, String keyId) async {
    Map<String, dynamic> remote;
    try {
      remote = await _wallet.createTopup(amount);
    } catch (e) {
      Get.rawSnackbar(message: e.toString());
      return;
    }
    setState(() => _recharging = true);
    _razorpay?.clear();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (
        PaymentSuccessResponse response,
      ) async {
        final credited = await _wallet.creditWallet(
          paymentId: response.paymentId ?? '',
          razorpayOrderId: response.orderId ?? '',
          signature: response.signature ?? '',
        );
        if (!mounted) return;
        setState(() => _recharging = false);
        if (credited) {
          Get.rawSnackbar(message: 'Amount added successfully.');
          _load();
        } else {
          Get.rawSnackbar(
            message: 'Payment succeeded but crediting the wallet failed — contact support.',
          );
        }
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        if (!mounted) return;
        setState(() => _recharging = false);
        final message = response.message;
        Get.rawSnackbar(
          message: (message == null || message.isEmpty)
              ? 'Payment was cancelled.'
              : 'Payment failed: $message',
        );
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    // The backend created this Razorpay order and fixed its amount server-side.
    // Open the SDK using that backend-owned order; confirmation also happens
    // server-side before the wallet is credited.
    _razorpay!.open({
      'key': keyId,
      'amount': remote['amount'],
      'order_id': remote['id'],
      'currency': remote['currency'],
      'name': 'POTLI',
      'description': 'Wallet top-up',
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn)
      return const Scaffold(
        appBar: LuxuryHeader(showBack: true),
        body: _SignInRequired(),
      );
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
                children: [
                  Text('MY\nWALLET', style: context.textTheme.editorialSmall),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: KColors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const MicroLabel(
                                'AVAILABLE BALANCE',
                                color: KColors.gray,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₹${_balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _showAddMoneySheet,
                          child: const Text('ADD MONEY'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  const MicroLabel('TRANSACTIONS'),
                  const SizedBox(height: 16),
                  if (_transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: MicroLabel(
                          'NO TRANSACTIONS YET',
                          color: KColors.gray,
                        ),
                      ),
                    )
                  else
                    for (final txn in _transactions) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn.message,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 3),
                                  MicroLabel(txn.date, color: KColors.gray),
                                ],
                              ),
                            ),
                            Text(
                              '${txn.type == 'credit' ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: txn.type == 'credit'
                                    ? Colors.green.shade700
                                    : KColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SectionDivider(),
                    ],
                ],
              ),
            ),
    );
  }
}

class CommunicationPreferencesView extends StatefulWidget {
  const CommunicationPreferencesView({super.key});

  @override
  State<CommunicationPreferencesView> createState() =>
      _CommunicationPreferencesViewState();
}

class _CommunicationPreferencesViewState
    extends State<CommunicationPreferencesView> {
  final _service = Get.find<SettingsService>();
  bool _loading = true;
  bool _saving = false;
  bool _email = true;
  bool _whatsapp = true;

  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isSignedIn.value) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    final prefs = await _service.getPromoPreferences();
    if (!mounted) return;
    setState(() {
      _email = prefs.email;
      _whatsapp = prefs.whatsapp;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _service.updatePromoPreferences(email: _email, whatsapp: _whatsapp);
    if (!mounted) return;
    setState(() => _saving = false);
    Get.snackbar(
      'Saved',
      'Your preferences have been updated.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: !Get.find<AuthController>().isSignedIn.value
          ? const _SignInRequired()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
              children: [
                Text(
                  'COMMUNICATION\nPREFERENCES',
                  style: context.textTheme.editorialSmall,
                ),
                const SizedBox(height: 10),
                const MicroLabel(
                  'CHOOSE HOW WE CAN REACH YOU WITH OFFERS AND UPDATES',
                  color: KColors.gray,
                ),
                const SizedBox(height: 30),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Promotional Emails'),
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                const SectionDivider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Promotional WhatsApp Messages'),
                  value: _whatsapp,
                  onChanged: (v) => setState(() => _whatsapp = v),
                ),
                const SizedBox(height: 30),
                FullWidthButton(
                  label: 'Save',
                  busy: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
    );
  }
}
