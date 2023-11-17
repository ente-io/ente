import "dart:io";

import "package:flutter/foundation.dart";
import "package:photos/services/user_service.dart";

bool shouldShowBfBanner() {
  if (!Platform.isAndroid && !kDebugMode) {
    return false;
  }
  // if date is after 5th of December 2023, 00:00:00, hide banner
  if (DateTime.now().isAfter(DateTime(2023, 12, 5))) {
    return false;
  }
  // if coupon is already applied, can hide the banner
  return (UserService.instance
          .getCachedUserDetails()
          ?.bonusData
          ?.getAddOnBonuses()
          .isEmpty ??
      true);
}
