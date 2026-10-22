import 'enums.dart';
import 'instrument.dart';

class BracketParams {
  final double target;
  final double stopLoss;
  final double? trailingSl;

  const BracketParams({
    required this.target,
    required this.stopLoss,
    this.trailingSl,
  });

  Map<String, dynamic> toJson() => {
    'target': target,
    'stopLoss': stopLoss,
    'trailingSl': trailingSl,
  };

  factory BracketParams.fromJson(Map<String, dynamic> json) => BracketParams(
    target: (json['target'] as num).toDouble(),
    stopLoss: (json['stopLoss'] as num).toDouble(),
    trailingSl: (json['trailingSl'] as num?)?.toDouble(),
  );
}

class OrderRequest {
  final String instrumentToken;
  final TransactionType side;
  final ProductType product;
  final OrderKind kind;
  final int quantity;
  final double? price;
  final double? triggerPrice;
  final Validity validity;
  final int disclosedQty;
  final OrderVariety variety;
  final BracketParams? bracket;
  final String? idempotencyKey;
  final double? leverage;
  final String? market;
  final DateTime? expiresAt;
  final String? comment;

  const OrderRequest({
    required this.instrumentToken,
    required this.side,
    required this.product,
    required this.kind,
    required this.quantity,
    this.price,
    this.triggerPrice,
    this.validity = Validity.DAY,
    this.disclosedQty = 0,
    this.variety = OrderVariety.REGULAR,
    this.bracket,
    this.idempotencyKey,
    this.leverage,
    this.market,
    this.expiresAt,
    this.comment,
  });

  OrderRequest copyWith({
    String? instrumentToken,
    TransactionType? side,
    ProductType? product,
    OrderKind? kind,
    int? quantity,
    double? price,
    double? triggerPrice,
    Validity? validity,
    int? disclosedQty,
    OrderVariety? variety,
    BracketParams? bracket,
    String? idempotencyKey,
    double? leverage,
    String? market,
    DateTime? expiresAt,
    String? comment,
  }) {
    return OrderRequest(
      instrumentToken: instrumentToken ?? this.instrumentToken,
      side: side ?? this.side,
      product: product ?? this.product,
      kind: kind ?? this.kind,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      triggerPrice: triggerPrice ?? this.triggerPrice,
      validity: validity ?? this.validity,
      disclosedQty: disclosedQty ?? this.disclosedQty,
      variety: variety ?? this.variety,
      bracket: bracket ?? this.bracket,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      leverage: leverage ?? this.leverage,
      market: market ?? this.market,
      expiresAt: expiresAt ?? this.expiresAt,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toJson() => {
    'instrumentToken': instrumentToken,
    'symbol': instrumentToken,
    'side': side.name,
    'product': product.name,
    'kind': kind.toBackendString(),
    'orderType': kind.toBackendString(),
    'type': kind.toBackendString(),
    'quantity': quantity,
    if (price != null && price! > 0) 'price': price,
    if (price != null && price! > 0) 'limitPrice': price,
    if (triggerPrice != null && triggerPrice! > 0) 'triggerPrice': triggerPrice,
    'validity': validity.name,
    'disclosedQty': disclosedQty,
    'variety': variety.name,
    if (bracket != null) 'bracket': bracket!.toJson(),
    if (bracket?.stopLoss != null && bracket!.stopLoss > 0) 'stopLoss': bracket!.stopLoss,
    if (bracket?.target != null && bracket!.target > 0) 'takeProfit': bracket!.target,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    if (leverage != null && leverage! > 0) 'leverage': leverage,
    if (market != null) 'market': market,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
  };

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    OrderKind parsedKind = OrderKind.MARKET;
    final rawKind = (json['orderType'] ?? json['type'] ?? json['kind'] ?? '').toString().toUpperCase();
    for (final k in OrderKind.values) {
      if (k.name == rawKind || k.toBackendString() == rawKind) {
        parsedKind = k;
        break;
      }
    }

    ProductType parsedProd = ProductType.MIS;
    final rawProd = (json['product'] ?? '').toString().toUpperCase();
    for (final p in ProductType.values) {
      if (p.name == rawProd) {
        parsedProd = p;
        break;
      }
    }

    Validity parsedVal = Validity.DAY;
    final rawVal = (json['validity'] ?? '').toString().toUpperCase();
    for (final v in Validity.values) {
      if (v.name == rawVal) {
        parsedVal = v;
        break;
      }
    }

    return OrderRequest(
      instrumentToken: (json['instrumentToken'] ?? json['symbol'] ?? '').toString(),
      side: json['side'] == 'SELL' ? TransactionType.SELL : TransactionType.BUY,
      product: parsedProd,
      kind: parsedKind,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] ?? json['limitPrice'] as num?)?.toDouble(),
      triggerPrice: (json['triggerPrice'] as num?)?.toDouble(),
      validity: parsedVal,
      disclosedQty: (json['disclosedQty'] as num?)?.toInt() ?? 0,
      variety: OrderVariety.REGULAR,
      bracket: json['bracket'] != null ? BracketParams.fromJson(json['bracket'] as Map<String, dynamic>) : null,
      idempotencyKey: json['idempotencyKey'] as String?,
      leverage: (json['leverage'] as num?)?.toDouble(),
      market: json['market'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      comment: json['comment'] as String?,
    );
  }
}

class OrderPreviewRequest {
  final String symbol;
  final TransactionType side;
  final OrderKind orderType;
  final num quantity;
  final double? limitPrice;
  final double? triggerPrice;
  final double? leverage;
  final ProductType product;
  final Validity validity;

  const OrderPreviewRequest({
    required this.symbol,
    required this.side,
    required this.orderType,
    required this.quantity,
    this.limitPrice,
    this.triggerPrice,
    this.leverage,
    this.product = ProductType.MIS,
    this.validity = Validity.DAY,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'side': side.name,
    'orderType': orderType.toBackendString(),
    'quantity': quantity,
    if (limitPrice != null && limitPrice! > 0) 'limitPrice': limitPrice,
    if (triggerPrice != null && triggerPrice! > 0) 'triggerPrice': triggerPrice,
    if (leverage != null && leverage! > 0) 'leverage': leverage,
    'product': product.name,
    'validity': validity.name,
  };
}

class OrderPreview {
  final double requiredMargin;
  final double availableMargin;
  final double marginAfterTrade;
  final double? marginLevel;
  final ChargesBreakdown charges;
  final List<String> warnings;
  final bool canPlace;
  final String? blockingReason;
  final double executionPrice;

  const OrderPreview({
    required this.requiredMargin,
    required this.availableMargin,
    required this.marginAfterTrade,
    this.marginLevel,
    required this.charges,
    this.warnings = const [],
    required this.canPlace,
    this.blockingReason,
    this.executionPrice = 0.0,
  });

  factory OrderPreview.fromJson(Map<String, dynamic> json) {
    final reqMargin = (json['requiredMargin'] ?? json['marginRequired'] as num?)?.toDouble() ?? 0.0;
    final availMargin = (json['availableMargin'] ?? json['freeMarginBefore'] ?? json['freeMargin'] as num?)?.toDouble() ?? 0.0;
    final afterTrade = (json['marginAfterTrade'] ?? json['freeMarginAfter'] as num?)?.toDouble() ??
        (availMargin - reqMargin);
    final marginLvl = (json['marginLevel'] as num?)?.toDouble();

    ChargesBreakdown brk;
    if (json['charges'] is Map<String, dynamic>) {
      brk = ChargesBreakdown.fromJson(json['charges'] as Map<String, dynamic>);
    } else {
      brk = ChargesBreakdown.fromJson(json);
    }

    final warnList = <String>[];
    if (json['warnings'] is List) {
      for (final w in json['warnings'] as List) {
        if (w != null && w.toString().isNotEmpty) {
          warnList.add(w.toString());
        }
      }
    }

    final totalChg = (json['totalCharges'] as num?)?.toDouble() ?? brk.total;
    final canBePlaced = json['canPlace'] is bool
        ? json['canPlace'] as bool
        : (availMargin >= (reqMargin + totalChg));

    String? blockReason;
    if (json['blockingReason'] != null) {
      blockReason = json['blockingReason'].toString();
    } else if (!canBePlaced) {
      blockReason = 'Insufficient available margin (₹${availMargin.toStringAsFixed(2)}) for required margin (₹${reqMargin.toStringAsFixed(2)})';
    }

    final execPrice = (json['executionPrice'] ?? json['price'] as num?)?.toDouble() ?? 0.0;

    return OrderPreview(
      requiredMargin: reqMargin,
      availableMargin: availMargin,
      marginAfterTrade: afterTrade,
      marginLevel: marginLvl,
      charges: brk,
      warnings: warnList,
      canPlace: canBePlaced,
      blockingReason: blockReason,
      executionPrice: execPrice,
    );
  }
}


class OrderEvent {
  final OrderStatus status;
  final String description;
  final DateTime at;

  const OrderEvent({
    required this.status,
    required this.description,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'description': description,
    'at': at.toIso8601String(),
  };

  factory OrderEvent.fromJson(Map<String, dynamic> json) => OrderEvent(
    status: OrderStatus.values.byName(json['status'] as String),
    description: json['description'] as String,
    at: DateTime.parse(json['at'] as String),
  );
}

class ChargesBreakdown {
  final double brokerage;
  final double stt;
  final double exchangeTxnCharge;
  final double gst;
  final double sebiCharges;
  final double stampDuty;

  const ChargesBreakdown({
    this.brokerage = 0.0,
    required this.stt,
    required this.exchangeTxnCharge,
    required this.gst,
    required this.sebiCharges,
    required this.stampDuty,
  });

  double get total => brokerage + stt + exchangeTxnCharge + gst + sebiCharges + stampDuty;

  Map<String, dynamic> toJson() => {
    'brokerage': brokerage,
    'stt': stt,
    'exchangeTxnCharge': exchangeTxnCharge,
    'gst': gst,
    'sebiCharges': sebiCharges,
    'stampDuty': stampDuty,
  };

  factory ChargesBreakdown.zero() => const ChargesBreakdown(
    brokerage: 0.0,
    stt: 0.0,
    exchangeTxnCharge: 0.0,
    gst: 0.0,
    sebiCharges: 0.0,
    stampDuty: 0.0,
  );

  factory ChargesBreakdown.fromJson(Map<String, dynamic> json) => ChargesBreakdown(
    brokerage: (json['brokerage'] as num?)?.toDouble() ?? 0.0,
    stt: (json['stt'] as num?)?.toDouble() ?? 0.0,
    exchangeTxnCharge: (json['exchangeTxnCharge'] ?? json['exchangeTxn'] ?? json['exchangeTurnoverFee'] as num?)?.toDouble() ?? 0.0,
    gst: (json['gst'] as num?)?.toDouble() ?? 0.0,
    sebiCharges: (json['sebiCharges'] as num?)?.toDouble() ?? 0.0,
    stampDuty: (json['stampDuty'] as num?)?.toDouble() ?? 0.0,
  );
}

class OrderAuditEntry {
  final DateTime timestamp;
  final OrderStatus fromStatus;
  final OrderStatus toStatus;
  final String action;
  final String actorId;
  final String? details;
  final String? clientIp;

  const OrderAuditEntry({
    required this.timestamp,
    required this.fromStatus,
    required this.toStatus,
    required this.action,
    this.actorId = 'SYSTEM',
    this.details,
    this.clientIp,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'fromStatus': fromStatus.name,
    'toStatus': toStatus.name,
    'action': action,
    'actorId': actorId,
    'details': details,
    'clientIp': clientIp,
  };

  factory OrderAuditEntry.fromJson(Map<String, dynamic> json) => OrderAuditEntry(
    timestamp: DateTime.parse(json['timestamp'] as String),
    fromStatus: OrderStatus.values.byName(json['fromStatus'] as String),
    toStatus: OrderStatus.values.byName(json['toStatus'] as String),
    action: json['action'] as String,
    actorId: json['actorId'] as String? ?? 'SYSTEM',
    details: json['details'] as String?,
    clientIp: json['clientIp'] as String?,
  );
}

class Order {
  final String orderId;
  final String exchangeOrderId;
  final String? serverOrderId;
  final Instrument instrument;
  final OrderRequest request;
  final OrderStatus status;
  final int filledQty;
  final double averagePrice;
  final DateTime placedAt;
  final List<OrderEvent> timeline;
  final List<OrderAuditEntry> auditTrail;
  final ChargesBreakdown charges;
  final String? rejectionReason;

  const Order({
    required this.orderId,
    required this.exchangeOrderId,
    this.serverOrderId,
    required this.instrument,
    required this.request,
    required this.status,
    required this.filledQty,
    required this.averagePrice,
    required this.placedAt,
    required this.timeline,
    this.auditTrail = const [],
    required this.charges,
    this.rejectionReason,
  });

  String get id => orderId;
  String get effectiveServerOrderId => serverOrderId ?? orderId;
  String? get idempotencyKey => request.idempotencyKey;

  Order copyWith({
    String? orderId,
    String? exchangeOrderId,
    String? serverOrderId,
    Instrument? instrument,
    OrderRequest? request,
    OrderStatus? status,
    int? filledQty,
    double? averagePrice,
    DateTime? placedAt,
    List<OrderEvent>? timeline,
    List<OrderAuditEntry>? auditTrail,
    ChargesBreakdown? charges,
    String? rejectionReason,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      exchangeOrderId: exchangeOrderId ?? this.exchangeOrderId,
      serverOrderId: serverOrderId ?? this.serverOrderId,
      instrument: instrument ?? this.instrument,
      request: request ?? this.request,
      status: status ?? this.status,
      filledQty: filledQty ?? this.filledQty,
      averagePrice: averagePrice ?? this.averagePrice,
      placedAt: placedAt ?? this.placedAt,
      timeline: timeline ?? this.timeline,
      auditTrail: auditTrail ?? this.auditTrail,
      charges: charges ?? this.charges,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'exchangeOrderId': exchangeOrderId,
    'serverOrderId': serverOrderId,
    'instrument': instrument.toJson(),
    'request': request.toJson(),
    'status': status.name,
    'filledQty': filledQty,
    'averagePrice': averagePrice,
    'placedAt': placedAt.toIso8601String(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'auditTrail': auditTrail.map((e) => e.toJson()).toList(),
    'charges': charges.toJson(),
    'rejectionReason': rejectionReason,
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final oId = (json['orderId'] ?? json['id'] ?? json['_id'] ?? '').toString();
    final exId = (json['exchangeOrderId'] ?? json['serverOrderId'] ?? oId).toString();
    final srvId = json['serverOrderId']?.toString();

    // Tolerant status parsing
    OrderStatus stat = OrderStatus.OPEN;
    final statRaw = (json['status'] ?? '').toString().toUpperCase();
    for (final val in OrderStatus.values) {
      if (val.name == statRaw) {
        stat = val;
        break;
      }
    }
    if (statRaw == 'PENDING') stat = OrderStatus.OPEN;
    if (statRaw == 'FILLED') stat = OrderStatus.COMPLETE;

    // Instrument parsing
    Instrument inst;
    if (json['instrument'] is Map<String, dynamic>) {
      inst = Instrument.fromJson(json['instrument'] as Map<String, dynamic>);
    } else {
      final sym = (json['symbol'] ?? json['instrumentToken'] ?? '').toString();
      inst = Instrument(
        symbol: sym,
        token: sym,
        name: sym,
        exchange: Exchange.NSE,
        type: InstrumentType.EQ,
      );
    }

    // Request parsing
    OrderRequest req;
    if (json['request'] is Map<String, dynamic>) {
      req = OrderRequest.fromJson(json['request'] as Map<String, dynamic>);
    } else {
      TransactionType s = TransactionType.BUY;
      final sideRaw = (json['side'] ?? '').toString().toUpperCase();
      if (sideRaw == 'SELL') s = TransactionType.SELL;

      OrderKind k = OrderKind.MARKET;
      final kindRaw = (json['orderType'] ?? json['kind'] ?? '').toString().toUpperCase();
      if (kindRaw == 'LIMIT') k = OrderKind.LIMIT;
      if (kindRaw == 'SL' || kindRaw == 'STOP') k = OrderKind.SL;
      if (kindRaw == 'SL_M' || kindRaw == 'STOP_MARKET') k = OrderKind.SL_M;

      final qty = (json['quantity'] ?? json['filledQty'] as num?)?.toInt() ?? 1;
      final limPrice = (json['limitPrice'] ?? json['price'] as num?)?.toDouble();
      final stopLoss = (json['stopLoss'] as num?)?.toDouble();
      final takeProfit = (json['takeProfit'] as num?)?.toDouble();

      BracketParams? brk;
      if (stopLoss != null || takeProfit != null) {
        brk = BracketParams(
          target: takeProfit ?? 0.0,
          stopLoss: stopLoss ?? 0.0,
        );
      }

      req = OrderRequest(
        instrumentToken: inst.symbol,
        side: s,
        product: ProductType.MIS,
        kind: k,
        quantity: qty,
        price: limPrice,
        bracket: brk,
        idempotencyKey: json['idempotencyKey']?.toString(),
      );
    }

    final filled = (json['filledQty'] ?? json['quantity'] as num?)?.toInt() ?? 0;
    final avg = (json['averagePrice'] ?? json['avgPrice'] ?? json['entryPrice'] ?? json['price'] as num?)?.toDouble() ?? 0.0;

    DateTime placed;
    final rawDate = json['placedAt'] ?? json['createdAt'] ?? json['timestamp'];
    if (rawDate != null) {
      placed = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      placed = DateTime.now();
    }

    List<OrderEvent> tl = [];
    if (json['timeline'] is List) {
      tl = (json['timeline'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderEvent.fromJson(e))
          .toList();
    }
    if (tl.isEmpty) {
      tl = [
        OrderEvent(
          status: stat,
          description: 'Order $statRaw',
          at: placed,
        ),
      ];
    }

    List<OrderAuditEntry> audits = [];
    if (json['auditTrail'] is List) {
      audits = (json['auditTrail'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderAuditEntry.fromJson(e))
          .toList();
    }

    ChargesBreakdown chg;
    if (json['charges'] is Map<String, dynamic>) {
      chg = ChargesBreakdown.fromJson(json['charges'] as Map<String, dynamic>);
    } else {
      final fee = (json['fees'] ?? json['margin'] as num?)?.toDouble() ?? 0.0;
      chg = ChargesBreakdown(
        brokerage: 0.0,
        stt: 0.0,
        exchangeTxnCharge: fee,
        gst: 0.0,
        sebiCharges: 0.0,
        stampDuty: 0.0,
      );
    }

    return Order(
      orderId: oId,
      exchangeOrderId: exId,
      serverOrderId: srvId,
      instrument: inst,
      request: req,
      status: stat,
      filledQty: filled,
      averagePrice: avg,
      placedAt: placed,
      timeline: tl,
      auditTrail: audits,
      charges: chg,
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

enum GttType { SINGLE, OCO }
enum GttStatus { ACTIVE, TRIGGERED, EXPIRED, CANCELLED, REJECTED }

class GttRequest {
  final String instrumentToken;
  final TransactionType side;
  final GttType type;
  final int quantity;
  final double triggerPrice;
  final double orderPrice;
  final double? targetTriggerPrice;
  final double? targetOrderPrice;

  const GttRequest({
    required this.instrumentToken,
    required this.side,
    this.type = GttType.SINGLE,
    required this.quantity,
    required this.triggerPrice,
    required this.orderPrice,
    this.targetTriggerPrice,
    this.targetOrderPrice,
  });

  Map<String, dynamic> toJson() => {
    'instrumentToken': instrumentToken,
    'side': side.name,
    'type': type.name,
    'quantity': quantity,
    'triggerPrice': triggerPrice,
    'orderPrice': orderPrice,
    'targetTriggerPrice': targetTriggerPrice,
    'targetOrderPrice': targetOrderPrice,
  };

  factory GttRequest.fromJson(Map<String, dynamic> json) => GttRequest(
    instrumentToken: json['instrumentToken'] as String,
    side: TransactionType.values.byName(json['side'] as String),
    type: GttType.values.byName(json['type'] as String),
    quantity: (json['quantity'] as num).toInt(),
    triggerPrice: (json['triggerPrice'] as num).toDouble(),
    orderPrice: (json['orderPrice'] as num).toDouble(),
    targetTriggerPrice: (json['targetTriggerPrice'] as num?)?.toDouble(),
    targetOrderPrice: (json['targetOrderPrice'] as num?)?.toDouble(),
  );
}

class GttOrder {
  final String id;
  final Instrument instrument;
  final GttRequest request;
  final GttStatus status;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  const GttOrder({
    required this.id,
    required this.instrument,
    required this.request,
    required this.status,
    required this.createdAt,
    this.triggeredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'instrument': instrument.toJson(),
    'request': request.toJson(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'triggeredAt': triggeredAt?.toIso8601String(),
  };

  factory GttOrder.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final sym = (json['symbol'] ?? (json['instrument'] is Map ? (json['instrument'] as Map)['symbol'] : '') ?? '').toString();

    Instrument inst;
    if (json['instrument'] is Map<String, dynamic>) {
      inst = Instrument.fromJson(json['instrument'] as Map<String, dynamic>);
    } else {
      inst = Instrument(
        token: sym,
        symbol: sym,
        name: sym,
        exchange: Exchange.NSE,
        segment: 'EQUITY',
        type: InstrumentType.EQ,
        lotSize: 1.0,
        tickSize: 0.05,
      );
    }

    GttRequest req;
    if (json['request'] is Map<String, dynamic>) {
      req = GttRequest.fromJson(json['request'] as Map<String, dynamic>);
    } else {
      final sideStr = (json['orderSide'] ?? json['side'] ?? 'BUY').toString().toUpperCase();
      final side = sideStr == 'SELL' ? TransactionType.SELL : TransactionType.BUY;
      final qty = (json['quantity'] as num?)?.toInt() ?? 1;
      final trig = (json['triggerPrice'] as num?)?.toDouble() ?? 0.0;
      final ordPrice = (json['price'] ?? json['orderPrice'] as num?)?.toDouble() ?? trig;
      req = GttRequest(
        instrumentToken: sym,
        side: side,
        quantity: qty,
        triggerPrice: trig,
        orderPrice: ordPrice,
      );
    }

    final statusStr = (json['status'] ?? 'ACTIVE').toString().toUpperCase();
    GttStatus st = GttStatus.ACTIVE;
    if (statusStr == 'TRIGGERED') {
      st = GttStatus.TRIGGERED;
    } else if (statusStr == 'CANCELLED') {
      st = GttStatus.CANCELLED;
    } else if (statusStr == 'REJECTED') {
      st = GttStatus.REJECTED;
    }

    final created = json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
        : DateTime.now();
    final triggered = json['triggeredAt'] != null
        ? DateTime.tryParse(json['triggeredAt'].toString())
        : null;

    return GttOrder(
      id: id,
      instrument: inst,
      request: req,
      status: st,
      createdAt: created,
      triggeredAt: triggered,
    );
  }
}
