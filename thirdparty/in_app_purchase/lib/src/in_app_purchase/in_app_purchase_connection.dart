// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'app_store_connection.dart';
import 'google_play_connection.dart';
import 'product_details.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/billing_client_wrappers.dart';
import './purchase_details.dart';

export 'package:in_app_purchase/billing_client_wrappers.dart';

/// Basic API for making in app purchases across multiple platforms.
///
/// This is a generic abstraction built from `billing_client_wrapers` and
/// `store_kit_wrappers`. Either library can be used for their respective
/// platform instead of this.
abstract class InAppPurchaseConnection {
  /// Listen to this broadcast stream to get real time update for purchases.
  ///
  /// This stream will never close as long as the app is active.
  ///
  /// Purchase updates can happen in several situations:
  /// * When a purchase is triggered by user in the app.
  /// * When a purchase is triggered by user from App Store or Google Play.
  /// * If a purchase is not completed ([completePurchase] is not called on the
  ///   purchase object) from the last app session. Purchase updates will happen
  ///   when a new app session starts instead.
  ///
  /// IMPORTANT! You must subscribe to this stream as soon as your app launches,
  /// preferably before returning your main App Widget in main(). Otherwise you
  /// will miss purchase updated made before this stream is subscribed to.
  ///
  /// We also recommend listening to the stream with one subscription at a given
  /// time. If you choose to have multiple subscription at the same time, you
  /// should be careful at the fact that each subscription will receive all the
  /// events after they start to listen.
  Stream<List<PurchaseDetails>> get purchaseUpdatedStream => _getStream();

  Stream<List<PurchaseDetails>> _purchaseUpdatedStream;

  Stream<List<PurchaseDetails>> _getStream() {
    if (_purchaseUpdatedStream != null) {
      return _purchaseUpdatedStream;
    }

    if (Platform.isAndroid) {
      _purchaseUpdatedStream =
          GooglePlayConnection.instance.purchaseUpdatedStream;
    } else if (Platform.isIOS) {
      _purchaseUpdatedStream =
          AppStoreConnection.instance.purchaseUpdatedStream;
    } else {
      throw UnsupportedError(
          'InAppPurchase plugin only works on Android and iOS.');
    }
    return _purchaseUpdatedStream;
  }

  /// Whether pending purchase is enabled.
  ///
  /// See also [enablePendingPurchases] for more on pending purchases.
  static bool get enablePendingPurchase => _enablePendingPurchase;
  static bool _enablePendingPurchase = false;

  /// Returns true if the payment platform is ready and available.
  Future<bool> isAvailable();

  /// Enable the [InAppPurchaseConnection] to handle pending purchases.
  ///
  /// This method is required to be called when initialize the application.
  /// It is to acknowledge your application has been updated to support pending purchases.
  /// See [Support pending transactions](https://developer.android.com/google/play/billing/billing_library_overview#pending)
  /// for more details.
  /// Failure to call this method before access [instance] will throw an exception.
  ///
  /// It is an no-op on iOS.
  static void enablePendingPurchases() {
    _enablePendingPurchase = true;
  }

  /// Query product details for the given set of IDs.
  ///
  /// The [identifiers] need to exactly match existing configured product
  /// identifiers in the underlying payment platform, whether that's [App Store
  /// Connect](https://appstoreconnect.apple.com/) or [Google Play
  /// Console](https://play.google.com/).
  ///
  /// See the [example readme](../../../../example/README.md) for steps on how
  /// to initialize products on both payment platforms.
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  /// Buy a non consumable product or subscription.
  ///
  /// Non consumable items can only be bought once. For example, a purchase that
  /// unlocks a special content in your app. Subscriptions are also non
  /// consumable products.
  ///
  /// You always need to restore all the non consumable products for user when
  /// they switch their phones.
  ///
  /// This method does not return the result of the purchase. Instead, after
  /// triggering this method, purchase updates will be sent to
  /// [purchaseUpdatedStream]. You should [Stream.listen] to
  /// [purchaseUpdatedStream] to get [PurchaseDetails] objects in different
  /// [PurchaseDetails.status] and update your UI accordingly. When the
  /// [PurchaseDetails.status] is [PurchaseStatus.purchased] or
  /// [PurchaseStatus.error], you should deliver the content or handle the
  /// error, then call [completePurchase] to finish the purchasing process.
  ///
  /// This method does return whether or not the purchase request was initially
  /// sent successfully.
  ///
  /// Consumable items are defined differently by the different underlying
  /// payment platforms, and there's no way to query for whether or not the
  /// [ProductDetail] is a consumable at runtime. On iOS, products are defined
  /// as non consumable items in the [App Store
  /// Connect](https://appstoreconnect.apple.com/). [Google Play
  /// Console](https://play.google.com/) products are considered consumable if
  /// and when they are actively consumed manually.
  ///
  /// You can find more details on testing payments on iOS
  /// [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/ShowUI.html#//apple_ref/doc/uid/TP40008267-CH3-SW11).
  /// You can find more details on testing payments on Android
  /// [here](https://developer.android.com/google/play/billing/billing_testing).
  ///
  /// See also:
  ///
  ///  * [buyConsumable], for buying a consumable product.
  ///  * [queryPastPurchases], for restoring non consumable products.
  ///
  /// Calling this method for consumable items will cause unwanted behaviors!
  Future<bool> buyNonConsumable({@required PurchaseParam purchaseParam});

  /// Buy a consumable product.
  ///
  /// Consumable items can be "consumed" to mark that they've been used and then
  /// bought additional times. For example, a health potion.
  ///
  /// To restore consumable purchases across devices, you should keep track of
  /// those purchase on your own server and restore the purchase for your users.
  /// Consumed products are no longer considered to be "owned" by payment
  /// platforms and will not be delivered by calling [queryPastPurchases].
  ///
  /// Consumable items are defined differently by the different underlying
  /// payment platforms, and there's no way to query for whether or not the
  /// [ProductDetail] is a consumable at runtime. On iOS, products are defined
  /// as consumable items in the [App Store
  /// Connect](https://appstoreconnect.apple.com/). [Google Play
  /// Console](https://play.google.com/) products are considered consumable if
  /// and when they are actively consumed manually.
  ///
  /// `autoConsume` is provided as a utility for Android only. It's meaningless
  /// on iOS because the App Store automatically considers all potentially
  /// consumable purchases "consumed" once the initial transaction is complete.
  /// `autoConsume` is `true` by default, and we will call [consumePurchase]
  /// after a successful purchase for you so that Google Play considers a
  /// purchase consumed after the initial transaction, like iOS. If you'd like
  /// to manually consume purchases in Play, you should set it to `false` and
  /// manually call [consumePurchase] instead. Failing to consume a purchase
  /// will cause user never be able to buy the same item again. Manually setting
  /// this to `false` on iOS will throw an `Exception`.
  ///
  /// This method does not return the result of the purchase. Instead, after
  /// triggering this method, purchase updates will be sent to
  /// [purchaseUpdatedStream]. You should [Stream.listen] to
  /// [purchaseUpdatedStream] to get [PurchaseDetails] objects in different
  /// [PurchaseDetails.status] and update your UI accordingly. When the
  /// [PurchaseDetails.status] is [PurchaseStatus.purchased] or
  /// [PurchaseStatus.error], you should deliver the content or handle the
  /// error, then call [completePurchase] to finish the purchasing process.
  ///
  /// This method does return whether or not the purchase request was initially
  /// sent succesfully.
  ///
  /// See also:
  ///
  ///  * [buyNonConsumable], for buying a non consumable product or
  ///    subscription.
  ///  * [queryPastPurchases], for restoring non consumable products.
  ///  * [consumePurchase], for manually consuming products on Android.
  ///
  /// Calling this method for non consumable items will cause unwanted
  /// behaviors!
  Future<bool> buyConsumable(
      {@required PurchaseParam purchaseParam, bool autoConsume = true});

  /// Mark that purchased content has been delivered to the
  /// user.
  ///
  /// You are responsible for completing every [PurchaseDetails] whose
  /// [PurchaseDetails.status] is [PurchaseStatus.purchased]. Additionally on iOS,
  /// the purchase needs to be completed if the [PurchaseDetails.status] is [PurchaseStatus.error].
  /// Completing a [PurchaseStatus.pending] purchase will cause an exception.
  /// For convenience, [PurchaseDetails.pendingCompletePurchase] indicates if a purchase is pending for completion.
  ///
  /// The method returns a [BillingResultWrapper] to indicate a detailed status of the complete process.
  /// If the result contains [BillingResponse.error] or [BillingResponse.serviceUnavailable], the developer should try
  /// to complete the purchase via this method again, or retry the [completePurchase] it at a later time.
  /// If the result indicates other errors, there might be some issue with
  /// the app's code. The developer is responsible to fix the issue.
  ///
  /// Warning! Failure to call this method and get a successful response within 3 days of the purchase will result a refund on Android.
  /// The [consumePurchase] acts as an implicit [completePurchase] on Android.
  ///
  /// The optional parameter `developerPayload` only works on Android.
  Future<BillingResultWrapper> completePurchase(PurchaseDetails purchase,
      {String developerPayload});

  /// (Play only) Mark that the user has consumed a product.
  ///
  /// You are responsible for consuming all consumable purchases once they are
  /// delivered. The user won't be able to buy the same product again until the
  /// purchase of the product is consumed.
  ///
  /// The `developerPayload` can be specified to be associated with this consumption.
  ///
  /// This throws an [UnsupportedError] on iOS.
  Future<BillingResultWrapper> consumePurchase(PurchaseDetails purchase,
      {String developerPayload});

  /// Query all previous purchases.
  ///
  /// The `applicationUserName` should match whatever was sent in the initial
  /// `PurchaseParam`, if anything.
  ///
  /// This does not return consumed products. If you want to restore unused
  /// consumable products, you need to persist consumable product information
  /// for your user on your own server.
  ///
  /// See also:
  ///
  ///  * [refreshPurchaseVerificationData], for reloading failed
  ///    [PurchaseDetails.verificationData].
  Future<QueryPurchaseDetailsResponse> queryPastPurchases(
      {String applicationUserName});

  /// (App Store only) retry loading purchase data after an initial failure.
  ///
  /// Throws an [UnsupportedError] on Android.
  Future<PurchaseVerificationData> refreshPurchaseVerificationData();

  /// The [InAppPurchaseConnection] implemented for this platform.
  ///
  /// Throws an [UnsupportedError] when accessed on a platform other than
  /// Android or iOS.
  static InAppPurchaseConnection get instance => _getOrCreateInstance();
  static InAppPurchaseConnection _instance;

  static InAppPurchaseConnection _getOrCreateInstance() {
    if (_instance != null) {
      return _instance;
    }

    if (Platform.isAndroid) {
      _instance = GooglePlayConnection.instance;
    } else if (Platform.isIOS) {
      _instance = AppStoreConnection.instance;
    } else {
      throw UnsupportedError(
          'InAppPurchase plugin only works on Android and iOS.');
    }

    return _instance;
  }
}

/// Which platform the request is on.
enum IAPSource {
  /// Google's Play Store.
  GooglePlay,

  /// Apple's App Store.
  AppStore
}

/// Captures an error from the underlying purchase platform.
///
/// The error can happen during the purchase, restoring a purchase, or querying product.
/// Errors from restoring a purchase are not indicative of any errors during the original purchase.
/// See also:
/// * [ProductDetailsResponse] for error when querying product details.
/// * [PurchaseDetails] for error happened in purchase.
class IAPError {
  /// Creates a new IAP error object with the given error details.
  IAPError(
      {@required this.source,
      @required this.code,
      @required this.message,
      this.details});

  /// Which source is the error on.
  final IAPSource source;

  /// The error code.
  final String code;

  /// A human-readable error message, possibly null.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}
