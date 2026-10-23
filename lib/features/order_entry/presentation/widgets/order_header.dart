import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/realtime_quote_service.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/instrument.dart';
import '../../../../data/models/quote.dart';
import '../../../../shared_widgets/quote_status_badge.dart';
import '../../../market/data/real_market_repository.dart';

class OrderHeader extends ConsumerWidget {
  final Instrument instrument;
  final ValueChanged<Instrument> onInstrumentSelected;

  const OrderHeader({
    super.key,
    required this.instrument,
    required this.onInstrumentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;
    final quoteAsync = ref.watch(quoteDetailStreamProvider(instrument.symbol));
    final quote = quoteAsync.valueOrNull;

    final ltp = quote?.ltp ?? 0.0;
    final change = quote?.change ?? 0.0;
    final changePct = quote?.changePercent ?? 0.0;
    final isBullish = change >= 0;
    final changeColor = isBullish ? colors.bullish : colors.bearish;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF282D37) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              // Instrument Selector
              Expanded(
                child: InkWell(
                  onTap: () => _showInstrumentPicker(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      instrument.symbol,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF252B37) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      instrument.exchange.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 14,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                instrument.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Quote Price & Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatInr(ltp),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isBullish ? '+' : ''}${change.toStringAsFixed(2)} (${isBullish ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: changeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      QuoteStatusBadge(status: quote?.status ?? QuoteStatus.live),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInstrumentPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InstrumentPickerSheet(
        currentInstrument: instrument,
        onSelected: (selected) {
          Navigator.of(ctx).pop();
          onInstrumentSelected(selected);
        },
      ),
    );
  }
}

class InstrumentPickerSheet extends ConsumerStatefulWidget {
  final Instrument currentInstrument;
  final ValueChanged<Instrument> onSelected;

  const InstrumentPickerSheet({
    super.key,
    required this.currentInstrument,
    required this.onSelected,
  });

  @override
  ConsumerState<InstrumentPickerSheet> createState() => _InstrumentPickerSheetState();
}

class _InstrumentPickerSheetState extends ConsumerState<InstrumentPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;
    final instrumentsAsync = ref.watch(cachedInstrumentsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Select Instrument',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onChanged: (val) => setState(() => _query = val.trim().toUpperCase()),
              decoration: InputDecoration(
                hintText: 'Search stock, future, index (e.g. RELIANCE, NIFTY)',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F242F) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: instrumentsAsync.when(
              data: (instruments) {
                final filtered = _query.isEmpty
                    ? instruments
                    : instruments.where((inst) {
                        return inst.symbol.toUpperCase().contains(_query) ||
                            inst.name.toUpperCase().contains(_query);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No instruments match "$_query"',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF282D37) : const Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, idx) {
                    final inst = filtered[idx];
                    final isCurrent = inst.symbol == widget.currentInstrument.symbol;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        inst.symbol,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isCurrent
                              ? colors.accent
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      subtitle: Text(
                        inst.name,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252B37) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inst.exchange.name,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Icon(LucideIcons.check, size: 16, color: colors.accent),
                          ],
                        ],
                      ),
                      onTap: () => widget.onSelected(inst),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Failed to load instruments: $err', style: GoogleFonts.inter(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
