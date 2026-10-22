import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/models/learning_content.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../data/learning_repository.dart';

final learningModulesProvider = FutureProvider.autoDispose<List<LearningModule>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getModules();
});

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  LearningCategory _selectedCategory = LearningCategory.ALL;

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final modulesAsync = ref.watch(learningModulesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/learning'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) {
            final canPop = Navigator.of(ctx).canPop();
            if (canPop) {
              return IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
                onPressed: () => Navigator.of(ctx).pop(),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(LucideIcons.menu, color: colors.textPrimary, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zero Academy',
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Trading Concepts, F&O & Risk Management',
              style: GoogleFonts.inter(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category selector chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: LearningCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      cat.name.replaceAll('_', ' '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : colors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    backgroundColor: colors.surface,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? colors.primary : colors.divider,
                      ),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Modules list
          Expanded(
            child: modulesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.circleAlert, size: 48, color: colors.bearish),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load learning modules',
                        style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(learningModulesProvider),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (modules) {
                final filtered = _selectedCategory == LearningCategory.ALL
                    ? modules
                    : modules.where((m) => m.category == _selectedCategory).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.graduationCap, size: 56, color: colors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'No Modules Available',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check back soon for new lessons in this category.',
                          style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: colors.primary,
                  onRefresh: () async => ref.invalidate(learningModulesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final module = filtered[index];
                      return _buildModuleCard(context, module, colors);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, LearningModule module, TradingColors colors) {
    return InkWell(
      onTap: () => _showModuleDetail(context, module, colors),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    module.category.name.replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    module.level.name,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.clock, size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${module.readTimeMinutes} min',
                  style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              module.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              module.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${module.sections.length} sections',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showModuleDetail(BuildContext context, LearningModule module, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  module.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  module.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 32),
                ...module.sections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.content,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: colors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        if (section.keyTakeaways.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Key Takeaways',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...section.keyTakeaways.map(
                                  (t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('• ', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                                        Expanded(
                                          child: Text(t, style: GoogleFonts.inter(fontSize: 12.5, color: colors.textSecondary)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (section.proTip != null && section.proTip!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(LucideIcons.lightbulb, size: 18, color: colors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    section.proTip!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
