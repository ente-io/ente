// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/src/billing_client_wrappers/enum_converters.dart';
import 'package:in_app_purchase/src/billing_client_wrappers/purchase_wrapper.dart';
import 'package:in_app_purchase/src/store_kit_wrappers/enum_converters.dart';
import 'package:in_app_purchase/src/store_kit_wrappers/sk_payment_transaction_wrappers.dart';

import './in_app_purchase_connection.dart';
import './product_details.dart';

/// [IAPError.code] code for failed purchases.
final String kPurchaseErrorCode = 'purchase_error';

/// [IAPError.code] code used when a query for previouys transaction has failed.
final String kRestoredPurchaseErrorCode = 'restore_transactions_failed';

/// [IAPError.code] code used when a consuming a purchased item fails.
final String kConsumptionFailedErrorCode = 'consume_purchase_failed';

final String _kPlatformIOS = 'ios';
final String _kPlatformAndroid = 'android';

/// Represents the data that is used to verify purchases.
///
/// The property [source] helps you to determine the method to verify purchases.
/// Different source of purchase has different methods of verifying purchases.
///
/// Both platforms have 2 ways to verify purchase data. You can either choose to verify the data locally using [localVerificationData]
/// or verify the data using your own server with [serverVerificationData].
///
/// For details on how to verify your purchase on iOS,
/// you can refer to Apple's document about [`About Receipt Validation`](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Introduction.html#//apple_ref/doc/uid/TP40010573-CH105-SW1).
///
/// On Android, all purchase information should also be verified manually. See [`Verify a purchase`](https://developer.android.com/google/play/billing/billing_library_overview#Verify).
///
/// It is preferable to verify purchases using a server with [serverVerificationData].
///
/// If the platform is iOS, it is possible the data can be null or your validation of this data turns out invalid. When this happens,
/// Call [InAppPurchaseConnection.refreshPurchaseVerificationData] to get a new [PurchaseVerificationData] object. And then you can
/// validate the receipt data again using one of the methods mentioned in [`Receipt Validation`](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Introduction.html#//apple_ref/doc/uid/TP40010573-CH105-SW1).
///
/// You should never use any purchase data until verified.
class PurchaseVerificationData {
  /// The data used for local verification.
  ///
  /// If the [source] is [IAPSource.AppStore], this data is a based64 encoded string. The structure of the payload is defined using ASN.1.
  /// If the [source] is [IAPSource.GooglePlay], this data is a JSON String.
  final String localVerificationData;

  /// The data used for server verification.
  ///
  /// If the platform is iOS, this data is identical to [localVerificationData].
  final String serverVerificationData;

  /// Indicates the source of the purchase.
  final IAPSource source;

  /// Creates a [PurchaseVerificationData] object with the provided information.
  PurchaseVerificationData(
      {@required this.localVerificationData,
      @required this.serverVerificationData,
      @required this.source});
}

/// Status for a [PurchaseDetails].
///
/// This is the type for [PurchaseDetails.status].
enum PurchaseStatus {
  /// The purchase process is pending.
  ///
  /// You can update UI to let your users know the purchase is pending.
  pending,

  /// The purchase is finished and successful.
  ///
  /// Update your UI to indicate the purchase is finished and deliver the product.
  /// On Android, the google play store is handling the purchase, so we set the status to
  /// `purchased` as long as we can successfully launch play store purchase flow.
  purchased,

  /// Some error occurred in the purchase. The purchasing process if aborted.
  error
}

/// The parameter object for generating a purchase.
class PurchaseParam {
  /// Creates a new purchase parameter object with the given data.
  PurchaseParam(
      {@required this.productDetails,
      this.applicationUserName,
      this.sandboxTesting,
      this.changeSubscriptionParam});

  /// The product to create payment for.
  ///
  /// It has to match one of the valid [ProductDetails] objects that you get from [ProductDetailsResponse] after calling [InAppPurchaseConnection.queryProductDetails].
  final ProductDetails productDetails;

  /// An opaque id for the user's account that's unique to your app. (Optional)
  ///
  /// Used to help the store detect irregular activity.
  /// Do not pass in a clear text, your developer ID, the user’s Apple ID, or the
  /// user's Google ID for this field.
  /// For example, you can use a one-way hash of the user’s account name on your server.
  final String applicationUserName;

  /// The 'sandboxTesting' is only available on iOS, set it to `true` for testing in AppStore's sandbox environment. The default value is `false`.
  final bool sandboxTesting;

  /// The 'changeSubscriptionParam' is only available on Android, for upgrading or
  /// downgrading an existing subscription. This does not require on iOS since
  /// Apple provides a way to group related subscriptions together in iTunesConnect.
  /// So when a subscription upgrade or downgrade is requested, Apple finds the old
  /// subscription details from the group and handle it automatically.
  final ChangeSubscriptionParam changeSubscriptionParam;
}

/// The parameter object for upgrading or downgrading an existing subscription so that
/// the user can only purchase one subscription in a group at a time. This object
/// is only applicable for Android.
///
/// This does not require on iOS since iTunesConnect provides a subscription grouping mechanism.
/// Each subscription you offer must be assigned to a subscription group.
/// So the developers can group related subscriptions together to prevent users from
/// accidentally purchasing multiple subscriptions.
///
/// Please refer to the 'Creating a Subscription Group' sections of [Apple's subscription guide](https://developer.apple.com/app-store/subscriptions/)
class ChangeSubscriptionParam {
  /// Creates a new change subscription param object with given data
  ChangeSubscriptionParam(
      {@required this.oldPurchaseDetails, this.prorationMode});

  /// The purchase object of the existing subscription that the user needs to
  /// upgrade/downgrade from.
  final PurchaseDetails oldPurchaseDetails;

  /// The proration mode.
  ///
  /// This is an optional parameter that indicates how to handle the existing
  /// subscription when the new subscription comes into effect.
  final ProrationMode prorationMode;
}

/// Represents the transaction details of a purchase.
///
/// This class unifies the BillingClient's [PurchaseWrapper] and StoreKit's [SKPaymentTransactionWrapper]. You can use the common attributes in
/// This class for simple operations. If you would like to see the detailed representation of the product, instead,  use [PurchaseWrapper] on Android and [SKPaymentTransactionWrapper] on iOS.
class PurchaseDetails {
  /// A unique identifier of the purchase.
  final String purchaseID;

  /// The product identifier of the purchase.
  final String productID;

  /// The verification data of the purchase.
  ///
  /// Use this to verify the purchase. See [PurchaseVerificationData] for
  /// details on how to verify purchase use this data. You should never use any
  /// purchase data until verified.
  ///
  /// On iOS, this may be null. Call
  /// [InAppPurchaseConnection.refreshPurchaseVerificationData] to get a new
  /// [PurchaseVerificationData] object for further validation.
  final PurchaseVerificationData verificationData;

  /// The timestamp of the transaction.
  ///
  /// Milliseconds since epoch.
  final String transactionDate;

  /// The status that this [PurchaseDetails] is currently on.
  PurchaseStatus get status => _status;
  set status(PurchaseStatus status) {
    if (_platform == _kPlatformIOS) {
      if (status == PurchaseStatus.purchased ||
          status == PurchaseStatus.error) {
        _pendingCompletePurchase = true;
      }
    }
    if (_platform == _kPlatformAndroid) {
      if (status == PurchaseStatus.purchased) {
        _pendingCompletePurchase = true;
      }
    }
    _status = status;
  }

  PurchaseStatus _status;

  /// The error is only available when [status] is [PurchaseStatus.error].
  IAPError error;

  /// Points back to the `StoreKits`'s [SKPaymentTransactionWrapper] object that generated this [PurchaseDetails] object.
  ///
  /// This is null on Android.
  final SKPaymentTransactionWrapper skPaymentTransaction;

  /// Points back to the `BillingClient`'s [PurchaseWrapper] object that generated this [PurchaseDetails] object.
  ///
  /// This is null on iOS.
  final PurchaseWrapper billingClientPurchase;

  /// The developer has to call [InAppPurchaseConnection.completePurchase] if the value is `true`
  /// and the product has been delivered to the user.
  ///
  /// The initial value is `false`.
  /// * See also [InAppPurchaseConnection.completePurchase] for more details on completing purchases.
  bool get pendingCompletePurchase => _pendingCompletePurchase;
  bool _pendingCompletePurchase = false;

  // The platform that the object is created on.
  //
  // The value is either '_kPlatformIOS' or '_kPlatformAndroid'.
  String _platform;

  /// Creates a new PurchaseDetails object with the provided data.
  PurchaseDetails({
    @required this.purchaseID,
    @required this.productID,
    @required this.verificationData,
    @required this.transactionDate,
    this.skPaymentTransaction,
    this.billingClientPurchase,
  });

  /// Generate a [PurchaseDetails] object based on an iOS [SKTransactionWrapper] object.
  PurchaseDetails.fromSKTransaction(
      SKPaymentTransactionWrapper transaction, String base64EncodedReceipt)
      : this.purchaseID = transaction.transactionIdentifier,
        this.productID = transaction.payment.productIdentifier,
        this.verificationData = PurchaseVerificationData(
            localVerificationData: base64EncodedReceipt,
            serverVerificationData: base64EncodedReceipt,
            source: IAPSource.AppStore),
        this.transactionDate = transaction.transactionTimeStamp != null
            ? (transaction.transactionTimeStamp * 1000).toInt().toString()
            : null,
        this.skPaymentTransaction = transaction,
        this.billingClientPurchase = null,
        _platform = _kPlatformIOS {
    status = SKTransactionStatusConverter()
        .toPurchaseStatus(transaction.transactionState);
    if (status == PurchaseStatus.error) {
      error = IAPError(
        source: IAPSource.AppStore,
        code: kPurchaseErrorCode,
        message: transaction.error.domain,
        details: transaction.error.userInfo,
      );
    }
  }

  /// Generate a [PurchaseDetails] object based on an Android [Purchase] object.
  PurchaseDetails.fromPurchase(PurchaseWrapper purchase)
      : this.purchaseID = purchase.orderId,
        this.productID = purchase.sku,
        this.verificationData = PurchaseVerificationData(
            localVerificationData: purchase.originalJson,
            serverVerificationData: purchase.purchaseToken,
            source: IAPSource.GooglePlay),
        this.transactionDate = purchase.purchaseTime.toString(),
        this.skPaymentTransaction = null,
        this.billingClientPurchase = purchase,
        _platform = _kPlatformAndroid {
    status = PurchaseStateConverter().toPurchaseStatus(purchase.purchaseState);
    if (status == PurchaseStatus.error) {
      error = IAPError(
        source: IAPSource.GooglePlay,
        code: kPurchaseErrorCode,
        message: null,
      );
    }
  }
}

/// The response object for fetching the past purchases.
///
/// An instance of this class is returned in [InAppPurchaseConnection.queryPastPurchases].
class QueryPurchaseDetailsResponse {
  /// Creates a new [QueryPurchaseDetailsResponse] object with the provider information.
  QueryPurchaseDetailsResponse({@required this.pastPurchases, this.error});

  /// A list of successfully fetched past purchases.
  ///
  /// If there are no past purchases, or there is an [error] fetching past purchases,
  /// this variable is an empty List.
  /// You should verify the purchase data using [PurchaseDetails.verificationData] before using the [PurchaseDetails] object.
  final List<PurchaseDetails> pastPurchases;

  /// The error when fetching past purchases.
  ///
  /// If the fetch is successful, the value is null.
  final IAPError error;
}
