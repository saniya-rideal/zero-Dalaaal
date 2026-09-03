import 'package:flutter/material.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../domain/indicator.dart';

class IndicatorPickerSheet extends StatefulWidget {
  final List<IndicatorConfig> currentConfigs;
  final ValueChanged<List<IndicatorConfig>> onApply;

  const IndicatorPickerSheet({
    super.key,
    required this.currentConfigs,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required List<IndicatorConfig> currentConfigs,
    required ValueChanged<List<IndicatorConfig>> onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => IndicatorPickerSheet(
        currentConfigs: currentConfigs,
        onApply: onApply,
      ),
    );
  }

  @override
  State<IndicatorPickerSheet> createState() => _IndicatorPickerSheetState();
}

class _IndicatorPickerSheetState extends State<IndicatorPickerSheet> {
  final _searchController = TextEditingController();
  late List<IndicatorConfig> _configs;

  @override
  void initState() {
    super.initState();
    _configs = List.from(widget.currentConfigs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isTypeEnabled(IndicatorType type) {
    return _configs.any((c) => c.type == type && c.isEnabled);
  }

  IndicatorConfig _getConfig(IndicatorType type) {
    return _configs.firstWhere(
      (c) => c.type == type,
      orElse: () => IndicatorConfig(type: type, isEnabled: true),
    );
  }

  void _toggleType(IndicatorType type) {
    setState(() {
      final index = _configs.indexWhere((c) => c.type == type);
      if (index != -1) {
        final cur = _configs[index];
        _configs[index] = cur.copyWith(isEnabled: !cur.isEnabled);
      } else {
        _configs.add(IndicatorConfig(type: type, isEnabled: true));
      }
    });
    widget.onApply(_configs);
  }

  void _showSettingsDialog(IndicatorType type, TradingColors colors) {
    final config = _getConfig(type);
    final periodCtrl = TextEditingController(text: config.period.toString());
    final stdDevCtrl = TextEditingController(text: config.stdDev.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('${type.shortName} Parameters', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: periodCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Period / Lookback',
                labelStyle: TextStyle(color: colors.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
            if (type == IndicatorType.BOLLINGER) ...[
              const SizedBox(height: 12),
              TextField(
                controller: stdDevCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'StdDev Multiplier',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final newPeriod = int.tryParse(periodCtrl.text) ?? config.period;
              final newStdDev = double.tryParse(stdDevCtrl.text) ?? config.stdDev;
              setState(() {
                final index = _configs.indexWhere((c) => c.type == type);
                final updated = config.copyWith(period: newPeriod, stdDev: newStdDev, isEnabled: true);
                if (index != -1) {
                  _configs[index] = updated;
                } else {
                  _configs.add(updated);
                }
              });
              widget.onApply(_configs);
              Navigator.pop(dialogCtx);
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final query = _searchController.text.trim().toLowerCase();

    final allTypes = IndicatorType.values.where((t) {
      if (query.isEmpty) return true;
      return t.shortName.toLowerCase().contains(query) ||
          t.fullName.toLowerCase().contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Studies & Indicators',
                  style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search indicators (SMA, RSI, MACD, Stoch, ATR...)',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.divider),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Indicators List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: ListView.separated(
              itemCount: allTypes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final type = allTypes[index];
                final isEnabled = _isTypeEnabled(type);
                final config = _getConfig(type);

                return ListTile(
                  leading: Checkbox(
                    value: isEnabled,
                    activeColor: colors.primary,
                    onChanged: (_) => _toggleType(type),
                  ),
                  title: Text(
                    type.fullName,
                    style: AppTypography.body(
                      color: colors.textPrimary,
                      weight: isEnabled ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${type.isOverlay ? 'Overlay' : 'Oscillator'} • Period: ${config.period}',
                    style: AppTypography.caption(color: colors.textSecondary),
                  ),
                  trailing: isEnabled
                      ? IconButton(
                          icon: Icon(Icons.tune, size: 20, color: colors.primary),
                          onPressed: () => _showSettingsDialog(type, colors),
                          tooltip: 'Edit Parameters',
                        )
                      : null,
                  onTap: () => _toggleType(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
