import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../controllers/app_controllers.dart';
import '../../models/support_ticket.dart';
import '../../services/api/support_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxury_widgets.dart';

/// Ticket list — the "CUSTOMER CARE" entry point from the Account page.
/// Shows past tickets and lets the customer open a new one; tapping any
/// ticket opens its own chat thread (SupportChatView) with support.
class SupportTicketListView extends StatefulWidget {
  const SupportTicketListView({super.key});

  @override
  State<SupportTicketListView> createState() => _SupportTicketListViewState();
}

class _SupportTicketListViewState extends State<SupportTicketListView> {
  List<SupportTicket> _tickets = [];
  List<TicketType> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isSignedIn.value) _load();
  }

  Future<void> _load() async {
    final service = Get.find<SupportService>();
    final results = await Future.wait([
      service.getTickets(),
      service.getTicketTypes(),
    ]);
    if (!mounted) return;
    setState(() {
      _tickets = results[0] as List<SupportTicket>;
      _types = results[1] as List<TicketType>;
      _loading = false;
    });
  }

  Future<void> _openNewTicketSheet() async {
    final created = await showModalBottomSheet<SupportTicket>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KColors.white,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _NewTicketSheet(types: _types),
    );
    if (created == null || !mounted) return;
    setState(() => _tickets = [created, ..._tickets]);
    Get.to(() => SupportChatView(ticket: created));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = Get.find<AuthController>().isSignedIn.value;
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      floatingActionButton: !signedIn
          ? null
          : FloatingActionButton(
              onPressed: _openNewTicketSheet,
              backgroundColor: KColors.black,
              child: const Icon(Icons.add, color: KColors.white),
            ),
      body: !signedIn
          ? const _SupportSignInRequired()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
              children: [
                Text(
                  'CUSTOMER\nSUPPORT',
                  style: context.textTheme.editorialSmall,
                ),
                const SizedBox(height: 34),
                if (_tickets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: MicroLabel(
                        'NO SUPPORT TICKETS YET',
                        color: KColors.gray,
                      ),
                    ),
                  )
                else
                  for (final ticket in _tickets) ...[
                    _TicketCard(ticket: ticket, onChanged: _load),
                    const SectionDivider(),
                  ],
              ],
            ),
    );
  }
}

class _SupportSignInRequired extends StatelessWidget {
  const _SupportSignInRequired();

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
          const MicroLabel('SIGN IN TO CONTACT SUPPORT', color: KColors.gray),
          const SizedBox(height: 28),
          FullWidthButton(
            label: 'SIGN IN',
            onPressed: () => Get.offAllNamed(Routes.login),
          ),
        ],
      ),
    ),
  );
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onChanged});
  final SupportTicket ticket;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      await Get.to(() => SupportChatView(ticket: ticket));
      onChanged();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              MicroLabel(ticket.statusLabel, color: KColors.gray),
            ],
          ),
          const SizedBox(height: 8),
          if (ticket.ticketType.isNotEmpty)
            MicroLabel(ticket.ticketType, color: KColors.gray),
          const SizedBox(height: 6),
          Text(
            ticket.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: KColors.gray),
          ),
        ],
      ),
    ),
  );
}

class _NewTicketSheet extends StatefulWidget {
  const _NewTicketSheet({required this.types});
  final List<TicketType> types;

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  String? _typeId;
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_typeId == null ||
        _subject.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _description.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in every field.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final ticket = await Get.find<SupportService>().addTicket(
      ticketTypeId: _typeId!,
      subject: _subject.text.trim(),
      email: _email.text.trim(),
      description: _description.text.trim(),
    );
    if (!mounted) return;
    if (ticket == null) {
      setState(() {
        _sending = false;
        _error = 'Could not submit this ticket — please try again.';
      });
      return;
    }
    Navigator.of(context).pop(ticket);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MicroLabel('NEW SUPPORT TICKET'),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _typeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'TYPE'),
                items: [
                  for (final type in widget.types)
                    DropdownMenuItem(value: type.id, child: Text(type.title)),
                ],
                onChanged: (value) => setState(() => _typeId = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'EMAIL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'SUBJECT'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'DESCRIPTION'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              FullWidthButton(
                label: 'SEND',
                busy: _sending,
                onPressed: _sending ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single ticket's chat thread with support. Refreshes on a short timer
/// while open so replies show up without the customer needing to
/// pull-to-refresh — there's no push/websocket channel for this on the
/// server, so periodic polling is the simplest reliable way to feel "live".
class SupportChatView extends StatefulWidget {
  const SupportChatView({super.key, required this.ticket});
  final SupportTicket ticket;

  @override
  State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  List<TicketMessage> _messages = [];
  List<File> _pendingAttachments = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _load({bool silent = false}) async {
    final messages = await Get.find<SupportService>().getMessages(
      widget.ticket.id,
    );
    if (!mounted) return;
    final wasAtBottom =
        !silent ||
        !_scrollController.hasClients ||
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 40;
    setState(() {
      _messages = messages;
      if (!silent) _loading = false;
    });
    // Only auto-scroll on the initial load or if the customer was already
    // at the bottom — a silent background refresh shouldn't yank the view
    // away from wherever they've scrolled to read older messages.
    if (wasAtBottom) _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _pendingAttachments = [..._pendingAttachments, File(picked.path)],
    );
  }

  void _removePendingAttachment(File file) {
    setState(
      () => _pendingAttachments = _pendingAttachments
          .where((f) => f.path != file.path)
          .toList(),
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _pendingAttachments.isEmpty) || _sending) return;
    setState(() => _sending = true);
    _messageController.clear();
    final attachments = _pendingAttachments;
    setState(() => _pendingAttachments = []);
    final sent = await Get.find<SupportService>().sendMessage(
      ticketId: widget.ticket.id,
      message: text,
      attachments: attachments,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (sent != null) _messages = [..._messages, sent];
    });
    if (sent != null) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuxuryHeader(showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.ticket.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                MicroLabel(widget.ticket.statusLabel, color: KColors.gray),
              ],
            ),
          ),
          const Divider(height: 1, color: KColors.line),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: MicroLabel('NO MESSAGES YET', color: KColors.gray),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: _messages[index]),
                  ),
          ),
          if (!widget.ticket.isClosed)
            _MessageInput(
              controller: _messageController,
              sending: _sending,
              onSend: _send,
              pendingAttachments: _pendingAttachments,
              onPickImage: _pickImage,
              onRemoveAttachment: _removePendingAttachment,
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? KColors.black : KColors.offWhite,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!mine && message.name.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: MicroLabel(message.name, color: KColors.gray),
              ),
            for (final attachment in message.attachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _AttachmentPreview(attachment: attachment, mine: mine),
              ),
            if (message.message.isNotEmpty)
              Text(
                message.message,
                style: TextStyle(
                  color: mine ? KColors.white : KColors.black,
                  fontSize: 13,
                ),
              ),
            if (message.dateCreated.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message.dateCreated,
                style: TextStyle(
                  fontSize: 10,
                  color: mine
                      ? KColors.white.withValues(alpha: 0.6)
                      : KColors.gray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment, required this.mine});
  final TicketAttachment attachment;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return GestureDetector(
        onTap: () => Get.to(() => _FullScreenImageView(url: attachment.url)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            attachment.url,
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 180,
              height: 180,
              color: KColors.line,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      );
    }
    // Non-image (document/video/archive) — open externally rather than
    // trying to preview it inline.
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(attachment.url),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? Colors.white.withValues(alpha: 0.15) : KColors.line,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 16,
              color: mine ? KColors.white : KColors.black,
            ),
            const SizedBox(width: 6),
            Text(
              attachment.type.isEmpty
                  ? 'ATTACHMENT'
                  : attachment.type.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: mine ? KColors.white : KColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  const _FullScreenImageView({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Center(
      child: InteractiveViewer(
        child: Image.network(
          url,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image_outlined, color: Colors.white),
        ),
      ),
    ),
  );
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.pendingAttachments,
    required this.onPickImage,
    required this.onRemoveAttachment,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final List<File> pendingAttachments;
  final ValueChanged<ImageSource> onPickImage;
  final ValueChanged<File> onRemoveAttachment;

  Future<void> _showAttachmentSource(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) onPickImage(source);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: KColors.white,
        border: Border(top: BorderSide(color: KColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pendingAttachments.isNotEmpty)
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final file in pendingAttachments)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              file,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => onRemoveAttachment(file),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: KColors.black,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: KColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: sending
                    ? null
                    : () => _showAttachmentSource(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                color: KColors.black,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Write a message…',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: sending ? null : onSend,
                icon: const Icon(Icons.send),
                color: KColors.black,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
