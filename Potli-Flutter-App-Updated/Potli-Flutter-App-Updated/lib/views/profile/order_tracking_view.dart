import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/order_tracking.dart';
import '../../services/api/order_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';

/// Real-time delivery status for an order — shows live Shiprocket tracking
/// when available, or the order's own status history for standard
/// delivery. Reached from the "TRACK PACKAGE" button on Order Detail.
class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  OrderTracking? _tracking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tracking = await Get.find<OrderService>().getOrderTracking(
      widget.orderId,
    );
    if (!mounted) return;
    setState(() {
      _tracking = tracking;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _tracking;
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: RefreshIndicator(
        onRefresh: () {
          setState(() => _loading = true);
          return _load();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
          children: [
            Text('TRACK\nPACKAGE', style: context.textTheme.editorialSmall),
            const SizedBox(height: 30),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (tracking == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: MicroLabel(
                    'TRACKING IS NOT AVAILABLE FOR THIS ORDER YET',
                    color: KColors.gray,
                  ),
                ),
              )
            else ...[
              MicroLabel(
                tracking.isLive
                    ? 'LIVE FROM ${tracking.courierAgency.isNotEmpty ? tracking.courierAgency.toUpperCase() : 'COURIER'}'
                    : 'STANDARD DELIVERY',
                color: KColors.gray,
              ),
              const SizedBox(height: 10),
              Text(
                tracking.currentStatus.isNotEmpty
                    ? tracking.currentStatus
                    : 'Processing',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (tracking.trackingId.isNotEmpty) ...[
                const SizedBox(height: 8),
                MicroLabel(
                  'TRACKING ID: ${tracking.trackingId}',
                  color: KColors.gray,
                ),
              ],
              const SizedBox(height: 34),
              const SectionDivider(),
              const SizedBox(height: 24),
              const MicroLabel('STATUS TIMELINE'),
              const SizedBox(height: 18),
              if (tracking.timeline.isEmpty)
                const MicroLabel('NO UPDATES YET', color: KColors.gray)
              else
                for (var i = 0; i < tracking.timeline.length; i++)
                  _TimelineRow(
                    event: tracking.timeline[tracking.timeline.length - 1 - i],
                    isLatest: i == 0,
                    isLast: i == tracking.timeline.length - 1,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isLatest,
    required this.isLast,
  });
  final TrackingEvent event;
  final bool isLatest;
  final bool isLast;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLatest ? KColors.black : KColors.gray,
              ),
            ),
            if (!isLast)
              const Expanded(
                child: VerticalDivider(color: KColors.line, thickness: 1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isLatest ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  MicroLabel(event.location, color: KColors.gray),
                ],
                if (event.date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  MicroLabel(event.date, color: KColors.gray),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
