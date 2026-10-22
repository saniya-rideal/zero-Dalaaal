import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/enums.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../market/data/real_market_repository.dart';
import '../data/alerts_repository.dart';

final alertsListProvider = FutureProvider.autoDispose<List<PriceAlert>>((ref) async {
  final repo = ref.watch(alertsRepositoryProvider);
  return repo.getAlerts();
});

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isActionInProgress = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAlertDialog() {
    final colors = context.tradingColors;
    final defaultSym = ref.read(cachedInstrumentsProvider).value?.firstOrNull?.symbol ?? '';
    final scriptController = TextEditingController(text: defaultSym);
    final priceController = TextEditingController();
    String condition = 'GTE';
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(bottomContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Price Alert',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scriptController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Symbol',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: condition,
                dropdownColor: colors.cardBackground,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Condition',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'GTE', child: Text('Price >= (Greater than or Equal)')),
                  DropdownMenuItem(value: 'LTE', child: Text('Price <= (Less than or Equal)')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => condition = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Target Trigger Price',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isCreating
                    ? null
                    : () async {
                        final target = double.tryParse(priceController.text) ?? 0.0;
                        final sym = scriptController.text.trim().toUpperCase();
                        if (sym.isEmpty || target <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter valid symbol and price')),
                          );
                          return;
                        }
                        setSheetState(() => isCreating = true);
                        try {
                          await ref.read(alertsRepositoryProvider).createAlert(
                                symbol: sym,
                                targetPrice: target,
                                condition: condition,
                              );
                          if (!mounted) return;
                          ref.invalidate(alertsListProvider);
                          Navigator.pop(bottomContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Price alert created successfully!')),
                          );
                        } catch (e) {
                          setSheetState(() => isCreating = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to create alert: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'SET ALERT',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAlert(String id) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(alertsRepositoryProvider).deleteAlert(id);
      ref.invalidate(alertsListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete alert: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _toggleAlert(String id) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(alertsRepositoryProvider).toggleAlert(id);
      ref.invalidate(alertsListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update alert: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final query = _searchController.text.trim().toLowerCase();
    final alertsAsync = ref.watch(alertsListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/alerts'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text(
          'Alerts',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: colors.primary, size: 22),
            onPressed: _showAddAlertDialog,
            tooltip: 'Add Alert',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const ZeroMarketHeaderStrip(),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search alerts by symbol...',
                  hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: colors.textSecondary),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 48, color: colors.loss),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load alerts',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(alertsListProvider),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (alerts) {
                var filteredAlerts = alerts;
                if (query.isNotEmpty) {
                  filteredAlerts = alerts.where((a) {
                    return a.instrumentSymbol.toLowerCase().contains(query);
                  }).toList();
                }

                if (filteredAlerts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(alertsListProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        EmptyStateView(
                          icon: LucideIcons.bellOff,
                          title: query.isEmpty ? 'No Price Alerts Set' : 'No Matching Alerts',
                          subtitle: query.isEmpty
                              ? 'Tap the + button to create a real-time price threshold alert.'
                              : 'No alerts found matching "$query"',
                          buttonText: query.isEmpty ? 'Create Alert' : null,
                          onButtonPressed: query.isEmpty ? _showAddAlertDialog : null,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(alertsListProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredAlerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      final isActive = alert.status == AlertStatus.ACTIVE;
                      final condText = alert.condition == AlertCondition.GREATER_THAN_OR_EQUAL
                          ? '>= ${alert.targetValue.toStringAsFixed(2)}'
                          : '<= ${alert.targetValue.toStringAsFixed(2)}';

                      return SectionCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? colors.primary.withValues(alpha: 0.1)
                                    : colors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isActive ? LucideIcons.bell : LucideIcons.bellOff,
                                color: isActive ? colors.primary : colors.textSecondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.instrumentSymbol.isNotEmpty
                                        ? alert.instrumentSymbol
                                        : 'Alert',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Condition: Price $condText',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: _isActionInProgress ? null : (_) => _toggleAlert(alert.id),
                              activeColor: colors.primary,
                            ),
                            IconButton(
                              icon: Icon(LucideIcons.trash2, size: 18, color: colors.loss),
                              onPressed: _isActionInProgress ? null : () => _deleteAlert(alert.id),
                              tooltip: 'Delete Alert',
                            ),
                          ],
                        ),
                      );
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
}
