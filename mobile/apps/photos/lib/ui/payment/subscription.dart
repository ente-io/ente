import 'package:flutter/cupertino.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/service_locator.dart";
import "package:photos/ui/payment/store_subscription_page.dart";
import 'package:photos/ui/payment/stripe_subscription_page.dart';

StatefulWidget getSubscriptionPage({bool isOnBoarding = false}) {
  if (updateService.isIndependentFlavor()) {
    return StripeSubscriptionPage(isOnboarding: isOnBoarding);
  }
  if (flagService.enableStripe && _isUserCreatedPostStripeSupport()) {
    return StripeSubscriptionPage(isOnboarding: isOnBoarding);
  } else {
    return StoreSubscriptionPage(isOnboarding: isOnBoarding);
  }
}

// return true if the user was created after we added support for stripe payment
// on frame. We do this check to avoid showing Stripe payment option for earlier
// users who might have paid via playStore. This method should be removed once
// we have better handling for active play/app store subscription & stripe plans.
bool _isUserCreatedPostStripeSupport() {
  return Configuration.instance.getUserID()! > 1580559962386460;
}
