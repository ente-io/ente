import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/errors.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/api/billing/billing_plan.dart';
import 'package:photos/models/api/billing/subscription.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/account/user_service.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/utils/dialog_util.dart';

const kWebPaymentRedirectUrl = String.fromEnvironment(
  "web-payment-redirect",
  defaultValue: "https://payments.ente.io/frameRedirect",
);

const kWebPaymentBaseEndpoint = String.fromEnvironment(
  "web-payment",
  defaultValue: "https://payments.ente.io",
);

class BillingService {
  late final _logger = Logger("BillingService");
  final Dio _enteDio;

  bool _isOnSubscriptionPage = false;

  Future<BillingPlans>? _future;
  BillingService(this._enteDio) {
    _logger.info("BillingService constructor");
    init();
  }

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
            InAppPurchase.instance.completePurchase(purchase);
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
    _future ??= _fetchBillingPlans().then((response) {
      return BillingPlans.fromMap(response.data);
    });
    return _future!;
  }

  Future<Response<dynamic>> _fetchBillingPlans() {
    return _enteDio.get("/billing/user-plans/");
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
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 409) {
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
    } on DioException catch (e, s) {
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
    } on DioException catch (e, s) {
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
    } on DioException catch (e, s) {
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
    } on DioException catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  void setIsOnSubscriptionPage(bool isOnSubscriptionPage) {
    _isOnSubscriptionPage = isOnSubscriptionPage;
  }

  Future<void> launchFamilyPortal(
    BuildContext context,
    UserDetails userDetails,
  ) async {
    if (userDetails.subscription.productID == freeProductID &&
        !userDetails.hasPaidAddon()) {
      await showErrorDialog(
        context,
        AppLocalizations.of(context).familyPlans,
        AppLocalizations.of(context).familyPlanOverview,
      );
      return;
    }
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).pleaseWait,
      isDismissible: true,
    );
    await dialog.show();
    try {
      final bool familyExist = userDetails.isPartOfFamily();
      final String url =
          await UserService.instance.getFamilyPortalUrl(familyExist);

      await dialog.hide();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return WebPage(
              AppLocalizations.of(context).familyPlanPortalTitle,
              url,
            );
          },
        ),
      );
    } catch (e) {
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }
}
