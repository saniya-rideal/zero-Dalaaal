import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../data/gtt_repository.dart';
import '../../../shared_widgets/shared_widgets.dart';

class GttCreateSheet extends ConsumerStatefulWidget {
  final Instrument? prefilledInstrument;

  const GttCreateSheet({super.key, this.prefilledInstrument});

  static Future<void> show(BuildContext context, {Instrument? instrument}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GttCreateSheet(prefilledInstrument: instrument),
    );
  }

  @override
  ConsumerState<GttCreateSheet> createState() => _GttCreateSheetState();
}

class _GttCreateSheetState extends ConsumerState<GttCreateSheet> {
  late Instrument _instrument;
  TransactionType _side = TransactionType.BUY;
  GttType _type = GttType.SINGLE;
  final int _quantity = 1;
  bool _isSubmitting = false;
  late TextEditingController _triggerPriceController;
  late TextEditingController _orderPriceController;
  late TextEditingController _targetTriggerController;
  late TextEditingController _targetOrderController;

  @override
  void initState() {
    super.initState();
    _instrument = widget.prefilledInstrument ??
        const Instrument(
          token: 'RELIANCE',
          symbol: 'RELIANCE',
          name: 'Reliance Industries',
          exchange: Exchange.NSE,
          type: InstrumentType.EQ,
        );
    _triggerPriceController = TextEditingController(text: '2900.00');
    _orderPriceController = TextEditingController(text: '2900.00');
    _targetTriggerController = TextEditingController(text: '3200.00');
    _targetOrderController = TextEditingController(text: '3200.00');
  }

  @override
  void dispose() {
    _triggerPriceController.dispose();
    _orderPriceController.dispose();
    _targetTriggerController.dispose();
    _targetOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZeroDragHandle(padding: EdgeInsets.zero),
              const SizedBox(height: 16),

              Text('Create GTT Order', style: AppTypography.h1(color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Good-Till-Triggered order remains active until triggered on server quote tick.',
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 16),

              // Instrument Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_instrument.symbol, style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700)),
                          Text('${_instrument.name} • ${_instrument.exchange.name}', style: AppTypography.caption(color: colors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Type: Buy / Sell
              Text('ACTION', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _side = TransactionType.BUY),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _side == TransactionType.BUY ? colors.bullish : colors.surface,
                        foregroundColor: _side == TransactionType.BUY ? Colors.white : colors.textPrimary,
                        elevation: 0,
                      ),
                      child: const Text('BUY'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _side = TransactionType.SELL),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _side == TransactionType.SELL ? colors.bearish : colors.surface,
                        foregroundColor: _side == TransactionType.SELL ? Colors.white : colors.textPrimary,
                        elevation: 0,
                      ),
                      child: const Text('SELL'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Trigger Type: Single vs OCO
              Text('TRIGGER TYPE', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Single (Stoploss or Target)'),
                    selected: _type == GttType.SINGLE,
                    onSelected: (_) => setState(() => _type = GttType.SINGLE),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('OCO (Both)'),
                    selected: _type == GttType.OCO,
                    onSelected: (_) => setState(() => _type = GttType.OCO),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Trigger & Order Price
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRIGGER PRICE', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _triggerPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTypography.body(tabular: true, weight: FontWeight.w600),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LIMIT PRICE', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _orderPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTypography.body(tabular: true, weight: FontWeight.w600),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  if (_isSubmitting) return;
                  setState(() => _isSubmitting = true);

                  try {
                    final repo = ref.read(gttRepositoryProvider);
                    final triggerPrice = double.tryParse(_triggerPriceController.text) ?? 0.0;
                    final orderPrice = double.tryParse(_orderPriceController.text) ?? 0.0;

                    // Contract Section 8.1: POST /api/gtt
                    await repo.createGtt(
                      symbol: _instrument.symbol,
                      market: 'INDIAN',
                      condition: _side == TransactionType.BUY ? 'LTE' : 'GTE',
                      triggerPrice: triggerPrice,
                      orderSide: _side.name,
                      orderType: 'LIMIT',
                      price: orderPrice,
                      quantity: _quantity,
                      leverage: 1,
                    );

                    ref.invalidate(gttsListProvider);

                    if (mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('GTT Created Successfully!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create GTT: $e'),
                          backgroundColor: colors.bearish,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('CREATE GTT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
