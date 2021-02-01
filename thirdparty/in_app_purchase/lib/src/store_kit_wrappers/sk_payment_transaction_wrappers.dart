// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'sk_product_wrapper.dart';
import 'sk_payment_queue_wrapper.dart';
import 'enum_converters.dart';

part 'sk_payment_transaction_wrappers.g.dart';

/// Callback handlers for transaction status changes.
///
/// Must be subclassed. Must be instantiated and added to the
/// [SKPaymentQueueWrapper] via [SKPaymentQueueWrapper.setTransactionObserver]
/// at app launch.
///
/// This class is a Dart wrapper around [SKTransactionObserver](https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver?language=objc).
abstract class SKTransactionObserverWrapper {
  /// Triggered when any transactions are updated.
  void updatedTransactions({List<SKPaymentTransactionWrapper> transactions});

  /// Triggered when any transactions are removed from the payment queue.
  void removedTransactions({List<SKPaymentTransactionWrapper> transactions});

  /// Triggered when there is an error while restoring transactions.
  void restoreCompletedTransactionsFailed({SKError error});

  /// Triggered when payment queue has finished sending restored transactions.
  void paymentQueueRestoreCompletedTransactionsFinished();

  /// Triggered when a user initiates an in-app purchase from App Store.
  ///
  /// Return `true` to continue the transaction in your app. If you have
  /// multiple [SKTransactionObserverWrapper]s, the transaction will continue if
  /// any [SKTransactionObserverWrapper] returns `true`. Return `false` to defer
  /// or cancel the transaction. For example, you may need to defer a
  /// transaction if the user is in the middle of onboarding. You can also
  /// continue the transaction later by calling [addPayment] with the
  /// `payment` param from this method.
  bool shouldAddStorePayment(
      {SKPaymentWrapper payment, SKProductWrapper product});
}

/// The state of a transaction.
///
/// Dart wrapper around StoreKit's
/// [SKPaymentTransactionState](https://developer.apple.com/documentation/storekit/skpaymenttransactionstate?language=objc).
enum SKPaymentTransactionStateWrapper {
  /// Indicates the transaction is being processed in App Store.
  ///
  /// You should update your UI to indicate that you are waiting for the
  /// transaction to update to another state. Never complete a transaction that
  /// is still in a purchasing state.
  @JsonValue(0)
  purchasing,

  /// The user's payment has been succesfully processed.
  ///
  /// You should provide the user the content that they purchased.
  @JsonValue(1)
  purchased,

  /// The transaction failed.
  ///
  /// Check the [SKPaymentTransactionWrapper.error] property from
  /// [SKPaymentTransactionWrapper] for details.
  @JsonValue(2)
  failed,

  /// This transaction is restoring content previously purchased by the user.
  ///
  /// The previous transaction information can be obtained in
  /// [SKPaymentTransactionWrapper.originalTransaction] from
  /// [SKPaymentTransactionWrapper].
  @JsonValue(3)
  restored,

  /// The transaction is in the queue but pending external action. Wait for
  /// another callback to get the final state.
  ///
  /// You should update your UI to indicate that you are waiting for the
  /// transaction to update to another state.
  @JsonValue(4)
  deferred,
}

/// Created when a payment is added to the [SKPaymentQueueWrapper].
///
/// Transactions are delivered to your app when a payment is finished
/// processing. Completed transactions provide a receipt and a transaction
/// identifier that the app can use to save a permanent record of the processed
/// payment.
///
/// Dart wrapper around StoreKit's
/// [SKPaymentTransaction](https://developer.apple.com/documentation/storekit/skpaymenttransaction?language=objc).
@JsonSerializable(nullable: true)
class SKPaymentTransactionWrapper {
  /// Creates a new [SKPaymentTransactionWrapper] with the provided information.
  SKPaymentTransactionWrapper({
    @required this.payment,
    @required this.transactionState,
    @required this.originalTransaction,
    @required this.transactionTimeStamp,
    @required this.transactionIdentifier,
    @required this.error,
  });

  /// Constructs an instance of this from a key value map of data.
  ///
  /// The map needs to have named string keys with values matching the names and
  /// types of all of the members on this class. The `map` parameter must not be
  /// null.
  factory SKPaymentTransactionWrapper.fromJson(Map map) {
    if (map == null) {
      return null;
    }
    return _$SKPaymentTransactionWrapperFromJson(map);
  }

  /// Current transaction state.
  @SKTransactionStatusConverter()
  final SKPaymentTransactionStateWrapper transactionState;

  /// The payment that has been created and added to the payment queue which
  /// generated this transaction.
  final SKPaymentWrapper payment;

  /// The original Transaction.
  ///
  /// Only available if the [transactionState] is
  /// [SKPaymentTransactionStateWrapper.restored]. When the [transactionState]
  /// is [SKPaymentTransactionStateWrapper.restored], the current transaction
  /// object holds a new [transactionIdentifier].
  final SKPaymentTransactionWrapper originalTransaction;

  /// The timestamp of the transaction.
  ///
  /// Seconds since epoch. It is only defined when the [transactionState] is
  /// [SKPaymentTransactionStateWrapper.purchased] or
  /// [SKPaymentTransactionStateWrapper.restored].
  final double transactionTimeStamp;

  /// The unique string identifer of the transaction.
  ///
  /// It is only defined when the [transactionState] is
  /// [SKPaymentTransactionStateWrapper.purchased] or
  /// [SKPaymentTransactionStateWrapper.restored]. You may wish to record this
  /// string as part of an audit trail for App Store purchases. The value of
  /// this string corresponds to the same property in the receipt.
  final String transactionIdentifier;

  /// The error object
  ///
  /// Only available if the [transactionState] is
  /// [SKPaymentTransactionStateWrapper.failed].
  final SKError error;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKPaymentTransactionWrapper typedOther = other;
    return typedOther.payment == payment &&
        typedOther.transactionState == transactionState &&
        typedOther.originalTransaction == originalTransaction &&
        typedOther.transactionTimeStamp == transactionTimeStamp &&
        typedOther.transactionIdentifier == transactionIdentifier &&
        typedOther.error == error;
  }

  @override
  int get hashCode => hashValues(
      this.payment,
      this.transactionState,
      this.originalTransaction,
      this.transactionTimeStamp,
      this.transactionIdentifier,
      this.error);

  @override
  String toString() => _$SKPaymentTransactionWrapperToJson(this).toString();

  /// The payload that is used to finish this transaction.
  Map<String, String> toFinishMap() => {
        "transactionIdentifier": this.transactionIdentifier,
        "productIdentifier": this.payment?.productIdentifier,
      };
}
