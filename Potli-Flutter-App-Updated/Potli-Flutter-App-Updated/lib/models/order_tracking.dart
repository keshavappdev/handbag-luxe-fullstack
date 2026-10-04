class TrackingEvent {
  const TrackingEvent({
    required this.status,
    required this.date,
    this.location = '',
  });

  final String status;
  final String date;
  final String location;

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      status: '${json['status'] ?? ''}',
      date: '${json['date'] ?? ''}',
      location: '${json['location'] ?? ''}',
    );
  }
}

/// Result of get_order_tracking — real-time Shiprocket status when the
/// order has a shipment on file, otherwise the order's own status history
/// (courier-agnostic, always available) as a fallback.
class OrderTracking {
  const OrderTracking({
    required this.isLive,
    required this.currentStatus,
    required this.courierAgency,
    required this.trackingId,
    required this.trackingUrl,
    required this.shippingType,
    required this.timeline,
  });

  // true when this came from a live Shiprocket call, false for the
  // order's own standard status-history fallback.
  final bool isLive;
  final String currentStatus;
  final String courierAgency;
  final String trackingId;
  final String trackingUrl;
  final String shippingType;
  final List<TrackingEvent> timeline;

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    final timelineJson = json['timeline'];
    return OrderTracking(
      isLive: json['source'] == 'shiprocket',
      currentStatus: '${json['current_status'] ?? ''}',
      courierAgency: '${json['courier_agency'] ?? ''}',
      trackingId: '${json['tracking_id'] ?? ''}',
      trackingUrl: '${json['tracking_url'] ?? ''}',
      shippingType: '${json['shipping_type'] ?? 'Standard'}',
      timeline: timelineJson is List
          ? timelineJson
                .whereType<Map>()
                .map(
                  (e) => TrackingEvent.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
