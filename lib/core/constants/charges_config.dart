import '../../data/models/models.dart';

class ChargesConfig {
  ChargesConfig._();

  static ChargesBreakdown calculateCharges({
    required double price,
    required int quantity,
    required TransactionType side,
    required ProductType product,
    required InstrumentType instrumentType,
  }) {
    final turnover = price * quantity;
    
    // Brokerage: ₹0 for Equity CNC, ₹20 max or 0.03% for MIS/F&O
    double brokerage = 0.0;
    if (product == ProductType.MIS || instrumentType != InstrumentType.EQ) {
      brokerage = (turnover * 0.0003).clamp(0.0, 20.0);
    }

    // STT / CTT
    double stt = 0.0;
    if (side == TransactionType.SELL) {
      if (product == ProductType.CNC && instrumentType == InstrumentType.EQ) {
        stt = turnover * 0.001; // 0.1% on delivery sell
      } else if (product == ProductType.MIS) {
        stt = turnover * 0.00025; // 0.025% on intraday sell
      } else if (instrumentType == InstrumentType.FUT) {
        stt = turnover * 0.000125; // 0.0125% on futures sell
      } else if (instrumentType == InstrumentType.CE || instrumentType == InstrumentType.PE) {
        stt = turnover * 0.000625; // 0.0625% on options sell
      }
    }

    // Exchange transaction charge (NSE approx 0.00297%)
    final exchangeTxnCharge = turnover * 0.0000297;

    // SEBI turnover charge (₹10 / crore = 0.0001%)
    final sebiCharges = turnover * 0.000001;

    // Stamp duty (Buy side only: 0.015% delivery, 0.003% intraday, 0.002% futures, 0.003% options)
    double stampDuty = 0.0;
    if (side == TransactionType.BUY) {
      if (product == ProductType.CNC && instrumentType == InstrumentType.EQ) {
        stampDuty = turnover * 0.00015;
      } else if (product == ProductType.MIS) {
        stampDuty = turnover * 0.00003;
      } else if (instrumentType == InstrumentType.FUT) {
        stampDuty = turnover * 0.00002;
      } else {
        stampDuty = turnover * 0.00003;
      }
    }

    // GST: 18% on (brokerage + exchange txn charge + sebi charges)
    final gst = (brokerage + exchangeTxnCharge + sebiCharges) * 0.18;

    return ChargesBreakdown(
      brokerage: double.parse(brokerage.toStringAsFixed(2)),
      stt: double.parse(stt.toStringAsFixed(2)),
      exchangeTxnCharge: double.parse(exchangeTxnCharge.toStringAsFixed(2)),
      gst: double.parse(gst.toStringAsFixed(2)),
      sebiCharges: double.parse(sebiCharges.toStringAsFixed(2)),
      stampDuty: double.parse(stampDuty.toStringAsFixed(2)),
    );
  }
}
