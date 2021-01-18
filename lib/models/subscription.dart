import 'dart:convert';

class Subscription {
  final int id;
  final int storageInMBs;
  final int expiryTime;

  Subscription({
    this.id,
    this.storageInMBs,
    this.expiryTime,
  });

  Subscription copyWith({
    int id,
    int storageInMBs,
    int expiryTime,
  }) {
    return Subscription(
      id: id ?? this.id,
      storageInMBs: storageInMBs ?? this.storageInMBs,
      expiryTime: expiryTime ?? this.expiryTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storageInMBs': storageInMBs,
      'expiryTime': expiryTime,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Subscription(
      id: map['id'],
      storageInMBs: map['storageInMBs'],
      expiryTime: map['expiryTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Subscription.fromJson(String source) =>
      Subscription.fromMap(json.decode(source));

  @override
  String toString() =>
      'Subscription(id: $id, storageInMBs: $storageInMBs, expiryTime: $expiryTime)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Subscription &&
        o.id == id &&
        o.storageInMBs == storageInMBs &&
        o.expiryTime == expiryTime;
  }

  @override
  int get hashCode => id.hashCode ^ storageInMBs.hashCode ^ expiryTime.hashCode;
}
