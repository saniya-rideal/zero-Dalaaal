import 'package:flutter/material.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import '../data/mock/seed_instruments.dart';
import '../data/models/instrument.dart';

class ScriptSelectorBar extends StatefulWidget {
  final Instrument? leftScript;
  final Instrument? rightScript;
  final ValueChanged<Instrument>? onLeftScriptChanged;
  final ValueChanged<Instrument>? onRightScriptChanged;

  const ScriptSelectorBar({
    super.key,
    this.leftScript,
    this.rightScript,
    this.onLeftScriptChanged,
    this.onRightScriptChanged,
  });

  @override
  State<ScriptSelectorBar> createState() => _ScriptSelectorBarState();
}

class _ScriptSelectorBarState extends State<ScriptSelectorBar> {
  Instrument? _left;
  Instrument? _right;

  @override
  void initState() {
    super.initState();
    _left = widget.leftScript;
    _right = widget.rightScript;
  }

  void _openScriptPicker(bool isLeft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final colors = context.tradingColors;
        final allScripts = SeedInstruments.all;
        String pickerQuery = '';

        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            final filtered = pickerQuery.isEmpty
                ? allScripts
                : allScripts
                    .where((s) =>
                        s.symbol.toLowerCase().contains(pickerQuery.toLowerCase()) ||
                        s.name.toLowerCase().contains(pickerQuery.toLowerCase()))
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        isLeft ? 'Select Left Quick Script' : 'Select Right Quick Script',
                        style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.divider),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search script to bind...',
                            prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() => pickerQuery = val);
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final script = filtered[index];
                          return ListTile(
                            title: Text(script.symbol, style: AppTypography.body(weight: FontWeight.w600)),
                            subtitle: Text('${script.name} • ${script.exchange.name}', style: AppTypography.caption(color: colors.textSecondary)),
                            trailing: Icon(Icons.add_circle_outline, color: colors.secondary),
                            onTap: () {
                              setState(() {
                                if (isLeft) {
                                  _left = script;
                                  widget.onLeftScriptChanged?.call(script);
                                } else {
                                  _right = script;
                                  widget.onRightScriptChanged?.call(script);
                                }
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: colors.background,
      child: Row(
        children: [
          // Left Script Button
          Expanded(
            child: _buildScriptButton(
              script: _left,
              onTap: () => _openScriptPicker(true),
              colors: colors,
            ),
          ),
          const SizedBox(width: 8),
          // Right Script Button
          Expanded(
            child: _buildScriptButton(
              script: _right,
              onTap: () => _openScriptPicker(false),
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptButton({
    required Instrument? script,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.scriptBarBackground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                script?.symbol ?? 'Press and hold to select script',
                style: AppTypography.labelSmall(
                  color: colors.textPrimary,
                  weight: script != null ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
