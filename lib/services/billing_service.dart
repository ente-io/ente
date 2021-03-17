import 'dart:io';

import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
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
  Future<BillingPlans> _future;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    InAppPurchaseConnection.enablePendingPurchases();
    // if (Platform.isIOS && kDebugMode) {
    //   await FlutterInappPurchase.instance.initConnection;
    //   FlutterInappPurchase.instance.clearTransactionIOS();
    // }
    InAppPurchaseConnection.instance.purchaseUpdatedStream.listen((purchases) {
      if (_isOnSubscriptionPage) {
        return;
      }
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          verifySubscription(purchase.productID,
                  purchase.verificationData.serverVerificationData)
              .then((response) {
            if (response != null) {
              InAppPurchaseConnection.instance.completePurchase(purchase);
            }
          });
        } else if (Platform.isIOS && purchase.pendingCompletePurchase) {
          InAppPurchaseConnection.instance.completePurchase(purchase);
        }
      }
    });
  }

  void clearCache() {
    _future = null;
  }

  Future<BillingPlans> getBillingPlans() {
    if (_future == null) {
      _future = _dio
          .get(_config.getHttpEndpoint() + "/billing/plans")
          .then((response) {
        return BillingPlans.fromMap(response.data);
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
    } on DioError catch (e) {
      if (e.response.statusCode == 404) {
        _prefs.remove(subscriptionKey);
      }
      throw e;
    }
  }

  Future<int> fetchUsage() async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/billing/usage",
        queryParameters: {
          "startTime": 0,
          "endTime": DateTime.now().microsecondsSinceEpoch,
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      return response.data["usage"];
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
