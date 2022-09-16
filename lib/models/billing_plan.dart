// @dart = 2.9
import 'dart:convert';

class BillingPlans {
  final List<BillingPlan> plans;
  final FreePlan freePlan;

  BillingPlans({
    this.plans,
    this.freePlan,
  });

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
        map['plans']?.map((x) => BillingPlan.fromMap(x)),
      ),
      freePlan: FreePlan.fromMap(map['freePlan']),
    );
  }

  factory BillingPlans.fromJson(String source) =>
      BillingPlans.fromMap(json.decode(source));
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
}

class BillingPlan {
  final String id;
  final String androidID;
  final String iosID;
  final String stripeID;
  final int storage;
  final String price;
  final String period;

  BillingPlan({
    this.id,
    this.androidID,
    this.iosID,
    this.stripeID,
    this.storage,
    this.price,
    this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'androidID': androidID,
      'iosID': iosID,
      'stripeID': stripeID,
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
      stripeID: map['stripeID'],
      storage: map['storage'],
      price: map['price'],
      period: map['period'],
    );
  }
}
