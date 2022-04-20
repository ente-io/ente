import 'package:flutter/cupertino.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/payment/stripe_subscription_page.dart';
import 'package:photos/ui/payment/subscription_page.dart';

StatefulWidget getSubscriptionPage({bool isOnBoarding = false}) {
  if (UpdateService.instance.isIndependentFlavor()) {
    return StripeSubscriptionPage(isOnboarding: isOnBoarding);
  }
  if (FeatureFlagService.instance.enableStripe() &&
      _isUserCreatedPostStripeSupport()) {
    return StripeSubscriptionPage(isOnboarding: isOnBoarding);
  } else {
    return SubscriptionPage(isOnboarding: isOnBoarding);
  }
}

// return true if the user was created after we added support for stripe payment
// on frame. We do this check to avoid showing Stripe payment option for earlier
// users who might have paid via playStore. This method should be removed once
// we have better handling for active play/app store subscription & stripe plans.
bool _isUserCreatedPostStripeSupport() {
  return Configuration.instance.getUserID() > 1580559962386460;
}
