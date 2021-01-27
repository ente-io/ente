import 'dart:io';

import 'package:dio/dio.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingService {
  BillingService._privateConstructor();

  static final BillingService instance = BillingService._privateConstructor();
  static const subscriptionKey = "subscription";

  final _logger = Logger("BillingService");
  final _dio = Network.instance.getDio();
  final _config = Configuration.instance;

  bool _isOnSubscriptionPage = false;

  SharedPreferences _prefs;
  Future<List<BillingPlan>> _future;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    InAppPurchaseConnection.instance.purchaseUpdatedStream
        .listen((event) async {
      if (_isOnSubscriptionPage) {
        return;
      }
      for (final e in event) {
        if (e.status == PurchaseStatus.purchased) {
          try {
            await verifySubscription(
                e.productID, e.verificationData.serverVerificationData);
          } catch (e) {
            _logger.warning("Could not complete payment ", e);
            return;
          }
          await InAppPurchaseConnection.instance.completePurchase(e);
        } else if (Platform.isIOS && e.pendingCompletePurchase) {
          await InAppPurchaseConnection.instance.completePurchase(e);
        }
      }
    });
  }

  Future<List<BillingPlan>> getBillingPlans() {
    if (_future == null) {
      _future = _dio
          .get(_config.getHttpEndpoint() + "/billing/plans")
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

  Future<Subscription> verifySubscription(
      final subscriptionID, final verificationData) async {
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/billing/verify-subscription",
        data: {
          "paymentProvider": Platform.isAndroid ? "playstore" : "appstore",
          "subscriptionID": subscriptionID,
          "verificationData": verificationData,
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      final subscription = Subscription.fromMap(response.data["subscription"]);
      await setSubscription(subscription);
      return subscription;
    } catch (e) {
      throw e;
    }
  }

  // TODO: Fetch new subscription once the current one has expired?
  Subscription getSubscription() {
    final jsonValue = _prefs.getString(subscriptionKey);
    if (jsonValue == null) {
      return null;
    } else {
      return Subscription.fromJson(jsonValue);
    }
  }

  bool hasActiveSubscription() {
    final subscription = getSubscription();
    return subscription != null &&
        subscription.expiryTime > DateTime.now().microsecondsSinceEpoch;
  }

  Future<void> setSubscription(Subscription subscription) async {
    await _prefs.setString(
        subscriptionKey, subscription == null ? null : subscription.toJson());
  }

  void setIsOnSubscriptionPage(bool isOnSubscriptionPage) {
    _isOnSubscriptionPage = isOnSubscriptionPage;
  }
}
