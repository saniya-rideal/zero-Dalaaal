import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/market_status_service.dart';
import '../core/theme/trading_colors.dart';

class MarketStatusStrip extends StatelessWidget {
  const MarketStatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final nseStatus = MarketStatusService.getStatusForExchange('NSE');
    final mcxStatus = MarketStatusService.getStatusForExchange('MCX');

    return InkWell(
      onTap: () => _showSessionScheduleSheet(context, colors),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        color: colors.background,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // NSE / BSE Status Pill
              Row(
                children: [
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: BoxDecoration(
                      color: nseStatus.badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    nseStatus.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: nseStatus.badgeColor,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // MCX Status Pill
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: BoxDecoration(
                      color: mcxStatus.badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    mcxStatus.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: mcxStatus.badgeColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Time-Zone Tag & Info Icon
              Row(
                children: [
                  Text(
                    MarketStatusService.timeZoneLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionScheduleSheet(BuildContext context, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Market Sessions & Timings',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildTimingRow(
                exchange: 'NSE / BSE Equity & Derivatives',
                hours: '09:15 AM - 03:30 PM IST',
                session: 'Regular Trading (Pre-open: 09:00 - 09:15)',
                colors: colors,
                isOpen: MarketStatusService.getStatusForExchange('NSE').state ==
                    MarketSessionState.open,
              ),
              const Divider(height: 16),

              _buildTimingRow(
                exchange: 'MCX Commodity Derivatives',
                hours: '09:00 AM - 11:30 PM IST',
                session: 'Evening Session (Summer: closes 11:30 PM / Winter: 11:55 PM)',
                colors: colors,
                isOpen: MarketStatusService.getStatusForExchange('MCX').state ==
                    MarketSessionState.open,
              ),
              const Divider(height: 16),

              _buildTimingRow(
                exchange: 'Currency Derivatives (CDS)',
                hours: '09:00 AM - 05:00 PM IST',
                session: 'Forex Pairs (USDINR, EURINR, GBPINR, JPYINR)',
                colors: colors,
                isOpen: false,
              ),
              const Divider(height: 16),

              _buildTimingRow(
                exchange: 'Global Crypto & Indices',
                hours: '24 Hours x 7 Days',
                session: 'Continuous Spot & Futures Feed',
                colors: colors,
                isOpen: true,
              ),
              const SizedBox(height: 20),

              // Timezone explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: colors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All market timestamps and settlement logs conform to Indian Standard Time (IST, UTC+05:30).',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingRow({
    required String exchange,
    required String hours,
    required String session,
    required TradingColors colors,
    required bool isOpen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              exchange,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (isOpen ? const Color(0xFF00A854) : const Color(0xFFC62828))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isOpen ? 'OPEN' : 'CLOSED',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isOpen ? const Color(0xFF00A854) : const Color(0xFFC62828),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          hours,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          session,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
