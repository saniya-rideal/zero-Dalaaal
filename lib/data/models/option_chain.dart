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
    token: json['token'] as String,
    ltp: (json['ltp'] as num).toDouble(),
    change: (json['change'] as num).toDouble(),
    changePercent: (json['changePercent'] as num).toDouble(),
    oi: (json['oi'] as num).toInt(),
    changeInOi: (json['changeInOi'] as num).toInt(),
    iv: (json['iv'] as num).toDouble(),
    volume: (json['volume'] as num).toInt(),
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
    strike: (json['strike'] as num).toDouble(),
    call: OptionLeg.fromJson(json['call'] as Map<String, dynamic>),
    put: OptionLeg.fromJson(json['put'] as Map<String, dynamic>),
    isAtm: json['isAtm'] as bool? ?? false,
  );
}
