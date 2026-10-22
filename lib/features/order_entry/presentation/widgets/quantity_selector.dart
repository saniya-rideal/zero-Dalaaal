import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../controllers/order_entry_controller.dart';

class QuantitySelector extends StatefulWidget {
  final OrderEntryState state;
  final ValueChanged<String> onUnitModeChanged;
  final ValueChanged<double> onLotsChanged;
  final VoidCallback onStepLotsUp;
  final VoidCallback onStepLotsDown;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onStepQuantityUp;
  final VoidCallback onStepQuantityDown;
  final void Function(double percent) onApplyRiskPercent;
  final double availableMargin;

  const QuantitySelector({
    super.key,
    required this.state,
    required this.onUnitModeChanged,
    required this.onLotsChanged,
    required this.onStepLotsUp,
    required this.onStepLotsDown,
    required this.onQuantityChanged,
    required this.onStepQuantityUp,
    required this.onStepQuantityDown,
    required this.onApplyRiskPercent,
    required this.availableMargin,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late final TextEditingController _lotCtrl;
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _lotCtrl = TextEditingController(text: widget.state.lots.toStringAsFixed(2));
    _qtyCtrl = TextEditingController(text: widget.state.quantity.toString());
  }

  @override
  void didUpdateWidget(QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (double.tryParse(_lotCtrl.text) != widget.state.lots) {
      _lotCtrl.text = widget.state.lots.toStringAsFixed(2);
    }
    if (int.tryParse(_qtyCtrl.text) != widget.state.quantity) {
      _qtyCtrl.text = widget.state.quantity.toString();
    }
  }

  @override
  void dispose() {
    _lotCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;
    final isLotMode = widget.state.unitMode == 'In Lot';
    final lotSize = widget.state.instrument.lotSize > 0 ? widget.state.instrument.lotSize : 1.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Volume / Size',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Unit Mode Toggle (In Lot / In Quantity)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleItem('In Lot', isLotMode, isDark),
                    _buildToggleItem('In Quantity', !isLotMode, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stepper + Input Field
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
                  onPressed: isLotMode ? widget.onStepLotsDown : widget.onStepQuantityDown,
                  splashRadius: 18,
                ),
                Expanded(
                  child: TextField(
                    controller: isLotMode ? _lotCtrl : _qtyCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) {
                      if (isLotMode) {
                        final parsed = double.tryParse(val) ?? 1.0;
                        widget.onLotsChanged(parsed);
                      } else {
                        final parsed = int.tryParse(val) ?? 1;
                        widget.onQuantityChanged(parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 16),
                  onPressed: isLotMode ? widget.onStepLotsUp : widget.onStepQuantityUp,
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Lot size description & equivalent quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isLotMode
                      ? '= ${widget.state.quantity} shares (Lot Size: ${lotSize.toStringAsFixed(0)})'
                      : '= ${(widget.state.quantity / lotSize).toStringAsFixed(2)} Lots (Lot Size: ${lotSize.toStringAsFixed(0)})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.state.instrument.freezeQty > 0) ...[
                const SizedBox(width: 6),
                Text(
                  'Freeze: ${widget.state.instrument.freezeQty}',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Quick Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('+1', () => widget.onStepQuantityUp(), isDark),
                _buildPresetChip('+5', () {
                  final step = widget.state.instrument.quantityStep;
                  widget.onQuantityChanged(widget.state.quantity + (5 * step));
                }, isDark),
                _buildPresetChip('+10', () {
                  final step = widget.state.instrument.quantityStep;
                  widget.onQuantityChanged(widget.state.quantity + (10 * step));
                }, isDark),
                _buildPresetChip('+25', () {
                  final step = widget.state.instrument.quantityStep;
                  widget.onQuantityChanged(widget.state.quantity + (25 * step));
                }, isDark),
                _buildPresetChip('Max', () {
                  final freeze = widget.state.instrument.freezeQty;
                  if (freeze > 0) widget.onQuantityChanged(freeze);
                }, isDark),
              ],
            ),
          ),

          // Optional Risk % Helper (suggests quantity from SL distance)
          if (widget.state.slPrice > 0 && widget.availableMargin > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 14, color: colors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Risk % Position Sizing (From SL Distance)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [1.0, 2.0, 3.0, 5.0].map((pct) {
                      final isSelected = widget.state.selectedRiskPercent == pct;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => widget.onApplyRiskPercent(pct),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.accent
                                  : (isDark ? const Color(0xFF2C3240) : Colors.white),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? colors.accent
                                    : (isDark ? const Color(0xFF384050) : const Color(0xFFD1D5DB)),
                              ),
                            ),
                            child: Text(
                              '${pct.toStringAsFixed(0)}% Risk',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () => widget.onUnitModeChanged(title),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF2C3240) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
