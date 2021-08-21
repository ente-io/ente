import 'package:flutter/cupertino.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/payment/stripe_subscription_page.dart';
import 'package:photos/ui/payment/subscription_page.dart';

StatefulWidget getSubscriptionPage({bool isOnBoarding = false}) {
  if (!UpdateService.instance.isIndependentFlavor()) {
    return StripeSubscriptionPage(isOnboarding: isOnBoarding);
  } else {
    return SubscriptionPage(isOnboarding: isOnBoarding);
  }
}