# In App Purchase

A Flutter plugin for in-app purchases. Exposes APIs for making in-app purchases
through the App Store (on iOS) and Google Play (on Android).

## Features

Add this to your Flutter app to:

1. Show in app products that are available for sale from the underlying shop.
   Includes consumables, permanent upgrades, and subscriptions.
2. Load in app products currently owned by the user according to the underlying
   shop.
3. Send your user to the underlying store to purchase your products.

## Getting Started

This plugin is in beta. Please use with caution and file any potential issues
you see on our [issue tracker](https://github.com/flutter/flutter/issues/new/choose).

This plugin relies on the App Store and Google Play for making in app purchases.
It exposes a unified surface, but you'll still need to understand and configure
your app with each store to handle purchases using them. Both have extensive
guides:

* [In-App Purchase (App Store)](https://developer.apple.com/in-app-purchase/)
* [Google Play Biling Overview](https://developer.android.com/google/play/billing/billing_overview)

You can check out the [example app README](https://github.com/flutter/plugins/blob/master/packages/in_app_purchase/example/README.md) for steps on how
to configure in app purchases in both stores.

Once you've configured your in app purchases in their respective stores, you're
able to start using the plugin. There's two basic options available to you to
use.

1. [in_app_purchase.dart](https://github.com/flutter/plugins/tree/master/packages/in_app_purchase/lib/src/in_app_purchase),
   the generic idiommatic Flutter API. This exposes the most basic IAP-related
   functionality. The goal is that Flutter apps should be able to use this API
   surface on its own for the vast majority of cases. If you use this you should
   be able to handle most use cases for loading and making purchases. If you would
   like a more platform dependent approach, we also provide the second option as
   below.

2. Dart APIs exposing the underlying platform APIs as directly as possible:
   [store_kit_wrappers.dart](https://github.com/flutter/plugins/blob/master/packages/in_app_purchase/lib/src/store_kit_wrappers) and
   [billing_client_wrappers.dart](https://github.com/flutter/plugins/blob/master/packages/in_app_purchase/lib/src/billing_client_wrappers). These
   API surfaces should expose all the platform-specific behavior and allow for
   more fine-tuned control when needed. However if you use this you'll need to
   code your purchase handling logic significantly differently depending on
   which platform you're on.

### Initializing the plugin

```dart
void main() {
  // Inform the plugin that this app supports pending purchases on Android.
  // An error will occur on Android if you access the plugin `instance`
  // without this call.
  //
  // On iOS this is a no-op.
  InAppPurchaseConnection.enablePendingPurchases();
  
  runApp(MyApp());
}
```

```dart
// Subscribe to any incoming purchases at app initialization. These can
// propagate from either storefront so it's important to listen as soon as
// possible to avoid losing events.
class _MyAppState extends State<MyApp> {
  StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    final Stream purchaseUpdates =
        InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdates.listen((purchases) {
      _handlePurchaseUpdates(purchases);
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
```

### Connecting to the Storefront

```dart
final bool available = await InAppPurchaseConnection.instance.isAvailable();
if (!available) {
  // The store cannot be reached or accessed. Update the UI accordingly.
}
```

### Loading products for sale

```dart
// Set literals require Dart 2.2. Alternatively, use `Set<String> _kIds = <String>['product1', 'product2'].toSet()`.
const Set<String> _kIds = {'product1', 'product2'};
final ProductDetailsResponse response = await InAppPurchaseConnection.instance.queryProductDetails(_kIds);
if (response.notFoundIDs.isNotEmpty) {
    // Handle the error.
}
List<ProductDetails> products = response.productDetails;
```

### Loading previous purchases

```dart
final QueryPurchaseDetailsResponse response = await InAppPurchaseConnection.instance.queryPastPurchases();
if (response.error != null) {
    // Handle the error.
}
for (PurchaseDetails purchase in response.pastPurchases) {
    _verifyPurchase(purchase);  // Verify the purchase following the best practices for each storefront.
    _deliverPurchase(purchase); // Deliver the purchase to the user in your app.
    if (Platform.isIOS) {
        // Mark that you've delivered the purchase. Only the App Store requires
        // this final confirmation.
        InAppPurchaseConnection.instance.completePurchase(purchase);
    }
}
```

Note that the App Store does not have any APIs for querying consumable
products, and Google Play considers consumable products to no longer be owned
once they're marked as consumed and fails to return them here. For restoring
these across devices you'll need to persist them on your own server and query
that as well.

### Listening to purchase updates

You should always start listening to purchase update as early as possible to be able
to catch all purchase updates, including the ones from the previous app session.
To listen to the update:

```dart
  Stream purchaseUpdated =
      InAppPurchaseConnection.instance.purchaseUpdatedStream;
  _subscription = purchaseUpdated.listen((purchaseDetailsList) {
    _listenToPurchaseUpdated(purchaseDetailsList);
  }, onDone: () {
    _subscription.cancel();
  }, onError: (error) {
    // handle error here.
  });
```

### Making a purchase

Both storefronts handle consumable and non-consumable products differently. If
you're using `InAppPurchaseConnection`, you need to make a distinction here and
call the right purchase method for each type.

```dart
final ProductDetails productDetails = ... // Saved earlier from queryPastPurchases().
final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
if (_isConsumable(productDetails)) {
    InAppPurchaseConnection.instance.buyConsumable(purchaseParam: purchaseParam);
} else {
    InAppPurchaseConnection.instance.buyNonConsumable(purchaseParam: purchaseParam);
}
// From here the purchase flow will be handled by the underlying storefront.
// Updates will be delivered to the `InAppPurchaseConnection.instance.purchaseUpdatedStream`.
```

### Complete a purchase

The `InAppPurchaseConnection.purchaseUpdatedStream` will send purchase updates after
you initiate the purchase flow using `InAppPurchaseConnection.buyConsumable` or `InAppPurchaseConnection.buyNonConsumable`.
After delivering the content to the user, you need to call `InAppPurchaseConnection.completePurchase` to tell the `GooglePlay`
and `AppStore` that the purchase has been finished.

WARNING! Failure to call `InAppPurchaseConnection.completePurchase` and get a successful response within 3 days of the purchase will result a refund.

### Upgrading or Downgrading an existing InApp Subscription

In order to upgrade/downgrade an existing InApp subscription on `PlayStore`, 
you need to provide an instance of `ChangeSubscriptionParam` with the old 
`PurchaseDetails` that the user needs to migrate from, and an optional `ProrationMode`
with the `PurchaseParam` object while calling `InAppPurchaseConnection.buyNonConsumable`.
`AppStore` does not require this since they provides a subscription grouping mechanism. 
Each subscription you offer must be assigned to a subscription group. 
So the developers can group related subscriptions together to prevents users from 
accidentally purchasing multiple subscriptions.
Please refer to the 'Creating a Subscription Group' sections of [Apple's subscription guide](https://developer.apple.com/app-store/subscriptions/)


```dart
final PurchaseDetails oldPurchaseDetails = ...;
PurchaseParam purchaseParam = PurchaseParam(
    productDetails: productDetails,
    changeSubscriptionParam: ChangeSubscriptionParam(
        oldPurchaseDetails: oldPurchaseDetails,
        prorationMode: ProrationMode.immediateAndChargeProratedPrice));
InAppPurchaseConnection.instance
    .buyNonConsumable(purchaseParam: purchaseParam);
```

## Development

This plugin uses
[json_serializable](https://pub.dev/packages/json_serializable) for the
many data structs passed between the underlying platform layers and Dart. After
editing any of the serialized data structs, rebuild the serializers by running
`flutter packages pub run build_runner build --delete-conflicting-outputs`.
`flutter packages pub run build_runner watch --delete-conflicting-outputs` will
watch the filesystem for changes.
