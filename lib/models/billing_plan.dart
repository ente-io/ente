import 'dart:convert';

import 'package:flutter/foundation.dart';

class BillingPlans {
  final List<BillingPlan> plans;
  final FreePlan freePlan;

  BillingPlans({
    this.plans,
    this.freePlan,
  });

  BillingPlans copyWith({
    List<BillingPlan> plans,
    FreePlan freePlan,
  }) {
    return BillingPlans(
      plans: plans ?? this.plans,
      freePlan: freePlan ?? this.freePlan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plans': plans?.map((x) => x?.toMap())?.toList(),
      'freePlan': freePlan?.toMap(),
    };
  }

  factory BillingPlans.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return BillingPlans(
      plans: List<BillingPlan>.from(
          map['plans']?.map((x) => BillingPlan.fromMap(x))),
      freePlan: FreePlan.fromMap(map['freePlan']),
    );
  }

  String toJson() => json.encode(toMap());

  factory BillingPlans.fromJson(String source) =>
      BillingPlans.fromMap(json.decode(source));

  @override
  String toString() => 'BillingPlans(plans: $plans, freePlan: $freePlan)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is BillingPlans &&
        listEquals(o.plans, plans) &&
        o.freePlan == freePlan;
  }

  @override
  int get hashCode => plans.hashCode ^ freePlan.hashCode;
}

class FreePlan {
  final int storage;
  final int duration;
  final String period;
  FreePlan({
    this.storage,
    this.duration,
    this.period,
  });

  FreePlan copyWith({
    int storage,
    int duration,
    String period,
  }) {
    return FreePlan(
      storage: storage ?? this.storage,
      duration: duration ?? this.duration,
      period: period ?? this.period,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storage': storage,
      'duration': duration,
      'period': period,
    };
  }

  factory FreePlan.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return FreePlan(
      storage: map['storage'],
      duration: map['duration'],
      period: map['period'],
    );
  }

  String toJson() => json.encode(toMap());

  factory FreePlan.fromJson(String source) =>
      FreePlan.fromMap(json.decode(source));

  @override
  String toString() =>
      'FreePlan(storage: $storage, duration: $duration, period: $period)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is FreePlan &&
        o.storage == storage &&
        o.duration == duration &&
        o.period == period;
  }

  @override
  int get hashCode => storage.hashCode ^ duration.hashCode ^ period.hashCode;
}

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
    int storage,
    String price,
    String period,
  }) {
    return BillingPlan(
      id: id ?? this.id,
      androidID: androidID ?? this.androidID,
      iosID: iosID ?? this.iosID,
      storage: storage ?? this.storage,
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
