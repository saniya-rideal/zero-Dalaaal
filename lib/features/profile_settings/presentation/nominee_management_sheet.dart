import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';

class NomineeManagementSheet extends StatefulWidget {
  const NomineeManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NomineeManagementSheet(),
    );
  }

  @override
  State<NomineeManagementSheet> createState() => _NomineeManagementSheetState();
}

class _NomineeManagementSheetState extends State<NomineeManagementSheet> {
  bool _isEditing = false;
  final _nameController = TextEditingController(text: 'Pooja Singh');
  String _relation = 'Spouse';
  final _dobController = TextEditingController(text: '1996-11-22');
  final _panController = TextEditingController(text: 'ABCPS9821K');
  final _allocationController = TextEditingController(text: '100%');

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _panController.dispose();
    _allocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Nominee / Beneficiary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Status Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bullish.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.bullish.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF00A854), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SEBI compliant: Nominee 1 is registered with 100% portfolio allocation.',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Nominee Fields
              _buildField('Nominee Full Name', _nameController, colors, enabled: _isEditing),
              const SizedBox(height: 12),

              // Relationship Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relationship', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _relation,
                    isExpanded: true,
                    dropdownColor: colors.cardBackground,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['Spouse', 'Child', 'Parent', 'Sibling', 'Other']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: colors.textPrimary, fontSize: 13))))
                        .toList(),
                    onChanged: _isEditing ? (val) => setState(() => _relation = val!) : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildField('Nominee Date of Birth', _dobController, colors, enabled: _isEditing),
              const SizedBox(height: 12),

              _buildField('Nominee PAN / Identification', _panController, colors, enabled: _isEditing),
              const SizedBox(height: 12),

              _buildField('Allocation Share (%)', _allocationController, colors, enabled: _isEditing),

              const SizedBox(height: 20),

              if (!_isEditing)
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('EDIT NOMINEE DETAILS', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => setState(() => _isEditing = true),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nominee details successfully updated.'),
                              backgroundColor: Color(0xFF00A854),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('SAVE NOMINEE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, TradingColors colors, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
          decoration: InputDecoration(
            isDense: true,
            filled: !enabled,
            fillColor: enabled ? null : colors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }
}
