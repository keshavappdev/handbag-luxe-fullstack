class TicketType {
  const TicketType({required this.id, required this.title});

  final String id;
  final String title;

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
    );
  }
}

// Status codes as used server-side (Ticket_model / app/v1/Api::edit_ticket):
// 1 pending, 2 opened, 3 resolved, 4 closed, 5 reopened.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.ticketTypeId,
    required this.ticketType,
    required this.subject,
    required this.email,
    required this.description,
    required this.status,
    required this.dateCreated,
  });

  final String id;
  final String ticketTypeId;
  final String ticketType;
  final String subject;
  final String email;
  final String description;
  final String status;
  final String dateCreated;

  bool get isClosed => status == '4';

  String get statusLabel => switch (status) {
    '1' => 'PENDING',
    '2' => 'OPENED',
    '3' => 'RESOLVED',
    '4' => 'CLOSED',
    '5' => 'REOPENED',
    _ => status,
  };

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: '${json['id'] ?? ''}',
      ticketTypeId: '${json['ticket_type_id'] ?? ''}',
      ticketType: '${json['ticket_type'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      email: '${json['email'] ?? ''}',
      description: '${json['description'] ?? ''}',
      status: '${json['status'] ?? ''}',
      dateCreated: '${json['date_created'] ?? ''}',
    );
  }
}

/// One file attached to a ticket message — type is one of the buckets
/// Ticket_model::get_messages() classifies uploads into server-side:
/// image/video/document/archive (by extension), not a MIME type.
class TicketAttachment {
  const TicketAttachment({required this.url, required this.type});

  final String url;
  final String type;

  bool get isImage => type == 'image';

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      url: '${json['media'] ?? ''}',
      type: '${json['type'] ?? ''}',
    );
  }
}

class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.userType,
    required this.userId,
    required this.message,
    required this.name,
    required this.dateCreated,
    this.attachments = const [],
  });

  final String id;
  // 'user' for the customer's own messages, otherwise a support agent's.
  final String userType;
  final String userId;
  final String message;
  final String name;
  final String dateCreated;
  final List<TicketAttachment> attachments;

  bool get isMine => userType == 'user';

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'];
    return TicketMessage(
      id: '${json['id'] ?? ''}',
      userType: '${json['user_type'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      message: '${json['message'] ?? ''}',
      name: '${json['name'] ?? ''}',
      dateCreated: '${json['date_created'] ?? ''}',
      attachments: attachmentsJson is List
          ? attachmentsJson
                .whereType<Map>()
                .map(
                  (e) =>
                      TicketAttachment.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
