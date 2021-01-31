import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
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
    await FlutterInappPurchase.instance.initConnection;
    if (kDebugMode && Platform.isIOS) {
      FlutterInappPurchase.instance.clearTransactionIOS();
    }
    FlutterInappPurchase.purchaseUpdated.listen((item) {
      if (_isOnSubscriptionPage) {
        return;
      }
      verifySubscription(item.productId,
              Platform.isAndroid ? item.purchaseToken : item.transactionReceipt)
          .then((response) {
        if (response != null) {
          FlutterInappPurchase.instance.finishTransaction(item);
        }
      });
    });
    if (_config.hasConfiguredAccount() && !hasActiveSubscription()) {
      fetchSubscription();
    }
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
      final productID, final verificationData) async {
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/billing/verify-subscription",
        data: {
          "paymentProvider": Platform.isAndroid ? "playstore" : "appstore",
          "productID": productID,
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

  Future<Subscription> fetchSubscription() async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/billing/subscription",
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
