import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../models/address.dart';
import '../../models/shipping.dart';
import '../../services/api/address_service.dart';
import '../../services/api/cart_service.dart';
import '../../services/api/order_service.dart';
import '../../services/api/settings_service.dart';
import '../../services/api/wallet_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  String _idempotencyKey = 'mobile-${DateTime.now().microsecondsSinceEpoch}';
  int payment = 0;
  bool busy = false;
  String? error;

  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final pincode = TextEditingController();
  final country = TextEditingController(text: 'India');
  String _state = '';
  bool _pincodeLoading = false;
  String? _pincodeMessage;
  Timer? _pincodeDebounce;

  // Real delivery pricing — resolved once the address is saved, replacing
  // CartController.delivery's flat estimate for this screen.
  String? _savedAddressId;
  DeliveryChargeResult? _deliveryResult;
  String _shippingType = 'Standard';
  bool _checkingDelivery = false;
  String? _deliveryError;

  // Coupon code — validated against the running total (subtotal + delivery)
  // the same way the website's inline checkout validation does.
  final promoCode = TextEditingController();
  double _promoDiscount = 0;
  bool _promoApplying = false;
  String? _promoMessage;
  bool get _promoApplied => _promoDiscount > 0;

  // Wallet balance — optionally applied against the total, same as the
  // website's checkbox. Capped to whatever's left after the coupon discount.
  double _walletBalance = 0;
  bool _useWallet = false;

  // Potli Credit — a separate mechanism from both the coupon and the
  // wallet: a one-time code issued as store credit (e.g. for an approved
  // return), redeemed here the same way a promo code is, but capped to its
  // own available balance and applied to the total BEFORE wallet (matching
  // Order_model::place_order()'s server-side order: credit reduces the
  // payable amount first, then wallet covers whatever's left).
  final creditCode = TextEditingController();
  double _creditBalance = 0;
  bool _creditApplying = false;
  String? _creditMessage;
  bool get _creditApplied => _creditBalance > 0;

  // Saved-address picker — lets a returning customer pick an existing
  // address instead of retyping one every time, matching the website.
  List<Address> _savedAddresses = [];
  bool _addressesLoading = true;
  // null = "enter a new address" mode; otherwise the id of the picked one.
  String? _selectedExistingId;

  // Razorpay — key fetched live from admin settings rather than hardcoded,
  // and the option only appears once we know it's actually enabled.
  String? _razorpayKeyId;
  Razorpay? _razorpay;
  // Set only while an online-payment order is pending (placed but not yet
  // paid) so the Razorpay callbacks know which order to confirm or cancel.
  String? _pendingOnlineOrderId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    Get.find<SettingsService>().getRazorpayKeyId().then((key) {
      if (!mounted) return;
      setState(() {
        _razorpayKeyId = key;
        // Online payment defaults to selected, but if it turns out not to
        // be configured, fall back to COD rather than leaving an option
        // selected that can't actually be used.
        if (key == null) payment = 1;
      });
    });
    if (Get.find<StorageService>().authToken.isNotEmpty) {
      Get.find<WalletService>().getBalance().then((balance) {
        if (mounted) setState(() => _walletBalance = balance);
      });
    }
  }

  Future<void> _loadAddresses() async {
    if (Get.find<StorageService>().authToken.isEmpty) {
      if (mounted) setState(() => _addressesLoading = false);
      return;
    }
    final addresses = await Get.find<AddressService>().getAddresses();
    if (!mounted) return;
    setState(() {
      _savedAddresses = addresses;
      _addressesLoading = false;
    });
    if (addresses.isNotEmpty) {
      final defaultAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      _selectExisting(defaultAddress);
    }
  }

  void _selectExisting(Address selected) {
    setState(() {
      _selectedExistingId = selected.id;
      _savedAddressId = selected.id;
      _deliveryResult = null;
      _deliveryError = null;
      name.text = selected.name;
      phone.text = selected.mobile;
      address.text = selected.address;
      city.text = selected.city;
      pincode.text = selected.pincode;
    });
    _checkDelivery();
  }

  void _useNewAddress() {
    setState(() {
      _selectedExistingId = null;
      _savedAddressId = null;
      _deliveryResult = null;
      _deliveryError = null;
      name.clear();
      phone.clear();
      address.clear();
      city.clear();
      pincode.clear();
      country.text = 'India';
      _state = '';
      _pincodeMessage = null;
    });
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    city.dispose();
    pincode.dispose();
    country.dispose();
    promoCode.dispose();
    creditCode.dispose();
    _pincodeDebounce?.cancel();
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _applyPromoCode() async {
    final code = promoCode.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _promoApplying = true;
      _promoMessage = null;
    });
    final result = await Get.find<CartService>().validatePromoCode(
      promoCode: code,
    );
    if (!mounted) return;
    setState(() {
      _promoApplying = false;
      if (result != null && result.success && result.discount > 0) {
        _promoDiscount = result.discount;
        _promoMessage = result.message;
      } else {
        _promoDiscount = 0;
        _promoMessage = result?.message ?? 'Could not validate this code.';
      }
    });
  }

  void _removePromoCode() {
    setState(() {
      _promoDiscount = 0;
      _promoMessage = null;
      promoCode.clear();
    });
  }

  Future<void> _applyCreditCode() async {
    final code = creditCode.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _creditApplying = true;
      _creditMessage = null;
    });
    final result = await Get.find<CartService>().validateCreditCode(code);
    if (!mounted) return;
    setState(() {
      _creditApplying = false;
      if (result != null && result.success && result.availableBalance > 0) {
        _creditBalance = result.availableBalance;
        _creditMessage = result.message;
      } else {
        _creditBalance = 0;
        _creditMessage = result?.message ?? 'Could not validate this code.';
      }
    });
  }

  void _removeCreditCode() {
    setState(() {
      _creditBalance = 0;
      _creditMessage = null;
      creditCode.clear();
    });
  }

  void _invalidateDeliveryCheck() {
    if (_savedAddressId == null && _deliveryResult == null) return;
    setState(() {
      _savedAddressId = null;
      _deliveryResult = null;
      _shippingType = 'Standard';
    });
  }

  void _onPincodeChanged(String value) {
    _invalidateDeliveryCheck();
    _pincodeDebounce?.cancel();
    final pin = value.replaceAll(RegExp(r'\D'), '');
    if (pin.length != 6) {
      setState(() => _pincodeMessage = null);
      return;
    }
    _pincodeDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _lookupPincode(pin),
    );
  }

  /// Same free India Post API the website's checkout uses to auto-fill
  /// city + state + country from a 6-digit pincode.
  Future<void> _lookupPincode(String pin) async {
    setState(() {
      _pincodeLoading = true;
      _pincodeMessage = 'Looking up pincode…';
    });
    try {
      final response = await http
          .get(Uri.parse('https://api.postalpincode.in/pincode/$pin'))
          .timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(response.body);
      final record = decoded is List && decoded.isNotEmpty
          ? decoded.first
          : null;
      final postOffices = record is Map ? record['PostOffice'] : null;
      if (record is Map &&
          record['Status'] == 'Success' &&
          postOffices is List &&
          postOffices.isNotEmpty) {
        final po = postOffices.first as Map;
        setState(() {
          city.text = '${po['District'] ?? po['Block'] ?? po['Name'] ?? ''}';
          _state = '${po['State'] ?? ''}';
          country.text = '${po['Country'] ?? 'India'}';
          _pincodeMessage = null;
        });
      } else {
        setState(
          () => _pincodeMessage = 'Please enter a correct Indian pincode.',
        );
      }
    } catch (_) {
      setState(
        () => _pincodeMessage =
            'Could not look up pincode — check your connection.',
      );
    } finally {
      if (mounted) setState(() => _pincodeLoading = false);
    }
  }

  // payment == 1 is COD (see the payment method selector below) — Shiprocket
  // charges a different (usually higher) rate for COD than prepaid per
  // courier, so the two are genuinely different amounts, not just a display
  // choice. This used to always resolve to the non-COD rate regardless of
  // which payment method was selected, and that same (too-low) number was
  // what got sent to place_order() as delivery_charge — unlike the website,
  // app/v1/Api.php::place_order() doesn't independently re-derive/override
  // it server-side, so COD orders were actually being undercharged shipping
  // by the full COD surcharge, not just showing a stale number.
  int get _resolvedDelivery {
    final result = _deliveryResult;
    if (result == null) return Get.find<CartController>().delivery;
    final option = _shippingType == 'Express'
        ? result.express
        : result.standard;
    final charge = payment == 1
        ? (option?.deliveryChargeWithCod ?? result.deliveryChargeWithCod)
        : (option?.deliveryChargeWithoutCod ?? result.deliveryChargeWithoutCod);
    return charge.round();
  }

  /// Amount of the (already promo-discounted) total covered by an applied
  /// Potli Credit code — never more than what's owed or what's on the
  /// code. Applied before wallet, same order the server settles it in.
  int _creditAmountFor(int totalAfterPromo) {
    if (!_creditApplied) return 0;
    return _creditBalance.floor().clamp(0, totalAfterPromo);
  }

  /// Amount of the remaining total (after promo AND credit) actually
  /// covered by wallet balance — never more than what's owed or available.
  int _walletAmountFor(int totalAfterDiscount) {
    if (!_useWallet || _walletBalance <= 0) return 0;
    return _walletBalance.floor().clamp(0, totalAfterDiscount);
  }

  Future<void> _checkDelivery() async {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        city.text.trim().isEmpty ||
        pincode.text.trim().length != 6) {
      setState(
        () => _deliveryError =
            'Please fill in your address and a 6-digit pincode first.',
      );
      return;
    }

    setState(() {
      _checkingDelivery = true;
      _deliveryError = null;
    });

    try {
      final addressService = Get.find<AddressService>();
      final cartService = Get.find<CartService>();
      final cart = Get.find<CartController>();

      final addressId =
          _savedAddressId ??
          await addressService.addAddress(
            name: name.text.trim(),
            mobile: phone.text.trim(),
            address: address.text.trim(),
            cityName: city.text.trim(),
            pincode: pincode.text.trim(),
            state: _state,
            country: country.text.trim(),
          );

      if (addressId == null) {
        setState(() => _deliveryError = 'Could not save delivery address');
        return;
      }

      final result = await cartService.getDeliveryCharge(addressId: addressId);

      if (!mounted) return;
      setState(() {
        _savedAddressId = addressId;
        _deliveryResult = result;
        _shippingType = 'Standard';
        if (result == null) {
          _deliveryError = 'Unable to calculate delivery for this address — using standard rate.';
        }
      });
    } finally {
      if (mounted) setState(() => _checkingDelivery = false);
    }
  }

  Future<void> _placeOrder() async {
    final cart = Get.find<CartController>();

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final addressService = Get.find<AddressService>();
      final orderService = Get.find<OrderService>();

      final addressId =
          _savedAddressId ??
          await addressService.addAddress(
            name: name.text.trim(),
            mobile: phone.text.trim(),
            address: address.text.trim(),
            cityName: city.text.trim(),
            pincode: pincode.text.trim(),
            state: _state,
            country: country.text.trim(),
          );

      if (addressId == null) {
        setState(() => error = 'Could not save delivery address');
        return;
      }

      final variantIds = <String>[];
      final quantities = <int>[];
      final personalizationMap = <String, String>{};
      for (final line in cart.lines) {
        final variantId = line.product.variantId;
        if (variantId == null) continue;
        variantIds.add(variantId);
        quantities.add(line.quantity);
        if (line.personalizationText != null &&
            line.personalizationText!.isNotEmpty) {
          personalizationMap[variantId] = line.personalizationText!;
        }
      }

      if (variantIds.isEmpty) {
        setState(() => error = 'Cart items are missing pricing data');
        return;
      }

      final deliveryCharge = _resolvedDelivery;
      final totalAmount = (cart.subtotal + deliveryCharge - _promoDiscount)
          .round();
      final creditAmountUsed = _creditAmountFor(totalAmount);
      final walletAmountUsed = _walletAmountFor(totalAmount - creditAmountUsed);
      final payableAmount = totalAmount - creditAmountUsed - walletAmountUsed;
      final isOnlinePayment = payment == 0;
      final result = await orderService.placeOrder(
        idempotencyKey: _idempotencyKey,
        variantIds: variantIds,
        quantities: quantities,
        addressId: addressId,
        paymentMethod: isOnlinePayment ? 'razorpay' : 'COD',
        shippingType: _shippingType,
        promoCode: _promoApplied ? promoCode.text.trim() : null,
        creditCode: _creditApplied ? creditCode.text.trim() : null,
        walletAmountUsed: walletAmountUsed,
        personalizationText: personalizationMap.isEmpty
            ? null
            : jsonEncode(personalizationMap),
      );

      if (!result.success || result.orderId == null) {
        setState(
          () => error = result.message.isNotEmpty
              ? result.message
              : 'Order could not be placed',
        );
        return;
      }

      if (!isOnlinePayment) {
        // COD — order was placed as 'received' already, nothing else to do.
        if (!mounted) return;
        Get.offNamed(Routes.success);
        return;
      }
      if ((result.payable ?? payableAmount) <= 0) {
        // The backend marks a zero-payable online order as paid/received
        // during place_order, so there is no payment verification step.
        if (!mounted) return;
        Get.offNamed(Routes.success);
        return;
      }

      // Online payment: the order above was placed as pending — now collect
      // whatever's left after wallet via the Razorpay checkout. Navigation
      // to success happens from the payment-success callback, not here.
      await _startRazorpayCheckout(orderId: result.orderId!);
    } catch (e, st) {
      // TEMP DEBUG — remove once the "place order does nothing" issue is found.
      debugPrint('_placeOrder FAILED: $e\n$st');
      if (mounted)
        setState(() => error = 'Something went wrong placing your order: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Opens the Razorpay checkout for an order that's already been placed
  /// (as pending). The order id is created server-side against Razorpay's
  /// Orders API first so the amount can't be tampered with client-side —
  /// same secure pattern the website and previous app both use.
  Future<void> _startRazorpayCheckout({required String orderId}) async {
    final keyId = _razorpayKeyId;
    if (keyId == null) {
      setState(
        () => error = 'Online payment is not available right now — please choose Cash on Delivery.',
      );
      return;
    }

    final orderService = Get.find<OrderService>();
    final razorpayOrder = await orderService.createRazorpayOrder(orderId);
    if (razorpayOrder == null) {
      setState(
        () => error = 'Could not start online payment — please try again.',
      );
      return;
    }

    _pendingOnlineOrderId = orderId;

    _razorpay?.clear();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    _razorpay!.open({
      'key': keyId,
      'amount': razorpayOrder.amount,
      'currency': razorpayOrder.currency,
      'order_id': razorpayOrder.razorpayOrderId,
      'name': 'POTLI',
      'description': 'Order #$orderId',
      'prefill': {'contact': phone.text.trim()},
    });
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final orderId = _pendingOnlineOrderId;
    _pendingOnlineOrderId = null;
    if (orderId == null) return;

    final confirmed = await Get.find<OrderService>().confirmOnlinePayment(
      paymentId: response.paymentId ?? '',
      razorpayOrderId: response.orderId ?? '',
      signature: response.signature ?? '',
    );
    if (!mounted) return;
    if (confirmed) {
      Get.offNamed(Routes.success);
    } else {
      setState(() {
        busy = false;
        error =
            'Payment succeeded but confirming the order failed — please contact support '
            'with payment id ${response.paymentId}.';
      });
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    _idempotencyKey = 'mobile-${DateTime.now().microsecondsSinceEpoch}';
    final orderId = _pendingOnlineOrderId;
    _pendingOnlineOrderId = null;
    if (orderId != null) {
      Get.find<OrderService>().cancelPendingOrder(orderId);
    }
    if (!mounted) return;
    final message = response.message;
    setState(() {
      busy = false;
      error = (message == null || message.isEmpty)
          ? 'Payment was cancelled.'
          : 'Payment failed: $message';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final totalAfterPromo = (cart.subtotal + _resolvedDelivery - _promoDiscount)
        .round();
    final creditApplied = _creditAmountFor(totalAfterPromo);
    final walletApplied = _useWallet
        ? _walletAmountFor(totalAfterPromo - creditApplied)
        : 0;
    final finalTotal = totalAfterPromo - creditApplied - walletApplied;
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 38, 20, 130),
        children: [
          const MicroLabel('SECURE CHECKOUT', color: KColors.gray),
          const SizedBox(height: 14),
          Text('THE FINAL\nDETAILS', style: context.textTheme.editorialSmall),
          const SizedBox(height: 46),
          const MicroLabel('DELIVERY ADDRESS'),
          const SizedBox(height: 15),
          if (_addressesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_savedAddresses.isNotEmpty) ...[
              for (final saved in _savedAddresses)
                _AddressChoiceTile(
                  address: saved,
                  selected: _selectedExistingId == saved.id,
                  onTap: () => _selectExisting(saved),
                ),
              _AddNewAddressTile(
                selected: _selectedExistingId == null,
                onTap: _useNewAddress,
              ),
              const SizedBox(height: 14),
            ],
            if (_selectedExistingId == null) ...[
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'FULL NAME'),
                onChanged: (_) => _invalidateDeliveryCheck(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'PHONE'),
                onChanged: (_) => _invalidateDeliveryCheck(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'ADDRESS'),
                onChanged: (_) => _invalidateDeliveryCheck(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pincode,
                keyboardType: TextInputType.number,
                onChanged: _onPincodeChanged,
                decoration: InputDecoration(
                  labelText: 'PIN CODE',
                  suffixIcon: _pincodeLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_pincodeMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  _pincodeMessage!,
                  style: TextStyle(
                    fontSize: 11,
                    color: _pincodeLoading ? KColors.gray : Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: city,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'CITY',
                        hintText: 'Auto-filled from pincode',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: country,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'COUNTRY'),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 14),
          if (_deliveryResult == null)
            OutlinedButton(
              onPressed: _checkingDelivery ? null : _checkDelivery,
              child: Text(
                _checkingDelivery ? 'CHECKING…' : 'CHECK DELIVERY OPTIONS',
              ),
            )
          else
            _ShippingOptionPicker(
              result: _deliveryResult!,
              selected: _shippingType,
              onChanged: (value) => setState(() => _shippingType = value),
            ),
          if (_deliveryError != null) ...[
            const SizedBox(height: 8),
            Text(
              _deliveryError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 48),
          const MicroLabel('PAYMENT'),
          const SizedBox(height: 14),
          if (_razorpayKeyId != null)
            _PaymentOption(
              label: 'ONLINE (CARDS / UPI / NETBANKING)',
              selected: payment == 0,
              onTap: () => setState(() => payment = 0),
            ),
          // Matches the matching (authoritative) check in Order_model::
          // place_order() on the server — this is just the UI-side
          // reflection of it, based on the same subtotal the summary below
          // already shows.
          _PaymentOption(
            label: 'CASH ON DELIVERY',
            selected: payment == 1,
            enabled: cart.subtotal <= 15000,
            disabledNote: 'Not available for orders above ₹15,000',
            onTap: () => setState(() => payment = 1),
          ),
          const SizedBox(height: 44),
          const MicroLabel('PROMO CODE'),
          const SizedBox(height: 14),
          if (_promoApplied)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '"${promoCode.text.trim().toUpperCase()}" applied',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _removePromoCode,
                  child: const MicroLabel('REMOVE'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoCode,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'ENTER COUPON CODE',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _promoApplying ? null : _applyPromoCode,
                  child: Text(_promoApplying ? '...' : 'APPLY'),
                ),
              ],
            ),
          if (_promoMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _promoMessage!,
              style: TextStyle(
                fontSize: 11,
                color: _promoApplied ? Colors.green : Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 44),
          const MicroLabel('POTLI CREDIT'),
          const SizedBox(height: 14),
          if (_creditApplied)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '"${creditCode.text.trim().toUpperCase()}" applied (₹${_creditBalance.toStringAsFixed(2)} available)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _removeCreditCode,
                  child: const MicroLabel('REMOVE'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: creditCode,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'HAVE A POTLI CREDIT CODE?',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _creditApplying ? null : _applyCreditCode,
                  child: Text(_creditApplying ? '...' : 'APPLY'),
                ),
              ],
            ),
          if (_creditMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _creditMessage!,
              style: TextStyle(
                fontSize: 11,
                color: _creditApplied ? Colors.green : Colors.red,
              ),
            ),
          ],
          if (_walletBalance > 0) ...[
            const SizedBox(height: 44),
            const MicroLabel('WALLET'),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => setState(() => _useWallet = !_useWallet),
              child: Row(
                children: [
                  Checkbox(
                    value: _useWallet,
                    onChanged: (v) => setState(() => _useWallet = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Use wallet balance (₹${_walletBalance.toStringAsFixed(2)} available)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 44),
          const MicroLabel('ORDER SUMMARY'),
          const SizedBox(height: 20),
          _CheckoutRow(label: 'PIECES', value: '${cart.count}'),
          const SizedBox(height: 12),
          _CheckoutRow(label: 'SUBTOTAL', value: '₹${cart.subtotal}'),
          const SizedBox(height: 12),
          _CheckoutRow(
            label: 'DELIVERY',
            value: _resolvedDelivery == 0
                ? 'COMPLIMENTARY'
                : '₹$_resolvedDelivery',
          ),
          const SizedBox(height: 12),
          // Every product page already states prices are "INCLUSIVE OF ALL
          // TAXES" (shop_views.dart) — same as the website's checkout row
          // for the common case, shown here so it isn't just implicit.
          const _CheckoutRow(label: 'TAX', value: 'Included'),
          if (_promoApplied) ...[
            const SizedBox(height: 12),
            _CheckoutRow(
              label: 'DISCOUNT',
              value: '-₹${_promoDiscount.round()}',
            ),
          ],
          if (creditApplied > 0) ...[
            const SizedBox(height: 12),
            _CheckoutRow(label: 'POTLI CREDIT', value: '-₹$creditApplied'),
          ],
          if (walletApplied > 0) ...[
            const SizedBox(height: 12),
            _CheckoutRow(label: 'WALLET APPLIED', value: '-₹$walletApplied'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: SectionDivider(),
          ),
          _CheckoutRow(label: 'TOTAL', value: '₹$finalTotal', strong: true),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: KColors.white,
          padding: const EdgeInsets.all(12),
          child: FullWidthButton(
            label: 'PLACE ORDER  •  ₹$finalTotal',
            busy: busy,
            onPressed: busy ? null : _placeOrder,
          ),
        ),
      ),
    );
  }
}

class _AddressChoiceTile extends StatelessWidget {
  const _AddressChoiceTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: KColors.black),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? KColors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (address.isDefault)
                      const MicroLabel('DEFAULT', color: KColors.gray),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${address.address}, ${address.city} - ${address.pincode}',
                  style: const TextStyle(fontSize: 12, color: KColors.gray),
                ),
                const SizedBox(height: 3),
                Text(
                  address.mobile,
                  style: const TextStyle(fontSize: 12, color: KColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AddNewAddressTile extends StatelessWidget {
  const _AddNewAddressTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: KColors.black),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? KColors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const MicroLabel('+ USE A NEW ADDRESS'),
        ],
      ),
    ),
  );
}

class _ShippingOptionPicker extends StatelessWidget {
  const _ShippingOptionPicker({
    required this.result,
    required this.selected,
    required this.onChanged,
  });

  final DeliveryChargeResult result;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (result.standard == null) {
      // No Shiprocket quote at all for this address (flat-rate/local cart) —
      // there was never a method choice to show.
      return _CheckoutRow(
        label: 'DELIVERY',
        value: result.deliveryChargeWithoutCod == 0
            ? 'COMPLIMENTARY'
            : '₹${result.deliveryChargeWithoutCod.round()}',
      );
    }
    if (!result.hasExpressOption) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShippingOptionTile(
            label: 'STANDARD SHIPPING',
            price: result.standard!.deliveryChargeWithoutCod,
            eta: result.standard!.etaLabel,
            selected: true,
            onTap: () => onChanged('Standard'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: MicroLabel(
              "EXPRESS SHIPPING ISN'T AVAILABLE FOR THIS ADDRESS",
              color: KColors.gray,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShippingOptionTile(
          label: 'STANDARD SHIPPING',
          price: result.standard?.deliveryChargeWithoutCod ?? 0,
          eta: result.standard?.etaLabel ?? '',
          selected: selected == 'Standard',
          onTap: () => onChanged('Standard'),
        ),
        _ShippingOptionTile(
          label: 'EXPRESS SHIPPING',
          price: result.express!.deliveryChargeWithoutCod,
          eta: result.express!.etaLabel,
          selected: selected == 'Express',
          onTap: () => onChanged('Express'),
        ),
      ],
    );
  }
}

class _ShippingOptionTile extends StatelessWidget {
  const _ShippingOptionTile({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.eta = '',
  });

  final String label;
  final double price;
  final bool selected;
  final VoidCallback onTap;
  final String eta;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: KColors.black),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? KColors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MicroLabel(label),
                if (eta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      eta,
                      style: const TextStyle(fontSize: 11, color: KColors.gray),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            price == 0 ? 'FREE' : '₹${price.round()}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.disabledNote,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledNote;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    child: Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: KColors.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KColors.black),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected && enabled
                      ? KColors.black
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MicroLabel(label),
                  if (!enabled && disabledNote != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      disabledNote!,
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MicroLabel(label, color: strong ? KColors.black : KColors.gray),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: strong ? 16 : 11)),
    ],
  );
}

class OrderSuccessView extends StatefulWidget {
  const OrderSuccessView({super.key});

  @override
  State<OrderSuccessView> createState() => _OrderSuccessViewState();
}

class _OrderSuccessViewState extends State<OrderSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    // Deferred to after this build completes: clear() mutates an .obs map,
    // which synchronously notifies every Obx watching it (e.g. the bag
    // count badge in the bottom nav) — calling that from initState() (still
    // inside the current build phase) tries to rebuild those widgets while
    // the framework is mid-build, which throws "setState() or
    // markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CartController>().clearLocal();
    });
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KColors.black,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandWordmark(color: KColors.white, fontSize: 15),
              const Spacer(),
              const MicroLabel('ORDER CONFIRMED', color: KColors.white),
              const SizedBox(height: 18),
              Text(
                'YOURS,\nUNAPOLOGETICALLY.',
                style: context.textTheme.editorialSmall.copyWith(
                  color: KColors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Your POTLI piece is being prepared.',
                style: TextStyle(
                  color: KColors.white.withValues(alpha: .72),
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
              const Spacer(),
              FullWidthButton(
                label: 'CONTINUE DISCOVERING',
                inverse: true,
                onPressed: () => Get.offAllNamed(Routes.shell),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
