## 0.3.6

* Support InApp subscription upgrade/downgrade.

## 0.3.5+1

* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.

## 0.3.5

* [Android] Fixed: added support for the SERVICE_TIMEOUT (-3) response code.

## 0.3.4+18

* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 0.3.4+17

* Update Flutter SDK constraint.

## 0.3.4+16

* Add Dartdocs to all public APIs.

## 0.3.4+15

* Update android compileSdkVersion to 29.

## 0.3.4+14

* Add test target to iOS example app Podfile

## 0.3.4+13

* Android Code Inspection and Clean up.

## 0.3.4+12

* [iOS] Fixed: finishing purchases upon payment dialog cancellation.

## 0.3.4+11

* [iOS] Fixed: crash when sending null for simulatesAskToBuyInSandbox parameter.

## 0.3.4+10

* Fixed typo 'verity' for 'verify'.

## 0.3.4+9

* [iOS] Fixed: purchase dialog not showing always.
* [iOS] Fixed: completing purchases could fail.
* [iOS] Fixed: restorePurchases caused hang (call never returned).

## 0.3.4+8

* [iOS] Fixed: purchase dialog not showing always.
* [iOS] Fixed: completing purchases could fail.
* [iOS] Fixed: restorePurchases caused hang (call never returned).

## 0.3.4+7

* iOS: Fix typo of the `simulatesAskToBuyInSandbox` key.

## 0.3.4+6

* iOS: Fix the bug that prevent restored subscription transactions from being completed

## 0.3.4+5

* Added necessary README docs for getting started with Android.

## 0.3.4+4

* Update package:e2e -> package:integration_test

## 0.3.4+3

* Fixed typo 'manuelly' for 'manually'.

## 0.3.4+2

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 0.3.4+1

* iOS: Fix the bug that `SKPaymentQueueWrapper.transactions` doesn't return all transactions.
* iOS: Fix the app crashes  if `InAppPurchaseConnection.instance` is called in the `main()`.

## 0.3.4

* Expose SKError code to client apps.

## 0.3.3+2

* Post-v2 Android embedding cleanups.

## 0.3.3+1

* Update documentations for `InAppPurchase.completePurchase` and update README.

## 0.3.3

* Introduce `SKPaymentQueueWrapper.transactions`.

## 0.3.2+2

* Fix CocoaPods podspec lint warnings.

## 0.3.2+1

* iOS: Fix only transactions with SKPaymentTransactionStatePurchased and SKPaymentTransactionStateFailed can be finished.
* iOS: Only one pending transaction of a given product is allowed.

## 0.3.2

* Remove Android dependencies fallback.
* Require Flutter SDK 1.12.13+hotfix.5 or greater.

## 0.3.1+2

* Fix potential casting crash on Android v1 embedding when registering life cycle callbacks.
* Remove hard-coded legacy xcode build setting.

## 0.3.1+1

* Add `pedantic` to dev_dependency.

## 0.3.1

* Android: Fix a bug where the `BillingClient` is disconnected when app goes to the background.
* Android: Make sure the `BillingClient` object is disconnected before the activity is destroyed.
* Android: Fix minor compiler warning.
* Fix typo in CHANGELOG.

## 0.3.0+3

* Fix pendingCompletePurchase flag status to allow to complete purchases.

## 0.3.0+2

* Update te example app to avoid using deprecated api.

## 0.3.0+1

* Fixing usage example. No functional changes.

## 0.3.0

* Migrate the `Google Play Library` to 2.0.3.
     * Introduce a new class `BillingResultWrapper` which contains a detailed result of a BillingClient operation.
          * **[Breaking Change]:**  All the BillingClient methods that previously return a `BillingResponse` now return a `BillingResultWrapper`, including: `launchBillingFlow`, `startConnection` and `consumeAsync`.
          * **[Breaking Change]:**  The `SkuDetailsResponseWrapper` now contains a `billingResult` field in place of `billingResponse` field.
          * A `billingResult` field is added to the `PurchasesResultWrapper`.
     * Other Updates to the "billing_client_wrappers":
          * Updates to the `PurchaseWrapper`: Add `developerPayload`, `purchaseState` and `isAcknowledged` fields.
          * Updates to the `SkuDetailsWrapper`: Add `originalPrice` and `originalPriceAmountMicros` fields.
          * **[Breaking Change]:** The `BillingClient.queryPurchaseHistory` is updated to return a `PurchasesHistoryResult`, which contains a list of `PurchaseHistoryRecordWrapper` instead of `PurchaseWrapper`. A `PurchaseHistoryRecordWrapper` object has the same fields and values as A `PurchaseWrapper` object, except that a `PurchaseHistoryRecordWrapper` object does not contain `isAutoRenewing`, `orderId` and `packageName`.
          * Add a new `BillingClient.acknowledgePurchase` API. Starting from this version, the developer has to acknowledge any purchase on Android using this API within 3 days of purchase, or the user will be refunded. Note that if a product is "consumed" via `BillingClient.consumeAsync`, it is implicitly acknowledged.
          * **[Breaking Change]:**  Added `enablePendingPurchases` in `BillingClientWrapper`. The application has to call this method before calling `BillingClientWrapper.startConnection`. See [enablePendingPurchases](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.Builder.html#enablependingpurchases) for more information.
     * Updates to the "InAppPurchaseConnection":
          * **[Breaking Change]:** `InAppPurchaseConnection.completePurchase` now returns a `Future<BillingResultWrapper>` instead of `Future<void>`. A new optional parameter `{String developerPayload}` has also been added to the API. On Android, this API does not throw an exception anymore, it instead acknowledge the purchase. If a purchase is not completed within 3 days on Android, the user will be refunded.
          * **[Breaking Change]:** `InAppPurchaseConnection.consumePurchase` now returns a `Future<BillingResultWrapper>` instead of `Future<BillingResponse>`. A new optional parameter `{String developerPayload}` has also been added to the API.
          * A new boolean field `pendingCompletePurchase` has been added to the `PurchaseDetails` class. Which can be used as an indicator of whether to call `InAppPurchaseConnection.completePurchase` on the purchase.
          * **[Breaking Change]:**  Added `enablePendingPurchases` in `InAppPurchaseConnection`. The application has to call this method when initializing the `InAppPurchaseConnection` on Android. See [enablePendingPurchases](https://developer.android.com/reference/com/android/billingclient/api/BillingClient.Builder.html#enablependingpurchases) for more information.
     * Misc: Some documentation updates reflecting the `BillingClient` migration and some documentation fixes.
     * Refer to [Google Play Billing Library Release Note](https://developer.android.com/google/play/billing/billing_library_releases_notes#release-2_0) for a detailed information on the update.

## 0.2.2+6

* Correct a comment.

## 0.2.2+5

* Update version of json_annotation to ^3.0.0 and json_serializable to ^3.2.0. Resolve conflicts with other packages e.g. flutter_tools from sdk.

## 0.2.2+4

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.2.2+3

* Fix failing pedantic lints. None of these fixes should have any change in
  functionality.

## 0.2.2+2

* Include lifecycle dependency as a compileOnly one on Android to resolve
  potential version conflicts with other transitive libraries.

## 0.2.2+1

* Android: Use android.arch.lifecycle instead of androidx.lifecycle:lifecycle in `build.gradle` to support apps that has not been migrated to AndroidX.

## 0.2.2

* Support the v2 Android embedder.
* Update to AndroidX.
* Migrate to using the new e2e test binding.
* Add a e2e test.

## 0.2.1+5

* Define clang module for iOS.
* Fix iOS build warning.

## 0.2.1+4

* Update and migrate iOS example project.

## 0.2.1+3

* Android : Improved testability.

## 0.2.1+2

* Android: Require a non-null Activity to use the `launchBillingFlow` method.

## 0.2.1+1

* Remove skipped driver test.

## 0.2.1

* iOS: Add currencyCode to priceLocale on productDetails.

## 0.2.0+8

* Add dependency on `androidx.annotation:annotation:1.0.0`.

## 0.2.0+7

* Make Gradle version compatible with the Android Gradle plugin version.

## 0.2.0+6

* Add missing `hashCode` implementations.

## 0.2.0+5

* iOS: Support unsupported UserInfo value types on NSError.

## 0.2.0+4

* Fixed code error in `README.md` and adjusted links to work on Pub.

## 0.2.0+3

* Update the `README.md` so that the code samples compile with the latest Flutter/Dart version.

## 0.2.0+2

* Fix a google_play_connection purchase update listener regression introduced in 0.2.0+1.

## 0.2.0+1

* Fix an issue the type is not casted before passing to `PurchasesResultWrapper.fromJson`.

## 0.2.0

* [Breaking Change] Rename 'PurchaseError' to 'IAPError'.
* [Breaking Change] Rename 'PurchaseSource' to 'IAPSource'.

## 0.1.1+3

* Expanded description in `pubspec.yaml` and fixed typo in `README.md`.

## 0.1.1+2

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.1.1+1

* Make `AdditionalSteps`(Used in the unit test) a void function.

## 0.1.1

* Some error messages from iOS are slightly changed.
* `ProductDetailsResponse` returned by `queryProductDetails()` now contains an `PurchaseError` object that represents any error that might occurred during the request.
* If the device is not connected to the internet, `queryPastPurchases()` on iOS now have the error stored in the response instead of throwing.
* Clean up minor iOS warning.
* Example app shows how to handle error when calling `queryProductDetails()` and `queryProductDetails()`.

## 0.1.0+4

* Change the `buy` methods to return `Future<bool>` instead of `void` in order
  to propagate `launchBillingFlow` failures up through `google_play_connection`.

## 0.1.0+3

* Guard against multiple onSetupFinished() calls.

## 0.1.0+2

* Fix bug where error only purchases updates weren't propagated correctly in
  `google_play_connection.dart`.

## 0.1.0+1

* Add more consumable handling to the example app.

## 0.1.0

Beta release.

* Ability to list products, load previous purchases, and make purchases.
* Simplified Dart API that's been unified for ease of use.
* Platform specific APIs more directly exposing `StoreKit` and `BillingClient`.

Includes:

* 5ba657dc [in_app_purchase] Remove extraneous download logic (#1560)
* 01bb8796 [in_app_purchase] Minor doc updates (#1555)
* 1a4d493f [in_app_purchase] Only fetch owned purchases (#1540)
* d63c51cf [in_app_purchase] Add auto-consume errors to PurchaseDetails (#1537)
* 959da97f [in_app_purchase] Minor doc updates (#1536)
* b82ae1a6 [in_app_purchase] Rename the unified API (#1517)
* d1ad723a [in_app_purchase]remove SKDownloadWrapper and related code. (#1474)
* 7c1e8b8a [in_app_purchase]make payment unified APIs (#1421)
* 80233db6 [in_app_purchase] Add references to the original object for PurchaseDetails and ProductDetails (#1448)
* 8c180f0d [in_app_purchase]load purchase (#1380)
* e9f141bc [in_app_purchase] Iap refactor (#1381)
* d3b3d60c add driver test command to cirrus (#1342)
* aee12523 [in_app_purchase] refactoring and tests (#1322)
* 6d7b4592 [in_app_purchase] Adds Dart BillingClient APIs for loading purchases (#1286)
* 5567a9c8 [in_app_purchase]retrieve receipt (#1303)
* 3475f1b7 [in_app_purchase]restore purchases (#1299)
* a533148d [in_app_purchase] payment queue dart ios (#1249)
* 10030840 [in_app_purchase] Minor bugfixes and code cleanup (#1284)
* 347f508d [in_app_purchase] Fix CI formatting errors. (#1281)
* fad02d87 [in_app_purchase] Java API for querying purchases (#1259)
* bc501915 [In_app_purchase]SKProduct related fixes (#1252)
* f92ba3a1 IAP make payment objc (#1231)
* 62b82522 [IAP] Add the Dart API for launchBillingFlow (#1232)
* b40a4acf [IAP] Add Java call for launchBillingFlow (#1230)
* 4ff06cd1 [In_app_purchase]remove categories (#1222)
* 0e72ca56 [In_app_purchase]fix requesthandler crash (#1199)
* 81dff2be Iap getproductlist basic draft (#1169)
* db139b28 Iap iOS add payment dart wrappers (#1178)
* 2e5fbb9b Fix the param map passed down to the platform channel when calling querySkuDetails (#1194)
* 4a84bac1 Mark some packages as unpublishable (#1193)
* 51696552 Add a gradle warning to the AndroidX plugins (#1138)
* 832ab832 Iap add payment objc translators (#1172)
* d0e615cf Revert "IAP add payment translators in objc (#1126)" (#1171)
* 09a5a36e IAP add payment translators in objc (#1126)
* a100fbf9 Expose nslocale and expose currencySymbol instead of currencyCode to match android (#1162)
* 1c982efd Using json serializer for skproduct wrapper and related classes (#1147)
* 3039a261 Iap productlist ios (#1068)
* 2a1593da [IAP] Update dev deps to match flutter_driver (#1118)
* 9f87cbe5 [IAP] Update README (#1112)
* 59e84d85 Migrate independent plugins to AndroidX (#1103)
* a027ccd6 [IAP] Generate boilerplate serializers (#1090)
* 909cf1c2 [IAP] Fetch SkuDetails from Google Play (#1084)
* 6bbaa7e5 [IAP] Add missing license headers (#1083)
* 5347e877 [IAP] Clean up Dart unit tests (#1082)
* fe03e407 [IAP] Check if the payment processor is available (#1057)
* 43ee28cf Fix `Manifest versionCode not found` (#1076)
* 4d702ad7 Supress `strong_mode_implicit_dynamic_method` for `invokeMethod` calls. (#1065)
* 809ccde7 Doc and build script updates to the IAP plugin (#1024)
* 052b71a9 Update the IAP README (#933)
* 54f9c4e2 Upgrade Android Gradle Plugin to 3.2.1 (#916)
* ced3e99d Set all gradle-wrapper versions to 4.10.2 (#915)
* eaa1388b Reconfigure Cirrus to use clang 7 (#905)
* 9b153920 Update gradle dependencies. (#881)
* 1aef7d92 Enable lint unnecessary_new (#701)

## 0.0.2

* Added missing flutter_test package dependency.
* Added missing flutter version requirements.

## 0.0.1

* Initial release.
