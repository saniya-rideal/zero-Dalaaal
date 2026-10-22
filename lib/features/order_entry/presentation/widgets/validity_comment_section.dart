import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../data/models/enums.dart';
import '../controllers/order_entry_controller.dart';

class ValidityCommentSection extends StatefulWidget {
  final OrderEntryState state;
  final ValueChanged<Validity> onValidityChanged;
  final ValueChanged<DateTime> onGtcExpiryChanged;
  final ValueChanged<String> onCommentChanged;

  const ValidityCommentSection({
    super.key,
    required this.state,
    required this.onValidityChanged,
    required this.onGtcExpiryChanged,
    required this.onCommentChanged,
  });

  @override
  State<ValidityCommentSection> createState() => _ValidityCommentSectionState();
}

class _ValidityCommentSectionState extends State<ValidityCommentSection> {
  late final TextEditingController _commentCtrl;
  bool _showCommentField = false;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController(text: widget.state.comment);
    _showCommentField = widget.state.comment.isNotEmpty;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;
    final validities = [Validity.DAY, Validity.IOC, Validity.GTC];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF282D37) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Validity / Time-In-Force',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _showCommentField = !_showCommentField;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _showCommentField ? LucideIcons.messageSquareDashed : LucideIcons.messageSquare,
                      size: 13,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showCommentField ? 'Hide Note' : 'Add Note',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Validity Chips
          Row(
            children: validities.map((val) {
              final isSelected = widget.state.validity == val;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    val.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colors.accent,
                  backgroundColor: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? colors.accent
                          : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  onSelected: (_) => widget.onValidityChanged(val),
                ),
              );
            }).toList(),
          ),

          // GTC Expiry Date Picker
          if (widget.state.validity == Validity.GTC) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _pickExpiryDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 16, color: colors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.state.gtcExpiry != null
                            ? 'Expires on: ${widget.state.gtcExpiry!.toLocal().toString().split(' ')[0]}'
                            : 'Select GTC Expiry Date (Default: 365 Days)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],

          // Optional Comment / Note Field
          if (_showCommentField) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLength: 140,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Order tag or strategy note (e.g. Breakout setup)',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                counterText: '',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E232E) : const Color(0xFFF9FAFB),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              onChanged: widget.onCommentChanged,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickExpiryDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.state.gtcExpiry ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      widget.onGtcExpiryChanged(picked);
    }
  }
}
