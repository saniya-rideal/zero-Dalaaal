import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/quote.dart';
import '../controllers/order_entry_controller.dart';

class BidAskActionBar extends StatelessWidget {
  final OrderEntryState state;
  final Quote? quote;
  final void Function(TransactionType side) onPlaceSide;

  const BidAskActionBar({
    super.key,
    required this.state,
    required this.quote,
    required this.onPlaceSide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ltp = quote?.ltp ?? 0.0;
    final bid = quote?.bid ?? ltp;
    final ask = quote?.ask ?? ltp;
    final hasBidAsk = quote?.hasBidAsk ?? false;
    final spread = quote?.spread ?? 0.0;

    final isSubmitting = state.isSubmitting;
    final canPlace = state.canPlaceOrder && !isSubmitting;
    final blockingReason = state.blockingReason;

    final colors = context.tradingColors;

    // Label on buttons depending on Market or Pending
    final sellLabel = state.isMarketOrder
        ? 'SELL'
        : (state.pendingType.contains('Stop') ? 'SELL STOP' : 'SELL LIMIT');
    final buyLabel = state.isMarketOrder
        ? 'BUY'
        : (state.pendingType.contains('Stop') ? 'BUY STOP' : 'BUY LIMIT');

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 6
            : 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF282D37) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live spread indicator chip
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hasBidAsk
                        ? 'Spread: ${spread.toStringAsFixed(2)} pts'
                        : 'LTP: ${CurrencyFormatter.formatInr(ltp)} (No Depth)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Two Big Tappable Action Buttons (SELL and BUY)
          Row(
            children: [
              // SELL BUTTON (Bid price)
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPlace
                          ? colors.bearish
                          : (isDark ? const Color(0xFF2A2E39) : const Color(0xFFE5E7EB)),
                      foregroundColor: Colors.white,
                      elevation: canPlace ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: canPlace ? () => onPlaceSide(TransactionType.SELL) : null,
                    child: isSubmitting && state.side == TransactionType.SELL
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                sellLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: canPlace
                                      ? Colors.white
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                CurrencyFormatter.formatInr(bid),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: canPlace
                                      ? Colors.white
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // BUY BUTTON (Ask price)
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPlace
                          ? colors.bullish
                          : (isDark ? const Color(0xFF2A2E39) : const Color(0xFFE5E7EB)),
                      foregroundColor: Colors.white,
                      elevation: canPlace ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: canPlace ? () => onPlaceSide(TransactionType.BUY) : null,
                    child: isSubmitting && state.side == TransactionType.BUY
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                buyLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: canPlace
                                      ? Colors.white
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                CurrencyFormatter.formatInr(ask),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: canPlace
                                      ? Colors.white
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),

          // Blocking Reason Banner below buttons if disabled
          if (!canPlace && blockingReason != null) ...[
            const SizedBox(height: 6),
            Text(
              blockingReason,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.bearish,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
