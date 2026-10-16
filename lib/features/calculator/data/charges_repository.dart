import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';

final chargesRepositoryProvider = Provider<ChargesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChargesRepository(client);
});

class ChargesBreakdown {
  final double brokerage;
  final double stt;
  final double exchangeTxnFee;
  final double gst;
  final double sebiCharges;
  final double stampDuty;
  final double totalCharges;

  const ChargesBreakdown({
    this.brokerage = 0.0,
    this.stt = 0.0,
    this.exchangeTxnFee = 0.0,
    this.gst = 0.0,
    this.sebiCharges = 0.0,
    this.stampDuty = 0.0,
    this.totalCharges = 0.0,
  });

  factory ChargesBreakdown.fromJson(Map<String, dynamic> json) {
    return ChargesBreakdown(
      brokerage: (json['brokerage'] as num?)?.toDouble() ?? 0.0,
      stt: (json['stt'] as num?)?.toDouble() ?? 0.0,
      exchangeTxnFee: (json['exchangeTxnFee'] ?? json['exchangeTurnoverFee'] as num?)?.toDouble() ?? 0.0,
      gst: (json['gst'] as num?)?.toDouble() ?? 0.0,
      sebiCharges: (json['sebiCharges'] as num?)?.toDouble() ?? 0.0,
      stampDuty: (json['stampDuty'] as num?)?.toDouble() ?? 0.0,
      totalCharges: (json['totalCharges'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChargesRepository {
  final ApiClient _client;

  ChargesRepository(this._client);

  Future<Map<String, dynamic>> getChargesConfig() async {
    final response = await _client.get(ApiPaths.chargesConfig);
    final data = ResponseReader.unwrap(response);
    return ResponseReader.asMap(data);
  }

  Future<ChargesBreakdown> calculateCharges({
    required double tradeValue,
    required String side, // 'BUY' or 'SELL'
    String market = 'INDIAN',
    String product = 'MIS',
  }) async {
    final payload = {
      'tradeValue': tradeValue,
      'market': market,
      'side': side,
      'product': product,
    };
    final response = await _client.post(ApiPaths.chargesCalculate, data: payload);
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return ChargesBreakdown.fromJson(map);
  }
}
