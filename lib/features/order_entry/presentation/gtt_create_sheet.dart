import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/realtime_quote_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../market/data/real_market_repository.dart';
import '../data/gtt_repository.dart';

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
    final cached = ref.read(cachedInstrumentsProvider).value;
    _instrument = widget.prefilledInstrument ??
        (cached != null && cached.isNotEmpty
            ? cached.first
            : const Instrument(
                token: 'NIFTY',
                symbol: 'NIFTY',
                name: 'Nifty 50 Index',
                exchange: Exchange.NSE,
                type: InstrumentType.INDEX,
              ));

    final initialPrice = ref.read(quoteDetailStreamProvider(_instrument.symbol)).value?.ltp ?? 0.0;
    final priceStr = initialPrice > 0 ? initialPrice.toStringAsFixed(2) : '';
    final targetStr = initialPrice > 0 ? (initialPrice * 1.05).toStringAsFixed(2) : '';

    _triggerPriceController = TextEditingController(text: priceStr);
    _orderPriceController = TextEditingController(text: priceStr);
    _targetTriggerController = TextEditingController(text: targetStr);
    _targetOrderController = TextEditingController(text: targetStr);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialPrice <= 0) {
        final liveQuote = ref.read(quoteDetailStreamProvider(_instrument.symbol)).value;
        if (liveQuote != null && liveQuote.ltp > 0) {
          _triggerPriceController.text = liveQuote.ltp.toStringAsFixed(2);
          _orderPriceController.text = liveQuote.ltp.toStringAsFixed(2);
          _targetTriggerController.text = (liveQuote.ltp * 1.05).toStringAsFixed(2);
          _targetOrderController.text = (liveQuote.ltp * 1.05).toStringAsFixed(2);
        }
      }
    });
  }

  void _onSelectInstrument(Instrument newInst) {
    setState(() {
      _instrument = newInst;
    });
    final quote = ref.read(quoteDetailStreamProvider(newInst.symbol)).value;
    if (quote != null && quote.ltp > 0) {
      _triggerPriceController.text = quote.ltp.toStringAsFixed(2);
      _orderPriceController.text = quote.ltp.toStringAsFixed(2);
      _targetTriggerController.text = (quote.ltp * 1.05).toStringAsFixed(2);
      _targetOrderController.text = (quote.ltp * 1.05).toStringAsFixed(2);
    }
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

              // Instrument Details (Tappable to pick instrument)
              InkWell(
                onTap: () => _showInstrumentPicker(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_instrument.symbol, style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                Icon(LucideIcons.chevronDown, size: 14, color: colors.textSecondary),
                              ],
                            ),
                            Text('${_instrument.name} • ${_instrument.exchange.name}', style: AppTypography.caption(color: colors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
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

              // GTT Type: Single vs OCO
              Text('TYPE', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _type = GttType.SINGLE),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _type == GttType.SINGLE ? colors.primary : colors.divider),
                        backgroundColor: _type == GttType.SINGLE ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        foregroundColor: colors.textPrimary,
                      ),
                      child: const Text('Single Trigger'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _type = GttType.OCO),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _type == GttType.OCO ? colors.primary : colors.divider),
                        backgroundColor: _type == GttType.OCO ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        foregroundColor: colors.textPrimary,
                      ),
                      child: const Text('OCO (Stop-loss & Target)'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Primary Trigger & Order Price
              Text(
                _type == GttType.OCO ? 'STOP-LOSS LEG' : 'TRIGGER PARAMETERS',
                style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _triggerPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Trigger Price',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _orderPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Limit Price',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),

              // OCO Secondary Target Leg
              if (_type == GttType.OCO) ...[
                const SizedBox(height: 16),
                Text('TARGET LEG', style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _targetTriggerController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Target Trigger',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _targetOrderController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Target Limit',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                  final triggerPrice = double.tryParse(_triggerPriceController.text) ?? 0.0;
                  final orderPrice = double.tryParse(_orderPriceController.text) ?? 0.0;

                  if (triggerPrice <= 0 || orderPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid positive prices')),
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);

                  try {
                    await ref.read(gttRepositoryProvider).createGtt(
                      symbol: _instrument.symbol,
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

  void _showInstrumentPicker(BuildContext context) {
    final cached = ref.read(cachedInstrumentsProvider).valueOrNull ?? [];
    if (cached.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => ListView.builder(
        itemCount: cached.length,
        itemBuilder: (_, idx) {
          final inst = cached[idx];
          return ListTile(
            title: Text(inst.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(inst.name),
            onTap: () {
              Navigator.pop(ctx);
              _onSelectInstrument(inst);
            },
          );
        },
      ),
    );
  }
}
