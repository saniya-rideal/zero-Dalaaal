import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/mock/order_simulation_engine.dart';
import '../../../data/mock/ticker_service.dart';
import '../../../data/models/enums.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/exchange_chip.dart';
import '../../../shared_widgets/margin_risk_banner.dart';
import '../../../shared_widgets/section_card.dart';
import 'position_action_sheets.dart';

enum PositionFilterType { all, profitable, losing }

class PositionsScreen extends ConsumerStatefulWidget {
  const PositionsScreen({super.key});

  @override
  ConsumerState<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends ConsumerState<PositionsScreen> {
  bool _isDayView = true;
  PositionFilterType _statusFilter = PositionFilterType.all;

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final engine = ref.watch(orderSimulationEngineProvider);
    final tickerService = ref.watch(tickerServiceProvider);
    
    final positionsAsync = ref.watch(positionsListProvider);
    final allPositions = positionsAsync.value ?? engine.positions;

    final basePositions = _isDayView
        ? allPositions.where((p) => p.isDayPosition).toList()
        : allPositions;

    // Attach latest tick prices and compute PnL metrics
    final positionsWithMeta = basePositions.map((p) {
      final quote = tickerService.getQuote(p.instrument.token);
      final posWithLtp = p.copyWith(ltp: quote.ltp);
      final pnl = posWithLtp.realizedPnl + posWithLtp.unrealizedPnl;
      return (position: posWithLtp, pnl: pnl);
    }).toList();

    double totalPnl = 0.0;
    int profitableCount = 0;
    double profitablePnl = 0.0;
    int losingCount = 0;
    double losingPnl = 0.0;

    for (final item in positionsWithMeta) {
      totalPnl += item.pnl;
      if (item.pnl > 0) {
        profitableCount++;
        profitablePnl += item.pnl;
      } else if (item.pnl < 0) {
        losingCount++;
        losingPnl += item.pnl;
      }
    }

    final filteredPositions = positionsWithMeta.where((item) {
      switch (_statusFilter) {
        case PositionFilterType.all:
          return true;
        case PositionFilterType.profitable:
          return item.pnl > 0;
        case PositionFilterType.losing:
          return item.pnl < 0;
      }
    }).toList();

    final pnlColor = totalPnl >= 0 ? colors.bullish : colors.bearish;

    return Scaffold(
      appBar: AppBar(
        title: Text('Positions', style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700)),
        actions: [
          // Day vs Net Toggle Chip
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ChoiceChip(
              label: Text(_isDayView ? 'Day View' : 'Net View', style: AppTypography.labelSmall(weight: FontWeight.w600)),
              selected: true,
              selectedColor: colors.surface,
              onSelected: (_) => setState(() => _isDayView = !_isDayView),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Margin Risk Alert Banner (High Margin, Margin Call, Forced Liquidation)
          const MarginRiskBanner(segment: Segment.EQUITY),

          // Summary Header Card
          SectionCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total P&L', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatSigned(totalPnl),
                      style: AppTypography.h1(color: pnlColor, weight: FontWeight.w700, tabular: true),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${basePositions.length} Open Positions',
                      style: AppTypography.caption(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$profitableCount in profit • $losingCount in loss',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profitable vs Losing Filter Chips
          if (basePositions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      'All (${positionsWithMeta.length})',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    selected: _statusFilter == PositionFilterType.all,
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = PositionFilterType.all);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colors.bullish,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$profitableCount In Profit (${CurrencyFormatter.formatSigned(profitablePnl)})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusFilter == PositionFilterType.profitable ? colors.bullish : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    selected: _statusFilter == PositionFilterType.profitable,
                    selectedColor: colors.bullish.withValues(alpha: 0.18),
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = PositionFilterType.profitable);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colors.bearish,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$losingCount In Loss (${CurrencyFormatter.formatSigned(losingPnl)})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusFilter == PositionFilterType.losing ? colors.bearish : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    selected: _statusFilter == PositionFilterType.losing,
                    selectedColor: colors.bearish.withValues(alpha: 0.18),
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = PositionFilterType.losing);
                    },
                  ),
                ],
              ),
            ),

          // Positions List
          Expanded(
            child: basePositions.isEmpty
                ? EmptyStateView(
                    icon: LucideIcons.layers,
                    title: 'No Open Positions',
                    subtitle: 'You do not have any active intraday or F&O positions for today.',
                    buttonText: 'Trade Now',
                    onButtonPressed: () => context.go('/watchlist'),
                  )
                : filteredPositions.isEmpty
                    ? EmptyStateView(
                        icon: _statusFilter == PositionFilterType.profitable
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        title: _statusFilter == PositionFilterType.profitable
                            ? 'No Profitable Positions'
                            : 'No Losing Positions',
                        subtitle: _statusFilter == PositionFilterType.profitable
                            ? 'None of your open positions currently have an unrealized gain.'
                            : 'None of your open positions currently have an unrealized loss.',
                        buttonText: 'Show All Positions',
                        onButtonPressed: () =>
                            setState(() => _statusFilter = PositionFilterType.all),
                      )
                    : ListView.separated(
                        itemCount: filteredPositions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filteredPositions[index];
                          final posWithLtp = item.position;
                          final itemPnl = item.pnl;
                          final itemPnlColor =
                              itemPnl >= 0 ? colors.bullish : colors.bearish;
                          final currentPrice = posWithLtp.ltp;
                          final pos = posWithLtp;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () => PositionActionSheets.showFullOptions(
                            context,
                            posWithLtp,
                            engine,
                            onRefresh: () => setState(() {}),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (posWithLtp.isLong
                                          ? colors.bullish
                                          : colors.bearish)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  posWithLtp.isLong ? 'LONG' : 'SHORT',
                                  style: GoogleFonts.inter(
                                    color: posWithLtp.isLong
                                        ? colors.bullish
                                        : colors.bearish,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pos.instrument.symbol,
                                style: GoogleFonts.inter(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              ExchangeChip(
                                  exchange: pos.instrument.exchange,
                                  type: pos.instrument.type),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${pos.leverage.toInt()}x ${pos.product.name}',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${pos.netQty.abs()} • Entry: ${CurrencyFormatter.format(pos.entryPrice)} • LTP: ${CurrencyFormatter.format(currentPrice)}',
                                style: GoogleFonts.inter(
                                    color: colors.textSecondary,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    pos.stopLoss != null
                                        ? 'SL: ₹${pos.stopLoss!.toStringAsFixed(2)}'
                                        : 'SL: --',
                                    style: GoogleFonts.inter(
                                        color: colors.textSecondary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    pos.takeProfit != null
                                        ? 'TP: ₹${pos.takeProfit!.toStringAsFixed(2)}'
                                        : 'TP: --',
                                    style: GoogleFonts.inter(
                                        color: colors.textSecondary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Margin: ${CurrencyFormatter.format(pos.usedMargin)}',
                                    style: GoogleFonts.inter(
                                        color: colors.textSecondary
                                            .withValues(alpha: 0.8),
                                        fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatSigned(
                                        itemPnl,
                                        showSymbol: true),
                                    style: GoogleFonts.inter(
                                      color: itemPnlColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (posWithLtp.pnlPercent >= 0
                                              ? colors.bullish
                                              : colors.bearish)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${posWithLtp.pnlPercent >= 0 ? '+' : ''}${posWithLtp.pnlPercent.toStringAsFixed(2)}%',
                                      style: GoogleFonts.inter(
                                        color: posWithLtp.pnlPercent >= 0
                                            ? colors.bullish
                                            : colors.bearish,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(LucideIcons.chevronRight,
                                  color: colors.textSecondary, size: 18),
                            ],
                          ),
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

