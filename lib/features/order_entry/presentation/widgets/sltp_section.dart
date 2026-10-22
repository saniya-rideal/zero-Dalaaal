import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/quote.dart';
import '../controllers/order_entry_controller.dart';

class SltpSection extends StatefulWidget {
  final OrderEntryState state;
  final Quote? quote;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<double> onSlPriceChanged;
  final VoidCallback onClearSl;
  final ValueChanged<double> onTpPriceChanged;
  final VoidCallback onClearTp;

  const SltpSection({
    super.key,
    required this.state,
    required this.quote,
    required this.onModeChanged,
    required this.onSlPriceChanged,
    required this.onClearSl,
    required this.onTpPriceChanged,
    required this.onClearTp,
  });

  @override
  State<SltpSection> createState() => _SltpSectionState();
}

class _SltpSectionState extends State<SltpSection> {
  late final TextEditingController _slCtrl;
  late final TextEditingController _tpCtrl;

  @override
  void initState() {
    super.initState();
    _slCtrl = TextEditingController(
      text: widget.state.slPrice > 0 ? widget.state.slPrice.toStringAsFixed(2) : '',
    );
    _tpCtrl = TextEditingController(
      text: widget.state.tpPrice > 0 ? widget.state.tpPrice.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(SltpSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.slPrice > 0 && double.tryParse(_slCtrl.text) != widget.state.slPrice) {
      _slCtrl.text = widget.state.slPrice.toStringAsFixed(2);
    } else if (widget.state.slPrice == 0 && _slCtrl.text.isNotEmpty) {
      _slCtrl.text = '';
    }

    if (widget.state.tpPrice > 0 && double.tryParse(_tpCtrl.text) != widget.state.tpPrice) {
      _tpCtrl.text = widget.state.tpPrice.toStringAsFixed(2);
    } else if (widget.state.tpPrice == 0 && _tpCtrl.text.isNotEmpty) {
      _tpCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _slCtrl.dispose();
    _tpCtrl.dispose();
    super.dispose();
  }

  double get _effectiveEntryPrice {
    if (widget.state.limitPrice > 0) return widget.state.limitPrice;
    if (widget.state.triggerPrice > 0) return widget.state.triggerPrice;
    final q = widget.quote;
    if (q == null) return 100.0;
    return widget.state.side == TransactionType.BUY ? (q.ask ?? q.ltp) : (q.bid ?? q.ltp);
  }

  double get _projectedSlPnl {
    if (widget.state.slPrice <= 0) return 0.0;
    final entry = _effectiveEntryPrice;
    final qty = widget.state.quantity * widget.state.instrument.contractMultiplier;
    if (widget.state.side == TransactionType.BUY) {
      return (widget.state.slPrice - entry) * qty;
    } else {
      return (entry - widget.state.slPrice) * qty;
    }
  }

  double get _projectedTpPnl {
    if (widget.state.tpPrice <= 0) return 0.0;
    final entry = _effectiveEntryPrice;
    final qty = widget.state.quantity * widget.state.instrument.contractMultiplier;
    if (widget.state.side == TransactionType.BUY) {
      return (widget.state.tpPrice - entry) * qty;
    } else {
      return (entry - widget.state.tpPrice) * qty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;
    final isAtPrice = widget.state.sltpMode == 'At Price';

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
                  'Stop Loss & Take Profit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // At Price / At Value toggle
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleItem('At Price', isAtPrice, isDark),
                    _buildToggleItem('At Value', !isAtPrice, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stop Loss Row
          _buildSltpRow(
            context,
            label: 'Stop Loss',
            controller: _slCtrl,
            color: colors.bearish,
            icon: LucideIcons.shieldAlert,
            projectedPnl: _projectedSlPnl,
            hasValue: widget.state.slPrice > 0,
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              if (isAtPrice) {
                widget.onSlPriceChanged(parsed);
              } else {
                final entry = _effectiveEntryPrice;
                final price = widget.state.side == TransactionType.BUY
                    ? (entry - parsed)
                    : (entry + parsed);
                widget.onSlPriceChanged(price > 0 ? price : 0.0);
              }
            },
            onClear: () {
              _slCtrl.clear();
              widget.onClearSl();
            },
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Take Profit Row
          _buildSltpRow(
            context,
            label: 'Take Profit',
            controller: _tpCtrl,
            color: colors.bullish,
            icon: LucideIcons.trendingUp,
            projectedPnl: _projectedTpPnl,
            hasValue: widget.state.tpPrice > 0,
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              if (isAtPrice) {
                widget.onTpPriceChanged(parsed);
              } else {
                final entry = _effectiveEntryPrice;
                final price = widget.state.side == TransactionType.BUY
                    ? (entry + parsed)
                    : (entry - parsed);
                widget.onTpPriceChanged(price > 0 ? price : 0.0);
              }
            },
            onClear: () {
              _tpCtrl.clear();
              widget.onClearTp();
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSltpRow(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required Color color,
    required IconData icon,
    required double projectedPnl,
    required bool hasValue,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
    required bool isDark,
  }) {
    final rowColors = context.tradingColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            if (hasValue) ...[
              Row(
                children: [
                  Text(
                    'Est. P&L: ${projectedPnl >= 0 ? '+' : ''}${CurrencyFormatter.formatInr(projectedPnl)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: projectedPnl >= 0 ? rowColors.bullish : rowColors.bearish,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClear,
                    child: const Icon(LucideIcons.xCircle, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue
                  ? color.withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Text(
                '₹',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.state.sltpMode == 'At Price' ? 'Target Price' : 'Points / Value',
                    hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem(String title, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () => widget.onModeChanged(title),
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
}
