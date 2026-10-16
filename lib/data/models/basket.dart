import 'order.dart';

class Basket {
  final String id;
  final String name;
  final List<OrderRequest> legs;
  final DateTime createdAt;

  const Basket({
    required this.id,
    required this.name,
    required this.legs,
    required this.createdAt,
  });

  Basket copyWith({
    String? id,
    String? name,
    List<OrderRequest>? legs,
    DateTime? createdAt,
  }) {
    return Basket(
      id: id ?? this.id,
      name: name ?? this.name,
      legs: legs ?? this.legs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'legs': legs.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Basket.fromJson(Map<String, dynamic> json) => Basket(
    id: (json['id'] ?? json['_id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    legs: ((json['orders'] ?? json['legs']) as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(OrderRequest.fromJson)
        .toList(),
    createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
  );
}
