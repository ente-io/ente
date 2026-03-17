import 'dart:io';

import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import "package:photos/gateways/billing/billing_gateway.dart";
import 'package:photos/gateways/billing/models/billing_plan.dart';
import 'package:photos/gateways/billing/models/subscription.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/user_details.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/account/user_service.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/family/family_plan_page.dart';
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

  bool _isOnSubscriptionPage = false;

  Future<BillingPlans>? _future;

  BillingGateway get _gateway => billingGateway;

  BillingService() {
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
    _future ??= _gateway.getUserPlans();
    return _future!;
  }

  Future<Subscription> verifySubscription(
    final productID,
    final verificationData, {
    final paymentProvider,
  }) async {
    try {
      return await _gateway.verifySubscription(
        productID: productID,
        verificationData: verificationData,
        paymentProvider:
            paymentProvider ?? (Platform.isAndroid ? "playstore" : "appstore"),
      );
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Subscription> fetchSubscription() async {
    try {
      return await _gateway.getSubscription();
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Subscription> cancelStripeSubscription() async {
    try {
      return await _gateway.cancelStripeSubscription();
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Subscription> activateStripeSubscription() async {
    try {
      return await _gateway.activateStripeSubscription();
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<String> getStripeCustomerPortalUrl({
    String endpoint = kWebPaymentRedirectUrl,
  }) async {
    try {
      return await _gateway.getStripeCustomerPortalUrl(
        redirectURL: kWebPaymentRedirectUrl,
      );
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  void setIsOnSubscriptionPage(bool isOnSubscriptionPage) {
    _isOnSubscriptionPage = isOnSubscriptionPage;
  }

  // Temporary rollout gate for the native family flow. When the native
  // experience is ready for all users, remove this getter and the legacy
  // launcher below, then call _launchNativeFamilyPortal directly.
  bool get _useNativeFamilyFlow => flagService.internalUser;

  Future<void> launchFamilyPortal(
    BuildContext context,
    UserDetails userDetails, {
    bool popOnFreeAdvertViewPlans = false,
    bool refreshOnOpen = true,
  }) async {
    try {
      if (_useNativeFamilyFlow) {
        await _launchNativeFamilyPortal(
          context,
          userDetails,
          popOnFreeAdvertViewPlans: popOnFreeAdvertViewPlans,
          refreshOnOpen: refreshOnOpen,
        );
        return;
      }

      await _launchLegacyFamilyPortal(context, userDetails);
    } catch (e) {
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _launchNativeFamilyPortal(
    BuildContext context,
    UserDetails userDetails, {
    required bool popOnFreeAdvertViewPlans,
    required bool refreshOnOpen,
  }) {
    return routeToPage(
      context,
      FamilyPlanPage(
        initialUserDetails: userDetails,
        popOnFreeAdvertViewPlans: popOnFreeAdvertViewPlans,
        refreshOnOpen: refreshOnOpen,
      ),
    );
  }

  Future<void> _launchLegacyFamilyPortal(
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
    var isDialogHidden = false;
    try {
      final familyExist = userDetails.isPartOfFamily();
      final url = await UserService.instance.getFamilyPortalUrl(familyExist);
      await dialog.hide();
      isDialogHidden = true;
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return WebPage(
              AppLocalizations.of(context).familyPlanPortalTitle,
              url,
            );
          },
        ),
      );
    } finally {
      if (!isDialogHidden) {
        await dialog.hide();
      }
    }
  }
}
