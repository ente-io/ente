import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/billing_plan.dart';

class BillingService {
  BillingService._privateConstructor() {}

  static final BillingService instance = BillingService._privateConstructor();

  final _logger = Logger("BillingService");
  final _dio = Network.instance.getDio();

  Future<List<BillingPlan>> _future;

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
}
