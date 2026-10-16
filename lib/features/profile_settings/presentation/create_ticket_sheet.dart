import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/support_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';

class CreateTicketSheet extends ConsumerStatefulWidget {
  const CreateTicketSheet({super.key});

  static Future<SupportTicket?> show(BuildContext context) {
    return showModalBottomSheet<SupportTicket>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateTicketSheet(),
    );
  }

  @override
  ConsumerState<CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  TicketCategory _category = TicketCategory.tradingOrders;
  TicketPriority _priority = TicketPriority.medium;
  final List<TicketAttachment> _attachments = [];
  bool _isSubmitting = false;
  bool _isUploadingAttachment = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAttachment({required bool isPdf}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: isPdf ? FileType.custom : FileType.image,
        allowedExtensions: isPdf ? ['pdf'] : null,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null || bytes.isEmpty) return;

      setState(() => _isUploadingAttachment = true);

      final repo = ref.read(supportRepositoryProvider);
      final attachment = await repo.uploadAttachment(
        fileName: file.name,
        bytes: bytes,
        mimeType: isPdf ? 'application/pdf' : 'image/png',
      );

      if (mounted) {
        setState(() {
          _attachments.add(attachment);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} uploaded successfully.'),
            backgroundColor: const Color(0xFF00A854),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload attachment: $e'),
            backgroundColor: const Color(0xFFE23A3A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
    }
  }

  Future<void> _submitTicket() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final repo = ref.read(supportRepositoryProvider);
    final ticket = await repo.createTicket(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      priority: _priority,
      attachments: _attachments,
    );

    if (mounted) {
      Navigator.of(context).pop(ticket);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket #${ticket.id} submitted. Desk officer assigned.'),
          duration: const Duration(seconds: 3),
        ),
      );
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const ZeroDragHandle(padding: EdgeInsets.only(top: 12, bottom: 8)),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raise Support Ticket',
                        style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Direct line to specialized desk officers',
                        style: AppTypography.caption(color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form Body
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Category Dropdown
                  Text('ISSUE CATEGORY', style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TicketCategory>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: colors.cardBackground,
                    style: AppTypography.body(color: colors.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: TicketCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // 2. Priority Selection
                  Text('PRIORITY LEVEL', style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TicketPriority.values.map((p) {
                      final isSelected = _priority == p;
                      final pColor = _getPriorityColor(p, colors);
                      return ChoiceChip(
                        label: Text(
                          p.label,
                          style: AppTypography.labelSmall(
                            color: isSelected ? Colors.white : colors.textPrimary,
                            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: pColor,
                        backgroundColor: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? pColor : colors.divider),
                        ),
                        onSelected: (_) => setState(() => _priority = p),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 3. Subject / Title
                  Text('SUBJECT', style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: AppTypography.body(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Brief summary of the issue...',
                      hintStyle: AppTypography.body(color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter a subject.';
                      if (val.trim().length < 5) return 'Subject should be at least 5 characters.';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 4. Description
                  Text('DETAILED DESCRIPTION', style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 5,
                    style: AppTypography.body(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Please describe what happened, order IDs, UTR reference numbers, or expected resolution...',
                      hintStyle: AppTypography.body(color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please describe your issue.';
                      if (val.trim().length < 15) return 'Please provide more details (at least 15 characters).';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 5. Attachment Upload Section
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text('ATTACHMENTS (OPTIONAL)', style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700)),
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            icon: const Icon(LucideIcons.image, size: 16),
                            label: Text('Add Image', style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600)),
                            onPressed: _isUploadingAttachment ? null : () => _pickAndUploadAttachment(isPdf: false),
                          ),
                          TextButton.icon(
                            icon: const Icon(LucideIcons.fileText, size: 16),
                            label: Text('Add PDF', style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600)),
                            onPressed: _isUploadingAttachment ? null : () => _pickAndUploadAttachment(isPdf: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachments.map((att) {
                        return Chip(
                          avatar: Icon(
                            att.fileType == 'pdf' ? LucideIcons.fileText : LucideIcons.image,
                            size: 14,
                            color: colors.primary,
                          ),
                          label: Text(
                            '${att.fileName} (${att.formattedSize})',
                            style: AppTypography.labelSmall(color: colors.textPrimary),
                          ),
                          backgroundColor: colors.surface,
                          deleteIcon: const Icon(LucideIcons.x, size: 14),
                          onDeleted: () {
                            setState(() => _attachments.remove(att));
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Submit Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'SUBMIT TICKET',
                        style: AppTypography.body(color: Colors.white, weight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
