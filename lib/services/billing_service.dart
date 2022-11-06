// @dart=2.9

import 'dart:io';

import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';

const kWebPaymentRedirectUrl = "https://payments.ente.io/frameRedirect";
const kWebPaymentBaseEndpoint = String.fromEnvironment(
  "web-payment",
  defaultValue: "https://payments.ente.io",
);

const kFamilyPlanManagementUrl = String.fromEnvironment(
  "web-family",
  defaultValue: "https://family.ente.io",
);

class BillingService {
  BillingService._privateConstructor();

  static final BillingService instance = BillingService._privateConstructor();

  final _logger = Logger("BillingService");
  final _dio = Network.instance.getDio();
  final _enteDio = Network.instance.enteDio;
  final _config = Configuration.instance;

  bool _isOnSubscriptionPage = false;

  Future<BillingPlans> _future;

  void init() {
    // if (Platform.isIOS && kDebugMode) {
    //   await FlutterInappPurchase.instance.initConnection;
    //   FlutterInappPurchase.instance.clearTransactionIOS();
    // }
    InAppPurchase.instance.purchaseStream.listen((purchases) {
      if (_isOnSubscriptionPage) {
        return;
      }
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          verifySubscription(
            purchase.productID,
            purchase.verificationData.serverVerificationData,
          ).then((response) {
            if (response != null) {
              InAppPurchase.instance.completePurchase(purchase);
            }
          });
        } else if (Platform.isIOS && purchase.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(purchase);
        }
      }
    });
  }

  void clearCache() {
    _future = null;
  }

  Future<BillingPlans> getBillingPlans() {
    _future ??= (_config.isLoggedIn()
            ? _fetchPublicBillingPlans()
            : _fetchPrivateBillingPlans())
        .then((response) {
      return BillingPlans.fromMap(response.data);
    });
    return _future;
  }

  Future<Response<dynamic>> _fetchPrivateBillingPlans() {
    return _enteDio.get("/billing/user-plans/");
  }

  Future<Response<dynamic>> _fetchPublicBillingPlans() {
    return _dio.get(_config.getHttpEndpoint() + "/billing/plans/v2");
  }

  Future<Subscription> verifySubscription(
    final productID,
    final verificationData, {
    final paymentProvider,
  }) async {
    try {
      final response = await _enteDio.post(
        "/billing/verify-subscription",
        data: {
          "paymentProvider": paymentProvider ??
              (Platform.isAndroid ? "playstore" : "appstore"),
          "productID": productID,
          "verificationData": verificationData,
        },
      );
      return Subscription.fromMap(response.data["subscription"]);
    } on DioError catch (e) {
      if (e.response != null && e.response.statusCode == 409) {
        throw SubscriptionAlreadyClaimedError();
      } else {
        rethrow;
      }
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Subscription> fetchSubscription() async {
    try {
      final response = await _enteDio.get("/billing/subscription");
      final subscription = Subscription.fromMap(response.data["subscription"]);
      return subscription;
    } on DioError catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Subscription> cancelStripeSubscription() async {
    try {
      final response =
          await _enteDio.post("/billing/stripe/cancel-subscription");
      final subscription = Subscription.fromMap(response.data["subscription"]);
      return subscription;
    } on DioError catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Subscription> activateStripeSubscription() async {
    try {
      final response =
          await _enteDio.post("/billing/stripe/activate-subscription");
      final subscription = Subscription.fromMap(response.data["subscription"]);
      return subscription;
    } on DioError catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<String> getStripeCustomerPortalUrl({
    String endpoint = kWebPaymentRedirectUrl,
  }) async {
    try {
      final response = await _enteDio.get(
        "/billing/stripe/customer-portal",
        queryParameters: {
          "redirectURL": kWebPaymentRedirectUrl,
        },
      );
      return response.data["url"];
    } on DioError catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  void setIsOnSubscriptionPage(bool isOnSubscriptionPage) {
    _isOnSubscriptionPage = isOnSubscriptionPage;
  }
}
