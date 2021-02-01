import 'dart:convert';

class BillingPlan {
  final String id;
  final String androidID;
  final String iosID;
  final int storage;
  final String price;
  final String period;

  BillingPlan({
    this.id,
    this.androidID,
    this.iosID,
    this.storage,
    this.price,
    this.period,
  });

  BillingPlan copyWith({
    String id,
    String androidID,
    String iosID,
    int storageInMBs,
    String price,
    String period,
  }) {
    return BillingPlan(
      id: id ?? this.id,
      androidID: androidID ?? this.androidID,
      iosID: iosID ?? this.iosID,
      storage: storageInMBs ?? this.storage,
      price: price ?? this.price,
      period: period ?? this.period,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'androidID': androidID,
      'iosID': iosID,
      'storage': storage,
      'price': price,
      'period': period,
    };
  }

  factory BillingPlan.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return BillingPlan(
      id: map['id'],
      androidID: map['androidID'],
      iosID: map['iosID'],
      storage: map['storage'],
      price: map['price'],
      period: map['period'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BillingPlan.fromJson(String source) =>
      BillingPlan.fromMap(json.decode(source));

  @override
  String toString() {
    return 'BillingPlan(id: $id, androidID: $androidID, iosID: $iosID, storage: $storage, price: $price, period: $period)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is BillingPlan &&
        o.id == id &&
        o.androidID == androidID &&
        o.iosID == iosID &&
        o.storage == storage &&
        o.price == price &&
        o.period == period;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        androidID.hashCode ^
        iosID.hashCode ^
        storage.hashCode ^
        price.hashCode ^
        period.hashCode;
  }
}
