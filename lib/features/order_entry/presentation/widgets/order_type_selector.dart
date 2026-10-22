import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../data/models/quote.dart';
import '../controllers/order_entry_controller.dart';

class OrderTypeSelector extends StatefulWidget {
  final OrderEntryState state;
  final Quote? quote;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPendingTypeChanged;
  final ValueChanged<double> onLimitPriceChanged;
  final VoidCallback onStepLimitPriceUp;
  final VoidCallback onStepLimitPriceDown;
  final VoidCallback onUseCurrentPriceForLimit;
  final ValueChanged<double> onTriggerPriceChanged;
  final VoidCallback onStepTriggerPriceUp;
  final VoidCallback onStepTriggerPriceDown;
  final VoidCallback onUseCurrentPriceForTrigger;

  const OrderTypeSelector({
    super.key,
    required this.state,
    required this.quote,
    required this.onCategoryChanged,
    required this.onPendingTypeChanged,
    required this.onLimitPriceChanged,
    required this.onStepLimitPriceUp,
    required this.onStepLimitPriceDown,
    required this.onUseCurrentPriceForLimit,
    required this.onTriggerPriceChanged,
    required this.onStepTriggerPriceUp,
    required this.onStepTriggerPriceDown,
    required this.onUseCurrentPriceForTrigger,
  });

  @override
  State<OrderTypeSelector> createState() => _OrderTypeSelectorState();
}

class _OrderTypeSelectorState extends State<OrderTypeSelector> {
  late final TextEditingController _limitCtrl;
  late final TextEditingController _triggerCtrl;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(
      text: widget.state.limitPrice > 0 ? widget.state.limitPrice.toStringAsFixed(2) : '',
    );
    _triggerCtrl = TextEditingController(
      text: widget.state.triggerPrice > 0 ? widget.state.triggerPrice.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(OrderTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.limitPrice > 0 &&
        double.tryParse(_limitCtrl.text) != widget.state.limitPrice) {
      _limitCtrl.text = widget.state.limitPrice.toStringAsFixed(2);
    } else if (widget.state.limitPrice == 0 && _limitCtrl.text.isNotEmpty) {
      _limitCtrl.text = '';
    }

    if (widget.state.triggerPrice > 0 &&
        double.tryParse(_triggerCtrl.text) != widget.state.triggerPrice) {
      _triggerCtrl.text = widget.state.triggerPrice.toStringAsFixed(2);
    } else if (widget.state.triggerPrice == 0 && _triggerCtrl.text.isNotEmpty) {
      _triggerCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _triggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;

    final isMarket = widget.state.orderCategory == 'Market';
    final pendingTypes = [
      'Buy Limit',
      'Sell Limit',
      'Buy Stop',
      'Sell Stop',
      'Stop-Limit',
    ];

    final isLimitMode = widget.state.pendingType.contains('Limit');
    final isStopMode = widget.state.pendingType.contains('Stop');
    final isStopLimit = widget.state.pendingType == 'Stop-Limit';

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
          // Market vs Pending Tabs
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onCategoryChanged('Market'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isMarket
                            ? (isDark ? const Color(0xFF2C3240) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isMarket
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Market Execution',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isMarket ? FontWeight.w700 : FontWeight.w500,
                            color: isMarket
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onCategoryChanged('Pending'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !isMarket
                            ? (isDark ? const Color(0xFF2C3240) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: !isMarket
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Pending Order',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: !isMarket ? FontWeight.w700 : FontWeight.w500,
                            color: !isMarket
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isMarket) ...[
            const SizedBox(height: 12),
            // Pending Order Type Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pendingTypes.map((type) {
                  final isSelected = widget.state.pendingType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        type,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? colors.accent
                              : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB)),
                        ),
                      ),
                      onSelected: (_) => widget.onPendingTypeChanged(type),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Trigger Price Field (for Stop or Stop-Limit)
            if (isStopMode || isStopLimit) ...[
              _buildPriceInputField(
                context,
                title: 'Trigger Price',
                controller: _triggerCtrl,
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  widget.onTriggerPriceChanged(parsed);
                },
                onStepUp: widget.onStepTriggerPriceUp,
                onStepDown: widget.onStepTriggerPriceDown,
                onUseCurrent: widget.onUseCurrentPriceForTrigger,
                tickSize: widget.state.instrument.tickSize,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
            ],

            // Limit Price Field (for Limit or Stop-Limit)
            if (isLimitMode || isStopLimit) ...[
              _buildPriceInputField(
                context,
                title: 'Limit Price',
                controller: _limitCtrl,
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  widget.onLimitPriceChanged(parsed);
                },
                onStepUp: widget.onStepLimitPriceUp,
                onStepDown: widget.onStepLimitPriceDown,
                onUseCurrent: widget.onUseCurrentPriceForLimit,
                tickSize: widget.state.instrument.tickSize,
                isDark: isDark,
              ),
            ],
          ],

          // Direction validation inline error message
          if (widget.state.directionValidationError != null &&
              widget.state.directionValidationError!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bearish.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.bearish.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, size: 16, color: colors.bearish),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.state.directionValidationError!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.bearish,
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
  }

  Widget _buildPriceInputField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onStepUp,
    required VoidCallback onStepDown,
    required VoidCallback onUseCurrent,
    required double tickSize,
    required bool isDark,
  }) {
    final colors = context.tradingColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              ),
            ),
            InkWell(
              onTap: onUseCurrent,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Use current price',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.minus, size: 16),
                onPressed: onStepDown,
                splashRadius: 18,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.jetBrainsMono(fontSize: 16, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: onChanged,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 16),
                onPressed: onStepUp,
                splashRadius: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
