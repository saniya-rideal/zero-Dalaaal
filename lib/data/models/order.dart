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
    );
  }

  Map<String, dynamic> toJson() => {
    'instrumentToken': instrumentToken,
    'side': side.name,
    'product': product.name,
    'kind': kind.name,
    'quantity': quantity,
    'price': price,
    'triggerPrice': triggerPrice,
    'validity': validity.name,
    'disclosedQty': disclosedQty,
    'variety': variety.name,
    'bracket': bracket?.toJson(),
    'idempotencyKey': idempotencyKey,
  };

  factory OrderRequest.fromJson(Map<String, dynamic> json) => OrderRequest(
    instrumentToken: json['instrumentToken'] as String,
    side: TransactionType.values.byName(json['side'] as String),
    product: ProductType.values.byName(json['product'] as String),
    kind: OrderKind.values.byName(json['kind'] as String),
    quantity: (json['quantity'] as num).toInt(),
    price: (json['price'] as num?)?.toDouble(),
    triggerPrice: (json['triggerPrice'] as num?)?.toDouble(),
    validity: Validity.values.byName(json['validity'] as String),
    disclosedQty: (json['disclosedQty'] as num?)?.toInt() ?? 0,
    variety: OrderVariety.values.byName(json['variety'] as String),
    bracket: json['bracket'] != null ? BracketParams.fromJson(json['bracket'] as Map<String, dynamic>) : null,
    idempotencyKey: json['idempotencyKey'] as String?,
  );
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

  factory ChargesBreakdown.fromJson(Map<String, dynamic> json) => ChargesBreakdown(
    brokerage: (json['brokerage'] as num?)?.toDouble() ?? 0.0,
    stt: (json['stt'] as num).toDouble(),
    exchangeTxnCharge: (json['exchangeTxnCharge'] as num).toDouble(),
    gst: (json['gst'] as num).toDouble(),
    sebiCharges: (json['sebiCharges'] as num).toDouble(),
    stampDuty: (json['stampDuty'] as num).toDouble(),
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

  String get effectiveServerOrderId => serverOrderId ?? 'ZD-SRV-$orderId';
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

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    orderId: json['orderId'] as String,
    exchangeOrderId: json['exchangeOrderId'] as String,
    serverOrderId: json['serverOrderId'] as String?,
    instrument: Instrument.fromJson(json['instrument'] as Map<String, dynamic>),
    request: OrderRequest.fromJson(json['request'] as Map<String, dynamic>),
    status: OrderStatus.values.byName(json['status'] as String),
    filledQty: (json['filledQty'] as num).toInt(),
    averagePrice: (json['averagePrice'] as num).toDouble(),
    placedAt: DateTime.parse(json['placedAt'] as String),
    timeline: (json['timeline'] as List<dynamic>).map((e) => OrderEvent.fromJson(e as Map<String, dynamic>)).toList(),
    auditTrail: (json['auditTrail'] as List<dynamic>?)?.map((e) => OrderAuditEntry.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
    charges: ChargesBreakdown.fromJson(json['charges'] as Map<String, dynamic>),
    rejectionReason: json['rejectionReason'] as String?,
  );
}

enum GttType { SINGLE, OCO }
enum GttStatus { ACTIVE, TRIGGERED, EXPIRED, CANCELLED }

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

  factory GttOrder.fromJson(Map<String, dynamic> json) => GttOrder(
    id: json['id'] as String,
    instrument: Instrument.fromJson(json['instrument'] as Map<String, dynamic>),
    request: GttRequest.fromJson(json['request'] as Map<String, dynamic>),
    status: GttStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    triggeredAt: json['triggeredAt'] != null ? DateTime.parse(json['triggeredAt'] as String) : null,
  );
}
