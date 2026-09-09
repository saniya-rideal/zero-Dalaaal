import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/mock/fatca_repository.dart';
import '../../../data/models/fatca_declaration.dart';
import '../../../shared_widgets/shared_widgets.dart';

class FatcaDeclarationSheet extends ConsumerStatefulWidget {
  const FatcaDeclarationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FatcaDeclarationSheet(),
    );
  }

  @override
  ConsumerState<FatcaDeclarationSheet> createState() =>
      _FatcaDeclarationSheetState();
}

class _FatcaDeclarationSheetState extends ConsumerState<FatcaDeclarationSheet> {
  late bool _isIndianTaxResidentOnly;
  late bool _isUsPerson;
  late bool _isPoliticallyExposed;
  late bool _isRelatedToPoliticallyExposed;
  late String _birthCountry;
  late TextEditingController _birthCityController;
  late TextEditingController _taxResidencyCountryController;
  late TextEditingController _tinController;
  late String _occupation;
  late String _incomeBracket;
  bool _undertakingAccepted = true;

  final List<String> _occupations = [
    'Private Sector',
    'Public Sector',
    'Business / Self-Employed',
    'Professional',
    'Student',
    'Retired',
    'Housewife',
    'Agriculture',
  ];

  final List<String> _incomeBrackets = [
    'Below ₹1 Lakh',
    '₹1L - ₹5L',
    '₹5L - ₹10L',
    '₹10L - ₹25L',
    'Above ₹25 Lakhs',
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(fatcaDeclarationProvider);
    _isIndianTaxResidentOnly = current.isIndianTaxResidentOnly;
    _isUsPerson = current.isUsPerson;
    _isPoliticallyExposed = current.isPoliticallyExposed;
    _isRelatedToPoliticallyExposed = current.isRelatedToPoliticallyExposed;
    _birthCountry = current.birthCountry;
    _birthCityController = TextEditingController(text: current.birthCity);
    _taxResidencyCountryController =
        TextEditingController(text: current.taxResidencyCountry ?? '');
    _tinController =
        TextEditingController(text: current.taxIdentificationNumber ?? '');
    _occupation = current.occupation;
    _incomeBracket = current.grossAnnualIncomeBracket;
  }

  @override
  void dispose() {
    _birthCityController.dispose();
    _taxResidencyCountryController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  void _saveDeclaration() {
    if (!_undertakingAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the statutory declaration undertaking.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    if (!_isIndianTaxResidentOnly &&
        _taxResidencyCountryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify your foreign Country of Tax Residency.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    final updated = FatcaDeclaration(
      isIndianTaxResidentOnly: _isIndianTaxResidentOnly,
      isUsPerson: _isUsPerson,
      isPoliticallyExposed: _isPoliticallyExposed,
      isRelatedToPoliticallyExposed: _isRelatedToPoliticallyExposed,
      birthCountry: _birthCountry,
      birthCity: _birthCityController.text.trim().isEmpty
          ? 'Mumbai'
          : _birthCityController.text.trim(),
      taxResidencyCountry: _isIndianTaxResidentOnly
          ? null
          : _taxResidencyCountryController.text.trim(),
      taxIdentificationNumber:
          _isIndianTaxResidentOnly ? null : _tinController.text.trim(),
      occupation: _occupation,
      grossAnnualIncomeBracket: _incomeBracket,
      declarationTimestamp: DateTime.now(),
      status: 'VERIFIED',
    );

    ref.read(fatcaDeclarationProvider.notifier).update(updated);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FATCA / CRS declaration submitted and verified.'),
        backgroundColor: Color(0xFF00A854),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final current = ref.watch(fatcaDeclarationProvider);

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              const ZeroDragHandle(padding: EdgeInsets.only(bottom: 16)),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FATCA / CRS & PEP Declaration',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mandated under IT Rules 114F–114H & SEBI/PMLA',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Status Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bullish.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: colors.bullish.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck,
                        color: Color(0xFF00A854), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${current.status} (Complied)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Declared on: ${_formatDate(current.declarationTimestamp)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section 1: Tax Residency
              _buildSectionTitle('1. Tax Residency Declaration', colors),
              const SizedBox(height: 8),
              _buildToggleCard(
                title: 'Are you a tax resident of India ONLY?',
                subtitle:
                    'Select NO if you pay income tax in any foreign jurisdiction or country outside India.',
                value: _isIndianTaxResidentOnly,
                onChanged: (val) {
                  setState(() {
                    _isIndianTaxResidentOnly = val;
                  });
                },
                colors: colors,
              ),

              // Expandable foreign residency fields
              if (!_isIndianTaxResidentOnly) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foreign Tax Details (CRS Mandate)',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'Country of Tax Residency',
                        controller: _taxResidencyCountryController,
                        hint: 'e.g. United Kingdom, Singapore, UAE',
                        colors: colors,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'Tax Identification Number (TIN / SSN)',
                        controller: _tinController,
                        hint: 'Foreign Tax ID issued by your tax authority',
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Section 2: US Person Status
              _buildSectionTitle('2. US Person Status', colors),
              const SizedBox(height: 8),
              _buildToggleCard(
                title: 'Are you a US Person?',
                subtitle:
                    'Includes US Citizen, US Green Card holder, or US resident under Substantial Presence test.',
                value: _isUsPerson,
                onChanged: (val) {
                  setState(() {
                    _isUsPerson = val;
                  });
                },
                colors: colors,
                invertLabelColors: true,
              ),

              const SizedBox(height: 16),

              // Section 3: Politically Exposed Person (PEP)
              _buildSectionTitle('3. Politically Exposed Person (PEP)', colors),
              const SizedBox(height: 8),
              _buildPepRadioGroup(colors),

              const SizedBox(height: 16),

              // Section 4: Place of Birth & Occupation
              _buildSectionTitle('4. Personal & Financial Profile', colors),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Country of Birth',
                      value: _birthCountry,
                      items: const ['India', 'United States', 'UK', 'UAE', 'Other'],
                      onChanged: (val) {
                        if (val != null) setState(() => _birthCountry = val);
                      },
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Place / City of Birth',
                      controller: _birthCityController,
                      hint: 'e.g. Mumbai',
                      colors: colors,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Primary Occupation',
                value: _occupations.contains(_occupation)
                    ? _occupation
                    : _occupations.first,
                items: _occupations,
                onChanged: (val) {
                  if (val != null) setState(() => _occupation = val);
                },
                colors: colors,
              ),

              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Gross Annual Income Bracket',
                value: _incomeBrackets.contains(_incomeBracket)
                    ? _incomeBracket
                    : _incomeBrackets[2],
                items: _incomeBrackets,
                onChanged: (val) {
                  if (val != null) setState(() => _incomeBracket = val);
                },
                colors: colors,
              ),

              const SizedBox(height: 20),

              // Statutory Undertaking
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.divider.withValues(alpha: 0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _undertakingAccepted,
                      activeColor: colors.primary,
                      onChanged: (v) =>
                          setState(() => _undertakingAccepted = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'I hereby certify under penalties of perjury that all statements made in this FATCA/CRS self-declaration are true and correct. I undertake to notify the intermediary within 30 days in case of any change in my tax residency status.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saveDeclaration,
                child: Text(
                  'Confirm & Update FATCA Declaration',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, TradingColors colors) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TradingColors colors,
    bool invertLabelColors = false,
  }) {
    final yesColor = invertLabelColors ? colors.bearish : colors.bullish;
    final noColor = invertLabelColors ? colors.bullish : colors.bearish;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildChoiceChip(
                    label: 'YES',
                    isSelected: value,
                    activeColor: yesColor,
                    onTap: () => onChanged(true),
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _buildChoiceChip(
                    label: 'NO',
                    isSelected: !value,
                    activeColor: noColor,
                    onTap: () => onChanged(false),
                    colors: colors,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : colors.cardBackground,
          border: Border.all(
            color: isSelected
                ? activeColor
                : colors.divider.withValues(alpha: 0.8),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPepRadioGroup(TradingColors colors) {
    int selectedVal = 0;
    if (_isPoliticallyExposed) {
      selectedVal = 1;
    } else if (_isRelatedToPoliticallyExposed) {
      selectedVal = 2;
    }

    return Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.divider.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          RadioListTile<int>(
            dense: true,
            title: Text(
              'Not Applicable (Standard Trader)',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Neither PEP nor related to PEP.',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: colors.textSecondary,
              ),
            ),
            value: 0,
            groupValue: selectedVal,
            activeColor: colors.primary,
            onChanged: (val) {
              setState(() {
                _isPoliticallyExposed = false;
                _isRelatedToPoliticallyExposed = false;
              });
            },
          ),
          Divider(height: 1, color: colors.divider.withValues(alpha: 0.3)),
          RadioListTile<int>(
            dense: true,
            title: Text(
              'I am a Politically Exposed Person (PEP)',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Senior politician, government official, or judicial officer.',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: colors.textSecondary,
              ),
            ),
            value: 1,
            groupValue: selectedVal,
            activeColor: colors.bearish,
            onChanged: (val) {
              setState(() {
                _isPoliticallyExposed = true;
                _isRelatedToPoliticallyExposed = false;
              });
            },
          ),
          Divider(height: 1, color: colors.divider.withValues(alpha: 0.3)),
          RadioListTile<int>(
            dense: true,
            title: Text(
              'Related to a Politically Exposed Person',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Close relative or associate of a senior political figure.',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: colors.textSecondary,
              ),
            ),
            value: 2,
            groupValue: selectedVal,
            activeColor: colors.bearish,
            onChanged: (val) {
              setState(() {
                _isPoliticallyExposed = false;
                _isRelatedToPoliticallyExposed = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TradingColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
            filled: true,
            fillColor: colors.cardBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors.divider.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors.divider.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required TradingColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary),
          dropdownColor: colors.cardBackground,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors.divider.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors.divider.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
