// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/src/channel.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/services.dart';
import 'sk_payment_transaction_wrappers.dart';
import 'sk_product_wrapper.dart';

part 'sk_payment_queue_wrapper.g.dart';

/// A wrapper around
/// [`SKPaymentQueue`](https://developer.apple.com/documentation/storekit/skpaymentqueue?language=objc).
///
/// The payment queue contains payment related operations. It communicates with
/// the App Store and presents a user interface for the user to process and
/// authorize payments.
///
/// Full information on using `SKPaymentQueue` and processing purchases is
/// available at the [In-App Purchase Programming
/// Guide](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Introduction.html#//apple_ref/doc/uid/TP40008267).
class SKPaymentQueueWrapper {
  SKTransactionObserverWrapper _observer;

  /// Returns the default payment queue.
  ///
  /// We do not support instantiating a custom payment queue, hence the
  /// singleton. However, you can override the observer.
  factory SKPaymentQueueWrapper() {
    return _singleton;
  }

  static final SKPaymentQueueWrapper _singleton = SKPaymentQueueWrapper._();

  SKPaymentQueueWrapper._();

  /// Calls [`-[SKPaymentQueue transactions]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506026-transactions?language=objc)
  Future<List<SKPaymentTransactionWrapper>> transactions() async {
    return _getTransactionList(
        await channel.invokeListMethod<Map>('-[SKPaymentQueue transactions]'));
  }

  /// Calls [`-[SKPaymentQueue canMakePayments:]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506139-canmakepayments?language=objc).
  static Future<bool> canMakePayments() async =>
      await channel.invokeMethod<bool>('-[SKPaymentQueue canMakePayments:]');

  /// Sets an observer to listen to all incoming transaction events.
  ///
  /// This should be called and set as soon as the app launches in order to
  /// avoid missing any purchase updates from the App Store. See the
  /// documentation on StoreKit's [`-[SKPaymentQueue
  /// addTransactionObserver:]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506042-addtransactionobserver?language=objc).
  void setTransactionObserver(SKTransactionObserverWrapper observer) {
    _observer = observer;
    callbackChannel.setMethodCallHandler(_handleObserverCallbacks);
  }

  /// Posts a payment to the queue.
  ///
  /// This sends a purchase request to the App Store for confirmation.
  /// Transaction updates will be delivered to the set
  /// [SkTransactionObserverWrapper].
  ///
  /// A couple preconditions need to be met before calling this method.
  ///
  ///   - At least one [SKTransactionObserverWrapper] should have been added to
  ///     the payment queue using [addTransactionObserver].
  ///   - The [payment.productIdentifier] needs to have been previously fetched
  ///     using [SKRequestMaker.startProductRequest] so that a valid `SKProduct`
  ///     has been cached in the platform side already. Because of this
  ///     [payment.productIdentifier] cannot be hardcoded.
  ///
  /// This method calls StoreKit's [`-[SKPaymentQueue addPayment:]`]
  /// (https://developer.apple.com/documentation/storekit/skpaymentqueue/1506036-addpayment?preferredLanguage=occ).
  ///
  /// Also see [sandbox
  /// testing](https://developer.apple.com/apple-pay/sandbox-testing/).
  Future<void> addPayment(SKPaymentWrapper payment) async {
    assert(_observer != null,
        '[in_app_purchase]: Trying to add a payment without an observer. One must be set using `SkPaymentQueueWrapper.setTransactionObserver` before the app launches.');
    Map requestMap = payment.toMap();
    await channel.invokeMethod<void>(
      '-[InAppPurchasePlugin addPayment:result:]',
      requestMap,
    );
  }

  /// Finishes a transaction and removes it from the queue.
  ///
  /// This method should be called after the given [transaction] has been
  /// succesfully processed and its content has been delivered to the user.
  /// Transaction status updates are propagated to [SkTransactionObserver].
  ///
  /// This will throw a Platform exception if [transaction.transactionState] is
  /// [SKPaymentTransactionStateWrapper.purchasing].
  ///
  /// This method calls StoreKit's [`-[SKPaymentQueue
  /// finishTransaction:]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506003-finishtransaction?language=objc).
  Future<void> finishTransaction(
      SKPaymentTransactionWrapper transaction) async {
    Map<String, String> requestMap = transaction.toFinishMap();
    await channel.invokeMethod<void>(
      '-[InAppPurchasePlugin finishTransaction:result:]',
      requestMap,
    );
  }

  /// Restore previously purchased transactions.
  ///
  /// Use this to load previously purchased content on a new device.
  ///
  /// This call triggers purchase updates on the set
  /// [SKTransactionObserverWrapper] for previously made transactions. This will
  /// invoke [SKTransactionObserverWrapper.restoreCompletedTransactions],
  /// [SKTransactionObserverWrapper.paymentQueueRestoreCompletedTransactionsFinished],
  /// and [SKTransactionObserverWrapper.updatedTransaction]. These restored
  /// transactions need to be marked complete with [finishTransaction] once the
  /// content is delivered, like any other transaction.
  ///
  /// The `applicationUserName` should match the original
  /// [SKPaymentWrapper.applicationUsername] used in [addPayment].
  ///
  /// This method either triggers [`-[SKPayment
  /// restoreCompletedTransactions]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506123-restorecompletedtransactions?language=objc)
  /// or [`-[SKPayment restoreCompletedTransactionsWithApplicationUsername:]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1505992-restorecompletedtransactionswith?language=objc)
  /// depending on whether the `applicationUserName` is set.
  Future<void> restoreTransactions({String applicationUserName}) async {
    await channel.invokeMethod<void>(
        '-[InAppPurchasePlugin restoreTransactions:result:]',
        applicationUserName);
  }

  // Triage a method channel call from the platform and triggers the correct observer method.
  Future<dynamic> _handleObserverCallbacks(MethodCall call) {
    assert(_observer != null,
        '[in_app_purchase]: (Fatal)The observer has not been set but we received a purchase transaction notification. Please ensure the observer has been set using `setTransactionObserver`. Make sure the observer is added right at the App Launch.');
    switch (call.method) {
      case 'updatedTransactions':
        {
          final List<SKPaymentTransactionWrapper> transactions =
              _getTransactionList(call.arguments);
          return Future<void>(() {
            _observer.updatedTransactions(transactions: transactions);
          });
        }
      case 'removedTransactions':
        {
          final List<SKPaymentTransactionWrapper> transactions =
              _getTransactionList(call.arguments);
          return Future<void>(() {
            _observer.removedTransactions(transactions: transactions);
          });
        }
      case 'restoreCompletedTransactionsFailed':
        {
          SKError error = SKError.fromJson(call.arguments);
          return Future<void>(() {
            _observer.restoreCompletedTransactionsFailed(error: error);
          });
        }
      case 'paymentQueueRestoreCompletedTransactionsFinished':
        {
          return Future<void>(() {
            _observer.paymentQueueRestoreCompletedTransactionsFinished();
          });
        }
      case 'shouldAddStorePayment':
        {
          SKPaymentWrapper payment =
              SKPaymentWrapper.fromJson(call.arguments['payment']);
          SKProductWrapper product =
              SKProductWrapper.fromJson(call.arguments['product']);
          return Future<void>(() {
            if (_observer.shouldAddStorePayment(
                    payment: payment, product: product) ==
                true) {
              SKPaymentQueueWrapper().addPayment(payment);
            }
          });
        }
      default:
        break;
    }
    return null;
  }

  // Get transaction wrapper object list from arguments.
  List<SKPaymentTransactionWrapper> _getTransactionList(dynamic arguments) {
    final List<SKPaymentTransactionWrapper> transactions = arguments
        .map<SKPaymentTransactionWrapper>(
            (dynamic map) => SKPaymentTransactionWrapper.fromJson(map))
        .toList();
    return transactions;
  }
}

/// Dart wrapper around StoreKit's
/// [NSError](https://developer.apple.com/documentation/foundation/nserror?language=objc).
@JsonSerializable(nullable: true)
class SKError {
  /// Creates a new [SKError] object with the provided information.
  SKError(
      {@required this.code, @required this.domain, @required this.userInfo});

  /// Constructs an instance of this from a key-value map of data.
  ///
  /// The map needs to have named string keys with values matching the names and
  /// types of all of the members on this class. The `map` parameter must not be
  /// null.
  factory SKError.fromJson(Map map) {
    assert(map != null);
    return _$SKErrorFromJson(map);
  }

  /// Error [code](https://developer.apple.com/documentation/foundation/1448136-nserror_codes)
  /// as defined in the Cocoa Framework.
  final int code;

  /// Error
  /// [domain](https://developer.apple.com/documentation/foundation/nscocoaerrordomain?language=objc)
  /// as defined in the Cocoa Framework.
  final String domain;

  /// A map that contains more detailed information about the error.
  ///
  /// Any key of the map must be a valid [NSErrorUserInfoKey](https://developer.apple.com/documentation/foundation/nserroruserinfokey?language=objc).
  final Map<String, dynamic> userInfo;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKError typedOther = other;
    return typedOther.code == code &&
        typedOther.domain == domain &&
        DeepCollectionEquality.unordered()
            .equals(typedOther.userInfo, userInfo);
  }

  @override
  int get hashCode => hashValues(this.code, this.domain, this.userInfo);
}

/// Dart wrapper around StoreKit's
/// [SKPayment](https://developer.apple.com/documentation/storekit/skpayment?language=objc).
///
/// Used as the parameter to initiate a payment. In general, a developer should
/// not need to create the payment object explicitly; instead, use
/// [SKPaymentQueueWrapper.addPayment] directly with a product identifier to
/// initiate a payment.
@JsonSerializable(nullable: true)
class SKPaymentWrapper {
  /// Creates a new [SKPaymentWrapper] with the provided information.
  SKPaymentWrapper(
      {@required this.productIdentifier,
      this.applicationUsername,
      this.requestData,
      this.quantity = 1,
      this.simulatesAskToBuyInSandbox = false});

  /// Constructs an instance of this from a key value map of data.
  ///
  /// The map needs to have named string keys with values matching the names and
  /// types of all of the members on this class. The `map` parameter must not be
  /// null.
  factory SKPaymentWrapper.fromJson(Map map) {
    assert(map != null);
    return _$SKPaymentWrapperFromJson(map);
  }

  /// Creates a Map object describes the payment object.
  Map<String, dynamic> toMap() {
    return {
      'productIdentifier': productIdentifier,
      'applicationUsername': applicationUsername,
      'requestData': requestData,
      'quantity': quantity,
      'simulatesAskToBuyInSandbox': simulatesAskToBuyInSandbox
    };
  }

  /// The id for the product that the payment is for.
  final String productIdentifier;

  /// An opaque id for the user's account.
  ///
  /// Used to help the store detect irregular activity. See
  /// [applicationUsername](https://developer.apple.com/documentation/storekit/skpayment/1506116-applicationusername?language=objc)
  /// for more details. For example, you can use a one-way hash of the user’s
  /// account name on your server. Don’t use the Apple ID for your developer
  /// account, the user’s Apple ID, or the user’s plaintext account name on
  /// your server.
  final String applicationUsername;

  /// Reserved for future use.
  ///
  /// The value must be null before sending the payment. If the value is not
  /// null, the payment will be rejected.
  ///
  // The iOS Platform provided this property but it is reserved for future use.
  // We also provide this property to match the iOS platform. Converted to
  // String from NSData from ios platform using UTF8Encoding. The / default is
  // null.
  final String requestData;

  /// The amount of the product this payment is for.
  ///
  /// The default is 1. The minimum is 1. The maximum is 10.
  final int quantity;

  /// Produces an "ask to buy" flow in the sandbox if set to true. Default is
  /// false.
  ///
  /// See https://developer.apple.com/in-app-purchase/ for a guide on Sandbox
  /// testing.
  final bool simulatesAskToBuyInSandbox;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKPaymentWrapper typedOther = other;
    return typedOther.productIdentifier == productIdentifier &&
        typedOther.applicationUsername == applicationUsername &&
        typedOther.quantity == quantity &&
        typedOther.simulatesAskToBuyInSandbox == simulatesAskToBuyInSandbox &&
        typedOther.requestData == requestData;
  }

  @override
  int get hashCode => hashValues(
      this.productIdentifier,
      this.applicationUsername,
      this.quantity,
      this.simulatesAskToBuyInSandbox,
      this.requestData);

  @override
  String toString() => _$SKPaymentWrapperToJson(this).toString();
}
