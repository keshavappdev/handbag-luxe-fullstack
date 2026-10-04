import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/order_summary.dart';
import '../../models/return_exchange.dart';
import '../../services/api/return_exchange_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';

const List<String> kReturnExchangeReasons = [
  'Wrong item received',
  'Item damaged / defective',
  'Size / fit issue',
  'Not as described',
  'Changed my mind',
  'other',
];

String _reasonLabel(String reason) => reason == 'other' ? 'Other' : reason;

/// Opens the Return Request sheet for [item]; calls [onDone] once a request
/// is submitted successfully so the caller can refresh its order list.
Future<void> showReturnRequestSheet(
  BuildContext context,
  OrderItemSummary item, {
  required String orderId,
  required VoidCallback onDone,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: KColors.white,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _RequestSheet(
      title: 'Return Item',
      item: item,
      orderId: orderId,
      isExchange: false,
      onDone: onDone,
    ),
  );
}

/// Opens the Exchange Request sheet for [item]; calls [onDone] once a
/// request is submitted successfully so the caller can refresh its order list.
Future<void> showExchangeRequestSheet(
  BuildContext context,
  OrderItemSummary item, {
  required String orderId,
  required VoidCallback onDone,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: KColors.white,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _RequestSheet(
      title: 'Exchange Item',
      item: item,
      orderId: orderId,
      isExchange: true,
      onDone: onDone,
    ),
  );
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({
    required this.title,
    required this.item,
    required this.orderId,
    required this.isExchange,
    required this.onDone,
  });

  final String title;
  final OrderItemSummary item;
  final String orderId;
  final bool isExchange;
  final VoidCallback onDone;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _service = Get.find<ReturnExchangeService>();
  final _notesController = TextEditingController();
  final _otherController = TextEditingController();

  String? _selectedReason;
  bool _busy = false;
  String? _error;

  // Exchange-only.
  Future<List<ExchangeVariantOption>>? _variantsFuture;
  String? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    if (widget.isExchange) {
      _variantsFuture = _service.getExchangeVariants(widget.item.id);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      setState(() => _error = 'Please select a reason.');
      return;
    }
    if (_selectedReason == 'other' && _otherController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe your reason.');
      return;
    }
    if (widget.isExchange &&
        (_selectedVariantId == null || _selectedVariantId!.isEmpty)) {
      setState(() => _error = 'Please select a size/variant to exchange for.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = widget.isExchange
        ? await _service.submitExchangeRequest(
            orderItemId: widget.item.id,
            exchangeForVariantId: _selectedVariantId!,
            reason: _selectedReason!,
            otherReason: _otherController.text.trim(),
            customerNotes: _notesController.text.trim(),
          )
        : await _service.submitReturnRequest(
            orderItemId: widget.item.id,
            reason: _selectedReason!,
            otherReason: _otherController.text.trim(),
            customerNotes: _notesController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _busy = false);

    if (result.success) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      widget.onDone();
    } else {
      setState(
        () => _error = result.message.isEmpty
            ? 'Something went wrong.'
            : result.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: context.textTheme.editorialSmall),
                const SizedBox(height: 8),
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                MicroLabel('Order #${widget.orderId}', color: KColors.gray),
                const SizedBox(height: 20),

                if (widget.isExchange) ...[
                  const Text(
                    'Exchange for',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<ExchangeVariantOption>>(
                    future: _variantsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(minHeight: 1),
                        );
                      }
                      final options = snapshot.data ?? const [];
                      if (options.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: MicroLabel(
                            'NO OTHER SIZES/VARIANTS AVAILABLE',
                            color: KColors.gray,
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedVariantId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: options
                            .map(
                              (o) => DropdownMenuItem(
                                value: o.id,
                                enabled: !o.isOutOfStock,
                                child: Text(
                                  '${o.label} — ₹${o.price.toStringAsFixed(2)}${o.isOutOfStock ? ' (Out of stock)' : ''}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedVariantId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                const Text(
                  'Reason',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                for (final reason in kReturnExchangeReasons)
                  RadioListTile<String>(
                    value: reason,
                    // ignore: deprecated_member_use
                    groupValue: _selectedReason,
                    // ignore: deprecated_member_use
                    onChanged: (v) => setState(() => _selectedReason = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_reasonLabel(reason)),
                  ),
                if (_selectedReason == 'other') ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: _otherController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Text(
                  'Additional details (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Tell us more…',
                    border: OutlineInputBorder(),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 20),
                FullWidthButton(
                  label: widget.isExchange
                      ? 'Confirm Exchange'
                      : 'Confirm Return',
                  busy: _busy,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
