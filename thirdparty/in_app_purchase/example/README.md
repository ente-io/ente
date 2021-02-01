# In App Purchase Example

Demonstrates how to use the In App Purchase (IAP) Plugin.

## Getting Started

This plugin is in beta. Please use with caution and file any potential issues
you see on our [issue tracker](https://github.com/flutter/flutter/issues/new/choose).

There's a significant amount of setup required for testing in app purchases
successfully, including registering new app IDs and store entries to use for
testing in both the Play Developer Console and App Store Connect. Both Google
Play and the App Store require developers to configure an app with in-app items
for purchase to call their in-app-purchase APIs. Both stores have extensive
documentation on how to do this, and we've also included a high level guide
below.

* [In-App Purchase (App Store)](https://developer.apple.com/in-app-purchase/)
* [Google Play Biling Overview](https://developer.android.com/google/play/billing/billing_overview)

### Android

1. Create a new app in the [Play Developer
   Console](https://play.google.com/apps/publish/) (PDC).

2. Sign up for a merchant's account in the PDC.

3. Create IAPs in the PDC available for purchase in the app. The example assumes
   the following SKU IDs exist:

   - `consumable`: A managed product.
   - `upgrade`: A managed product.
   - `subscription`: A subscription.

   Make sure that all of the products are set to `ACTIVE`.

4. Update `APP_ID` in `example/android/app/build.gradle` to match your package
   ID in the PDC.

5. Create an `example/android/keystore.properties` file with all your signing
   information. `keystore.example.properties` exists as an example to follow.
   It's impossible to use any of the `BillingClient` APIs from an unsigned APK.
   See
   [here](https://developer.android.com/studio/publish/app-signing#secure-shared-keystore)
   and [here](https://developer.android.com/studio/publish/app-signing#sign-apk)
   for more information.

6. Build a signed apk. `flutter build apk` will work for this, the gradle files
   in this project have been configured to sign even debug builds.

7. Upload the signed APK from step 6 to the PDC, and publish that to the alpha
   test channel. Add your test account as an approved tester. The
   `BillingClient` APIs won't work unless the app has been fully published to
   the alpha channel and is being used by an authorized test account. See
   [here](https://support.google.com/googleplay/android-developer/answer/3131213)
   for more info.

8. Sign in to the test device with the test account from step #7. Then use
   `flutter run` to install the app to the device and test like normal.

### iOS

1. Follow ["Workflow for configuring in-app
   purchases"](https://help.apple.com/app-store-connect/#/devb57be10e7), a
   detailed guide on all the steps needed to enable IAPs for an app. Complete
   steps 1 ("Sign a Paid Applications Agreement") and 2 ("Configure in-app
   purchases").

   For step #2, "Configure in-app purchases in App Store Connect," you'll want
   to create the following products:

   - A consumable with product ID `consumable`
   - An upgrade with product ID `upgrade`
   - An auto-renewing subscription with product ID `subscription`

2. In XCode, `File > Open File` `example/ios/Runner.xcworkspace`. Update the
   Bundle ID to match the Bundle ID of the app created in step #1.

3. [Create a Sandbox tester
   account](https://help.apple.com/app-store-connect/#/dev8b997bee1) to test the
   in-app purchases with.

4. Use `flutter run` to install the app and test it. Note that you need to test
   it on a real device instead of a simulator, and signing into any production
   service (including iTunes!) with the test account will permanently invalidate
   it. Sign in to the test account in the example app following the steps in the
   [*In-App Purchase Programming
   Guide*](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/ShowUI.html#//apple_ref/doc/uid/TP40008267-CH3-SW11).