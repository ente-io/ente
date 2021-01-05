import 'dart:convert';

class BillingPlan {
  final String id;
  final String storage;
  final String price;
  final String duration;

  BillingPlan({
    this.id,
    this.storage,
    this.price,
    this.duration,
  });

  BillingPlan copyWith({
    String id,
    String storage,
    String price,
    String duration,
  }) {
    return BillingPlan(
      id: id ?? this.id,
      storage: storage ?? this.storage,
      price: price ?? this.price,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storage': storage,
      'price': price,
      'duration': duration,
    };
  }

  factory BillingPlan.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return BillingPlan(
      id: map['id'],
      storage: map['storage'],
      price: map['price'],
      duration: map['duration'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BillingPlan.fromJson(String source) =>
      BillingPlan.fromMap(json.decode(source));

  @override
  String toString() {
    return 'BillingPlan(id: $id, storage: $storage, price: $price, duration: $duration)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is BillingPlan &&
        o.id == id &&
        o.storage == storage &&
        o.price == price &&
        o.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^ storage.hashCode ^ price.hashCode ^ duration.hashCode;
  }
}
