import 'dart:io';

import '../../models/support_ticket.dart';
import 'api_base_helper.dart';
import 'api_constants.dart';

class SupportService {
  SupportService(this._api);

  final ApiBaseHelper _api;

  Future<List<TicketType>> getTicketTypes() async {
    final response = await _api.post(getTicketTypesApi, const {});
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => TicketType.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SupportTicket>> getTickets({
    int limit = 25,
    int offset = 0,
  }) async {
    final response = await _api.post(getTicketsApi, {
      'limit': '$limit',
      'offset': '$offset',
    });
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Creates a new support ticket. Returns the created ticket, or null on
  /// failure (caller shows [message] from the raw response if needed).
  Future<SupportTicket?> addTicket({
    required String ticketTypeId,
    required String subject,
    required String email,
    required String description,
  }) async {
    final response = await _api.post(addTicketApi, {
      'ticket_type_id': ticketTypeId,
      'subject': subject,
      'email': email,
      'description': description,
    });
    if (response is! Map || response['error'] == true) return null;
    final data = response['data'];
    final row = data is List && data.isNotEmpty ? data.first : null;
    return row is Map
        ? SupportTicket.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  /// status: '3' resolved, '5' reopened — matches edit_ticket's contract.
  Future<bool> setTicketStatus(SupportTicket ticket, String status) async {
    final response = await _api.post(editTicketApi, {
      'ticket_id': ticket.id,
      'status': status,
    });
    return response is Map && response['error'] != true;
  }

  Future<List<TicketMessage>> getMessages(String ticketId) async {
    final response = await _api.post(getTicketMessagesApi, {
      'ticket_id': ticketId,
    });
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => TicketMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Sends a message on a ticket, optionally with image attachments.
  /// Returns the sent message (including its attachment URLs, so the UI
  /// can show it immediately) or null on failure.
  Future<TicketMessage?> sendMessage({
    required String ticketId,
    required String message,
    List<File> attachments = const [],
  }) async {
    final fields = {
      'ticket_id': ticketId,
      'message': message,
    };
    final response = attachments.isEmpty
        ? await _api.post(sendMsgApi, fields)
        : await _api.postMultipart(sendMsgApi, fields, [
            for (final file in attachments) MapEntry('attachments[]', file),
          ]);
    if (response is! Map || response['error'] == true) return null;
    final data = response['data'];
    return data is Map
        ? TicketMessage.fromJson(Map<String, dynamic>.from(data))
        : null;
  }
}
