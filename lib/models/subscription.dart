import 'dart:convert';

class Subscription {
  final String id;
  final int storageInMBs;
  final int validTill;

  Subscription({
    this.id,
    this.storageInMBs,
    this.validTill,
  });

  Subscription copyWith({
    String id,
    String billingPlanID,
    int validTill,
  }) {
    return Subscription(
      id: id ?? this.id,
      storageInMBs: storageInMBs ?? this.storageInMBs,
      validTill: validTill ?? this.validTill,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storageInMBs': storageInMBs,
      'validTill': validTill,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Subscription(
      id: map['id'],
      storageInMBs: map['storageInMBs'],
      validTill: map['validTill'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Subscription.fromJson(String source) =>
      Subscription.fromMap(json.decode(source));

  @override
  String toString() =>
      'Subscription(id: $id, storageInMBs: $storageInMBs, validTill: $validTill)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Subscription &&
        o.id == id &&
        o.storageInMBs == storageInMBs &&
        o.validTill == validTill;
  }

  @override
  int get hashCode => id.hashCode ^ storageInMBs.hashCode ^ validTill.hashCode;
}
