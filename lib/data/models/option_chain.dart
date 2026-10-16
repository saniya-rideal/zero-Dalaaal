class OptionLeg {
  final String token;
  final double ltp;
  final double change;
  final double changePercent;
  final int oi;
  final int changeInOi;
  final double iv;
  final int volume;

  const OptionLeg({
    required this.token,
    required this.ltp,
    required this.change,
    required this.changePercent,
    required this.oi,
    required this.changeInOi,
    required this.iv,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'ltp': ltp,
    'change': change,
    'changePercent': changePercent,
    'oi': oi,
    'changeInOi': changeInOi,
    'iv': iv,
    'volume': volume,
  };

  factory OptionLeg.fromJson(Map<String, dynamic> json) => OptionLeg(
    token: (json['token'] ?? json['symbol'] ?? '').toString(),
    ltp: (json['ltp'] as num?)?.toDouble() ?? 0.0,
    change: (json['change'] as num?)?.toDouble() ?? 0.0,
    changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
    oi: (json['oi'] ?? json['openInterest'] as num?)?.toInt() ?? 0,
    changeInOi: (json['changeInOi'] ?? json['oiChange'] as num?)?.toInt() ?? 0,
    iv: (json['iv'] as num?)?.toDouble() ?? 0.0,
    volume: (json['volume'] as num?)?.toInt() ?? 0,
  );
}

class OptionChainRow {
  final double strike;
  final OptionLeg call;
  final OptionLeg put;
  final bool isAtm;

  const OptionChainRow({
    required this.strike,
    required this.call,
    required this.put,
    this.isAtm = false,
  });

  Map<String, dynamic> toJson() => {
    'strike': strike,
    'call': call.toJson(),
    'put': put.toJson(),
    'isAtm': isAtm,
  };

  factory OptionChainRow.fromJson(Map<String, dynamic> json) => OptionChainRow(
    strike: (json['strike'] ?? json['strikePrice'] as num?)?.toDouble() ?? 0.0,
    call: json['call'] is Map<String, dynamic>
        ? OptionLeg.fromJson(json['call'] as Map<String, dynamic>)
        : const OptionLeg(token: '', ltp: 0, change: 0, changePercent: 0, oi: 0, changeInOi: 0, iv: 0, volume: 0),
    put: json['put'] is Map<String, dynamic>
        ? OptionLeg.fromJson(json['put'] as Map<String, dynamic>)
        : const OptionLeg(token: '', ltp: 0, change: 0, changePercent: 0, oi: 0, changeInOi: 0, iv: 0, volume: 0),
    isAtm: json['isAtm'] as bool? ?? false,
  );
}
