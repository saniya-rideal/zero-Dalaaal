import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/mock/support_repository.dart';
import '../../../data/models/models.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<TicketAttachment> _pendingAttachments = [];

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    final repo = ref.read(supportRepositoryProvider);
    repo.addReply(
      ticketId: widget.ticketId,
      content: text.isNotEmpty ? text : 'Attached document proof for reference.',
      attachments: List.from(_pendingAttachments),
    );

    _replyController.clear();
    setState(() => _pendingAttachments.clear());
    _scrollToBottom();
  }

  void _addSimulatedAttachment({required bool isPdf}) {
    final rng = Random();
    final id = 'att_${DateTime.now().millisecondsSinceEpoch}';
    final name = isPdf
        ? 'document_proof_${rng.nextInt(900) + 100}.pdf'
        : 'screenshot_${rng.nextInt(900) + 100}.png';
    final size = isPdf ? rng.nextInt(600000) + 150000 : rng.nextInt(250000) + 40000;

    setState(() {
      _pendingAttachments.add(TicketAttachment(
        id: id,
        fileName: name,
        fileSizeBytes: size,
        fileType: isPdf ? 'pdf' : 'image',
        uploadedAt: DateTime.now(),
      ));
    });
  }

  Color _getStatusColor(TicketStatus s, TradingColors colors) {
    switch (s) {
      case TicketStatus.open:
        return colors.primary;
      case TicketStatus.inProgress:
        return colors.warning;
      case TicketStatus.awaitingClient:
        return Colors.purpleAccent;
      case TicketStatus.resolved:
        return colors.bullish;
      case TicketStatus.closed:
        return colors.neutral;
    }
  }

  Color _getPriorityColor(TicketPriority p, TradingColors colors) {
    switch (p) {
      case TicketPriority.low:
        return colors.neutral;
      case TicketPriority.medium:
        return colors.primary;
      case TicketPriority.high:
        return colors.warning;
      case TicketPriority.critical:
        return colors.bearish;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final repo = ref.watch(supportRepositoryProvider);
    final ticket = repo.getTicketById(widget.ticketId);

    if (ticket == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          title: Text('Ticket Not Found', style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700)),
        ),
        body: Center(
          child: Text('Support Ticket #${widget.ticketId} was not found.', style: AppTypography.body(color: colors.textSecondary)),
        ),
      );
    }

    final statusColor = _getStatusColor(ticket.status, colors);
    final priorityColor = _getPriorityColor(ticket.priority, colors);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${ticket.id}',
              style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
            ),
            Text(
              ticket.category.label,
              style: AppTypography.caption(color: colors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (ticket.status != TicketStatus.resolved && ticket.status != TicketStatus.closed)
            TextButton.icon(
              icon: Icon(Icons.check_circle_outline, color: colors.bullish, size: 18),
              label: Text('Resolve', style: AppTypography.caption(color: colors.bullish, weight: FontWeight.w700)),
              onPressed: () {
                repo.updateTicketStatus(ticket.id, TicketStatus.resolved);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket marked as Resolved.')),
                );
              },
            )
          else
            TextButton.icon(
              icon: Icon(Icons.replay_rounded, color: colors.primary, size: 18),
              label: Text('Reopen', style: AppTypography.caption(color: colors.primary, weight: FontWeight.w700)),
              onPressed: () {
                repo.updateTicketStatus(ticket.id, TicketStatus.open);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket reopened for further assistance.')),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Ticket Overview Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    ticket.status.label.toUpperCase(),
                    style: AppTypography.labelSmall(color: statusColor, weight: FontWeight.w700),
                  ),
                ),
                // Priority Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${ticket.priority.label} Priority',
                    style: AppTypography.labelSmall(color: priorityColor, weight: FontWeight.w700),
                  ),
                ),
                // Officer Info
                Text(
                  ticket.assignedAgent,
                  style: AppTypography.labelSmall(color: colors.textSecondary),
                ),
              ],
            ),
          ),

          // Conversation Thread
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: ticket.messages.length + 1, // +1 for subject header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Created on ${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year} at ${ticket.createdAt.hour}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                          style: AppTypography.caption(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final msg = ticket.messages[index - 1];
                return _buildMessageBubble(msg, colors);
              },
            ),
          ),

          // Pending Attachment Preview Bar
          if (_pendingAttachments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: colors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: _pendingAttachments.map((att) {
                        return Chip(
                          avatar: Icon(att.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image, size: 14, color: colors.primary),
                          label: Text(att.fileName, style: AppTypography.labelSmall(color: colors.textPrimary)),
                          backgroundColor: colors.cardBackground,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _pendingAttachments.remove(att)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Reply Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                // Add attachment menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.attach_file, color: colors.textSecondary),
                  tooltip: 'Attach proof or screenshot',
                  onSelected: (val) {
                    if (val == 'image') _addSimulatedAttachment(isPdf: false);
                    if (val == 'pdf') _addSimulatedAttachment(isPdf: true);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'image', child: Text('Attach Screenshot (.png)')),
                    const PopupMenuItem(value: 'pdf', child: Text('Attach Bank/CMR PDF (.pdf)')),
                  ],
                ),
                // Text Field
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    maxLines: 3,
                    minLines: 1,
                    style: AppTypography.body(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type your message to support desk...',
                      hintStyle: AppTypography.body(color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                CircleAvatar(
                  backgroundColor: colors.primary,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _sendReply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TicketMessage msg, TradingColors colors) {
    final isClient = msg.senderRole == MessageSenderRole.client;
    final isSystem = msg.senderRole == MessageSenderRole.system;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: Text(
            msg.content,
            style: AppTypography.labelSmall(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Align(
      alignment: isClient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isClient ? colors.primary.withValues(alpha: 0.15) : colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isClient ? colors.primary.withValues(alpha: 0.4) : colors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                if (!isClient) ...[
                  Icon(Icons.support_agent, size: 16, color: colors.primary),
                  const SizedBox(width: 4),
                ],
                Text(
                  msg.senderName,
                  style: AppTypography.labelSmall(
                    color: isClient ? colors.primary : colors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  msg.timeAgo,
                  style: AppTypography.caption(color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.content,
              style: AppTypography.body(color: colors.textPrimary),
            ),
            if (msg.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...msg.attachments.map((att) {
                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(att.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image, size: 16, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${att.fileName} (${att.formattedSize})',
                        style: AppTypography.labelSmall(color: colors.textPrimary, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
