import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../data/compliance_repository.dart';

class NomineeManagementSheet extends ConsumerStatefulWidget {
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
  ConsumerState<NomineeManagementSheet> createState() => _NomineeManagementSheetState();
}

class _NomineeManagementSheetState extends ConsumerState<NomineeManagementSheet> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  late final TextEditingController _nameController;
  String _relation = 'SPOUSE';
  late final TextEditingController _dobController;
  late final TextEditingController _panController;
  late final TextEditingController _allocationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _panController = TextEditingController();
    _allocationController = TextEditingController(text: '100%');
    _loadNominees();
  }

  Future<void> _loadNominees() async {
    try {
      final repo = ref.read(complianceRepositoryProvider);
      final nominees = await repo.getNominees();
      if (nominees.isNotEmpty && mounted) {
        final first = nominees.first;
        _nameController.text = (first['name'] ?? '').toString();
        _relation = (first['relationship'] ?? 'SPOUSE').toString().toUpperCase();
        _dobController.text = (first['dob'] ?? '').toString();
        _panController.text = (first['idProofNumber'] ?? '').toString();
        _allocationController.text = '${first['sharePercentage'] ?? 100}%';
      }
    } catch (_) {
      // Empty or not configured yet
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNominee() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter nominee name.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(complianceRepositoryProvider);
      final share = int.tryParse(_allocationController.text.replaceAll('%', '').trim()) ?? 100;
      await repo.saveNominees([
        {
          'name': name,
          'relationship': _relation,
          'dob': _dobController.text.trim().isEmpty ? '1995-01-01' : _dobController.text.trim(),
          'sharePercentage': share,
          'idProofNumber': _panController.text.trim().isEmpty ? 'PAN1234567' : _panController.text.trim(),
        }
      ]);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nominee details successfully saved.'),
            backgroundColor: Color(0xFF00A854),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save nominee: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Add up to 3 nominees for your paper trading Demat and ledger account as per regulatory mandate.',
                style: GoogleFonts.inter(fontSize: 12.5, color: colors.textSecondary),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Card Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(LucideIcons.userCheck, size: 18, color: colors.primary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Primary Nominee (100% Share)',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: colors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isEditing)
                            TextButton.icon(
                              onPressed: () => setState(() => _isEditing = true),
                              icon: const Icon(LucideIcons.pencil, size: 14),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildField('Full Name', _nameController, colors, enabled: _isEditing),
                      const SizedBox(height: 10),
                      Text(
                        'Relationship',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isEditing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _relation,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'SPOUSE', child: Text('Spouse')),
                                DropdownMenuItem(value: 'PARENT', child: Text('Parent')),
                                DropdownMenuItem(value: 'CHILD', child: Text('Child')),
                                DropdownMenuItem(value: 'SIBLING', child: Text('Sibling')),
                              ],
                              onChanged: (val) => setState(() => _relation = val ?? 'SPOUSE'),
                            ),
                          ),
                        )
                      else
                        Text(
                          _relation,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                        ),
                      const SizedBox(height: 10),
                      _buildField('Date of Birth (YYYY-MM-DD)', _dobController, colors, enabled: _isEditing),
                      const SizedBox(height: 10),
                      _buildField('PAN / Identity Proof', _panController, colors, enabled: _isEditing),
                      const SizedBox(height: 10),
                      _buildField('Share Percentage', _allocationController, colors, enabled: _isEditing),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
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
                          onPressed: _isSaving ? null : _saveNominee,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('SAVE NOMINEE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
              ],
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
