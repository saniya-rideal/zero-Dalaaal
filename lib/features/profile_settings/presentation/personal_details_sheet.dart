import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../auth/presentation/auth_controller.dart';

class PersonalDetailsSheet extends ConsumerStatefulWidget {
  const PersonalDetailsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PersonalDetailsSheet(),
    );
  }

  @override
  ConsumerState<PersonalDetailsSheet> createState() => _PersonalDetailsSheetState();
}

class _PersonalDetailsSheetState extends ConsumerState<PersonalDetailsSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).session?.profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _mobileController = TextEditingController(text: profile?.phone ?? '');
    _dobController = TextEditingController(text: profile?.dob ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    final profile = ref.read(authControllerProvider).session?.profile;
    final Map<String, dynamic> changedFields = {};

    if (_nameController.text.trim() != profile?.name) {
      changedFields['name'] = _nameController.text.trim();
    }
    if (_mobileController.text.trim() != profile?.phone) {
      changedFields['phone'] = _mobileController.text.trim();
    }
    if (_dobController.text.trim() != profile?.dob) {
      changedFields['dob'] = _dobController.text.trim();
    }
    if (_addressController.text.trim() != profile?.address) {
      changedFields['address'] = _addressController.text.trim();
    }

    if (changedFields.isEmpty) {
      setState(() => _isEditing = false);
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).updateProfile(changedFields);
    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal profile details updated successfully.'),
          backgroundColor: Color(0xFF00A854),
        ),
      );
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Failed to update profile.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);
    final profile = authState.session?.profile;
    final userId = profile?.userId ?? '-';
    final pan = profile?.pan ?? '-';

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
                      'Personal & Demat Profile',
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
                    icon: Icon(LucideIcons.x, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Account Status Header Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.divider),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client User ID', style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
                        Text(userId, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Type', style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
                        Text('Resident Individual', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.bullish.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        profile?.kycStatus ?? 'ACTIVE',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: colors.bullish),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Form fields
              _buildFieldRow(
                label: 'Full Name',
                controller: _nameController,
                colors: colors,
                enabled: _isEditing,
                suffixIcon: const Icon(LucideIcons.user, size: 18),
              ),
              const SizedBox(height: 12),

              _buildFieldRow(
                label: 'PAN Number (Permanent)',
                controller: TextEditingController(text: pan),
                colors: colors,
                enabled: false,
                verified: true,
              ),
              const SizedBox(height: 12),

              _buildFieldRow(
                label: 'Mobile Number',
                controller: _mobileController,
                colors: colors,
                enabled: _isEditing,
                verified: true,
              ),
              const SizedBox(height: 12),

              _buildFieldRow(
                label: 'Email Address',
                controller: _emailController,
                colors: colors,
                enabled: false,
                verified: true,
              ),
              const SizedBox(height: 12),

              _buildFieldRow(
                label: 'Date of Birth',
                controller: _dobController,
                colors: colors,
                enabled: _isEditing,
                suffixIcon: const Icon(LucideIcons.calendar, size: 18),
              ),
              const SizedBox(height: 12),

              _buildFieldRow(
                label: 'Permanent Address',
                controller: _addressController,
                colors: colors,
                enabled: _isEditing,
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              _buildFieldRow(
                label: 'Bank Account (Masked)',
                controller: TextEditingController(text: profile?.bankAccountNumber ?? '-'),
                colors: colors,
                enabled: false,
                verified: profile?.bankAccountNumber != null,
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (!_isEditing)
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.penSquare, size: 16),
                  label: const Text('EDIT PERSONAL DETAILS', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        onPressed: authState.isLoading ? null : _handleSaveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildFieldRow({
    required String label,
    required TextEditingController controller,
    required TradingColors colors,
    bool enabled = true,
    bool verified = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.badgeCheck, size: 14, color: Color(0xFF00A854)),
                  const SizedBox(width: 4),
                  Text('Verified', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF00A854))),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: suffixIcon,
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
