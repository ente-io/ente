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

class BillingService {
  BillingService._privateConstructor();

  static final BillingService instance = BillingService._privateConstructor();

  final _logger = Logger("BillingService");
  final _dio = Network.instance.getDio();
  final _config = Configuration.instance;

  bool _isOnSubscriptionPage = false;

  Future<BillingPlans> _future;

  Future<void> init() async {
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
    _future ??=
        _dio.get(_config.getHttpEndpoint() + "/billing/plans").then((response) {
      return BillingPlans.fromMap(response.data);
    });
    return _future;
  }

  Future<Subscription> verifySubscription(
    final productID,
    final verificationData, {
    final paymentProvider,
  }) async {
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/billing/verify-subscription",
        data: {
          "paymentProvider": paymentProvider ??
              (Platform.isAndroid ? "playstore" : "appstore"),
          "productID": productID,
          "verificationData": verificationData,
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      return Subscription.fromMap(response.data["subscription"]);
    } catch (e) {
      rethrow;
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
      return subscription;
    } on DioError catch (e) {
      _logger.severe(e);
      rethrow;
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
      rethrow;
    }
  }

  void setIsOnSubscriptionPage(bool isOnSubscriptionPage) {
    _isOnSubscriptionPage = isOnSubscriptionPage;
  }
}
