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

class Order {
  final String orderId;
  final String exchangeOrderId;
  final Instrument instrument;
  final OrderRequest request;
  final OrderStatus status;
  final int filledQty;
  final double averagePrice;
  final DateTime placedAt;
  final List<OrderEvent> timeline;
  final ChargesBreakdown charges;
  final String? rejectionReason;

  const Order({
    required this.orderId,
    required this.exchangeOrderId,
    required this.instrument,
    required this.request,
    required this.status,
    required this.filledQty,
    required this.averagePrice,
    required this.placedAt,
    required this.timeline,
    required this.charges,
    this.rejectionReason,
  });

  Order copyWith({
    String? orderId,
    String? exchangeOrderId,
    Instrument? instrument,
    OrderRequest? request,
    OrderStatus? status,
    int? filledQty,
    double? averagePrice,
    DateTime? placedAt,
    List<OrderEvent>? timeline,
    ChargesBreakdown? charges,
    String? rejectionReason,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      exchangeOrderId: exchangeOrderId ?? this.exchangeOrderId,
      instrument: instrument ?? this.instrument,
      request: request ?? this.request,
      status: status ?? this.status,
      filledQty: filledQty ?? this.filledQty,
      averagePrice: averagePrice ?? this.averagePrice,
      placedAt: placedAt ?? this.placedAt,
      timeline: timeline ?? this.timeline,
      charges: charges ?? this.charges,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'exchangeOrderId': exchangeOrderId,
    'instrument': instrument.toJson(),
    'request': request.toJson(),
    'status': status.name,
    'filledQty': filledQty,
    'averagePrice': averagePrice,
    'placedAt': placedAt.toIso8601String(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'charges': charges.toJson(),
    'rejectionReason': rejectionReason,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    orderId: json['orderId'] as String,
    exchangeOrderId: json['exchangeOrderId'] as String,
    instrument: Instrument.fromJson(json['instrument'] as Map<String, dynamic>),
    request: OrderRequest.fromJson(json['request'] as Map<String, dynamic>),
    status: OrderStatus.values.byName(json['status'] as String),
    filledQty: (json['filledQty'] as num).toInt(),
    averagePrice: (json['averagePrice'] as num).toDouble(),
    placedAt: DateTime.parse(json['placedAt'] as String),
    timeline: (json['timeline'] as List<dynamic>).map((e) => OrderEvent.fromJson(e as Map<String, dynamic>)).toList(),
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
