import 'dart:convert';

class Subscription {
  final String id;
  final String billingPlanID;
  final int validTill;

  Subscription({
    this.id,
    this.billingPlanID,
    this.validTill,
  });

  Subscription copyWith({
    String id,
    String billingPlanID,
    int validTill,
  }) {
    return Subscription(
      id: id ?? this.id,
      billingPlanID: billingPlanID ?? this.billingPlanID,
      validTill: validTill ?? this.validTill,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billingPlanID': billingPlanID,
      'validTill': validTill,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Subscription(
      id: map['id'],
      billingPlanID: map['billingPlanID'],
      validTill: map['validTill'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Subscription.fromJson(String source) =>
      Subscription.fromMap(json.decode(source));

  @override
  String toString() =>
      'Subscription(id: $id, billingPlanID: $billingPlanID, validTill: $validTill)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Subscription &&
        o.id == id &&
        o.billingPlanID == billingPlanID &&
        o.validTill == validTill;
  }

  @override
  int get hashCode => id.hashCode ^ billingPlanID.hashCode ^ validTill.hashCode;
}
