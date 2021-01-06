import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingService {
  BillingService._privateConstructor() {}

  static final BillingService instance = BillingService._privateConstructor();
  static const subscriptionKey = "subscription";

  final _logger = Logger("BillingService");
  final _dio = Network.instance.getDio();

  SharedPreferences _prefs;
  Future<List<BillingPlan>> _future;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<BillingPlan>> getBillingPlans() {
    if (_future == null) {
      _future = _dio
          .get(Configuration.instance.getHttpEndpoint() + "/billing/plans")
          .then((response) {
        final plans = List<BillingPlan>();
        for (final plan in response.data["plans"]) {
          plans.add(BillingPlan.fromMap(plan));
        }
        return plans;
      });
    }
    return _future;
  }

  Subscription getSubscription() {
    final jsonValue = _prefs.getString(subscriptionKey);
    if (jsonValue == null) {
      return null;
    } else {
      return Subscription.fromJson(jsonValue);
    }
  }

  Future<void> setSubscription(Subscription subscription) async {
    await _prefs.setString(
        subscriptionKey, subscription == null ? null : subscription.toJson());
  }
}
