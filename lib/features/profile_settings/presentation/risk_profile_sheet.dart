import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/mock/risk_profile_repository.dart';
import '../../../data/models/investor_risk_profile.dart';
import '../../../shared_widgets/shared_widgets.dart';

class RiskProfileSheet extends ConsumerStatefulWidget {
  const RiskProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RiskProfileSheet(),
    );
  }

  @override
  ConsumerState<RiskProfileSheet> createState() => _RiskProfileSheetState();
}

class _RiskProfileSheetState extends ConsumerState<RiskProfileSheet> {
  bool _isQuizActive = false;
  int _currentQuestionIdx = 0;
  final Map<int, int> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    final current = ref.read(riskProfileProvider);
    _selectedAnswers.addAll(current.answers);
  }

  void _startQuiz() {
    setState(() {
      _isQuizActive = true;
      _currentQuestionIdx = 0;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIdx < kRiskQuestions.length - 1) {
      setState(() {
        _currentQuestionIdx++;
      });
    } else {
      _submitAssessment();
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIdx > 0) {
      setState(() {
        _currentQuestionIdx--;
      });
    } else {
      setState(() {
        _isQuizActive = false;
      });
    }
  }

  void _submitAssessment() {
    ref.read(riskProfileProvider.notifier).submitAnswers(_selectedAnswers);
    final updated = ref.read(riskProfileProvider);

    setState(() {
      _isQuizActive = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Risk profile updated to ${updated.category.label} (${updated.score}/25 points).',
        ),
        backgroundColor: const Color(0xFF00A854),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final profile = ref.watch(riskProfileProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isQuizActive
              ? _buildQuizView(colors)
              : _buildOverviewView(colors, profile),
        ),
      ),
    );
  }

  // ==================== OVERVIEW MODE ====================
  Widget _buildOverviewView(TradingColors colors, InvestorRiskProfile profile) {
    final categoryColor = _getCategoryColor(profile.category, colors);
    final categoryIcon = _getCategoryIcon(profile.category);

    return SingleChildScrollView(
      key: const ValueKey('OverviewView'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const ZeroDragHandle(padding: EdgeInsets.only(bottom: 12)),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEBI Investor Risk Profile',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Statutory suitability & risk tolerance assessment',
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

          // Hero Category Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: categoryColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: categoryColor.withValues(alpha: 0.2),
                      child: Icon(categoryIcon, color: categoryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile.category.label,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: categoryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  profile.category.badgeText,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Assessed Score: ${profile.score} / 25 points',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  profile.category.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Risk Meter Gauge Bar
          Text(
            'Risk Tolerance Meter',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildRiskMeter(profile.score, colors),

          const SizedBox(height: 16),

          // SEBI Suitability Advisory Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  profile.isFnoSuitable
                      ? LucideIcons.shieldCheck
                      : LucideIcons.alertTriangle,
                  color: profile.isFnoSuitable
                      ? const Color(0xFF00A854)
                      : colors.bearish,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.isFnoSuitable
                            ? 'F&O Derivatives Suitability: ELIGIBLE'
                            : 'F&O Derivatives Suitability: CAUTION',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.suitabilityAdvisory,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recommended Asset Classes
          Text(
            'Recommended Asset Classes for ${profile.category.label}',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.category.suitableProducts
                .map(
                  (prod) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: colors.divider.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.check, size: 14, color: categoryColor),
                        const SizedBox(width: 6),
                        Text(
                          prod,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),

          // Retake Questionnaire Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(
              'Retake Risk Assessment Questionnaire',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            onPressed: _startQuiz,
          ),
        ],
      ),
    );
  }

  // ==================== QUIZ STEPPER MODE ====================
  Widget _buildQuizView(TradingColors colors) {
    final question = kRiskQuestions[_currentQuestionIdx];
    final selectedOptionIdx = _selectedAnswers[question.id];

    return SingleChildScrollView(
      key: ValueKey('QuizView_$_currentQuestionIdx'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const ZeroDragHandle(padding: EdgeInsets.only(bottom: 12)),

          // Stepper Header
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft,
                    color: colors.textPrimary, size: 20),
                onPressed: _prevQuestion,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentQuestionIdx + 1} of ${kRiskQuestions.length}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SEBI Suitability Assessment',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, color: colors.textSecondary),
                onPressed: () => setState(() => _isQuizActive = false),
              ),
            ],
          ),

          // Progress Bar
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestionIdx + 1) / kRiskQuestions.length,
              minHeight: 6,
              backgroundColor: colors.divider.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),

          const SizedBox(height: 16),

          // Question Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.description,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Options List
          ...List.generate(question.options.length, (idx) {
            final opt = question.options[idx];
            final isSelected = selectedOptionIdx == idx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? colors.primary
                        : colors.divider.withValues(alpha: 0.6),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[question.id] = idx;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.textSecondary,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.text,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              if (_currentQuestionIdx > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                          color: colors.divider.withValues(alpha: 0.8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _prevQuestion,
                    child: Text(
                      'Back',
                      style: GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (_currentQuestionIdx > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: selectedOptionIdx != null ? _nextQuestion : null,
                  child: Text(
                    _currentQuestionIdx == kRiskQuestions.length - 1
                        ? 'Calculate & Submit Profile'
                        : 'Next Question',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== VISUAL HELPERS ====================
  Widget _buildRiskMeter(int score, TradingColors colors) {
    // Score ranges from 5 to 25.
    // 5-10: Conservative, 11-18: Moderate, 19-25: Aggressive
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 6, // 5..10 (6 units)
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0284C7), // Blue
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: 8, // 11..18 (8 units)
              child: Container(
                height: 8,
                color: const Color(0xFF10B981), // Green
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: 7, // 19..25 (7 units)
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B), // Amber / Orange
                  borderRadius:
                      BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Conservative (5-10)',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0284C7))),
            Text('Moderate (11-18)',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981))),
            Text('Aggressive (19-25)',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF59E0B))),
          ],
        ),
      ],
    );
  }

  Color _getCategoryColor(RiskCategory category, TradingColors colors) {
    switch (category) {
      case RiskCategory.conservative:
        return const Color(0xFF0284C7); // Sky Blue
      case RiskCategory.moderate:
        return const Color(0xFF10B981); // Emerald Green
      case RiskCategory.aggressive:
        return const Color(0xFFF59E0B); // Amber / High Risk
    }
  }

  IconData _getCategoryIcon(RiskCategory category) {
    switch (category) {
      case RiskCategory.conservative:
        return LucideIcons.shield;
      case RiskCategory.moderate:
        return LucideIcons.scale;
      case RiskCategory.aggressive:
        return LucideIcons.flame;
    }
  }
}
