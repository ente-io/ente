// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/src/in_app_purchase/purchase_details.dart';
import 'in_app_purchase_connection.dart';
import 'product_details.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:in_app_purchase/src/store_kit_wrappers/enum_converters.dart';
import '../../billing_client_wrappers.dart';

/// An [InAppPurchaseConnection] that wraps StoreKit.
///
/// This translates various `StoreKit` calls and responses into the
/// generic plugin API.
class AppStoreConnection implements InAppPurchaseConnection {
  /// Returns the singleton instance of the [AppStoreConnection] that should be
  /// used across the app.
  static AppStoreConnection get instance => _getOrCreateInstance();
  static AppStoreConnection _instance;
  static SKPaymentQueueWrapper _skPaymentQueueWrapper;
  static _TransactionObserver _observer;

  /// Creates an [AppStoreConnection] object.
  ///
  /// This constructor should only be used for testing, for any other purpose
  /// get the connection from the [instance] getter.
  @visibleForTesting
  AppStoreConnection();

  Stream<List<PurchaseDetails>> get purchaseUpdatedStream =>
      _observer.purchaseUpdatedController.stream;

  /// Callback handler for transaction status changes.
  @visibleForTesting
  static SKTransactionObserverWrapper get observer => _observer;

  static AppStoreConnection _getOrCreateInstance() {
    if (_instance != null) {
      return _instance;
    }

    _instance = AppStoreConnection();
    _skPaymentQueueWrapper = SKPaymentQueueWrapper();
    _observer = _TransactionObserver(StreamController.broadcast());
    _skPaymentQueueWrapper.setTransactionObserver(observer);
    return _instance;
  }

  @override
  Future<bool> isAvailable() => SKPaymentQueueWrapper.canMakePayments();

  @override
  Future<bool> buyNonConsumable({@required PurchaseParam purchaseParam}) async {
    assert(purchaseParam.changeSubscriptionParam == null,
        'This does not require on iOS since iTunesConnect provides a subscription grouping mechanism.');
    await _skPaymentQueueWrapper.addPayment(SKPaymentWrapper(
        productIdentifier: purchaseParam.productDetails.id,
        quantity: 1,
        applicationUsername: purchaseParam.applicationUserName,
        simulatesAskToBuyInSandbox: purchaseParam.sandboxTesting,
        requestData: null));
    return true; // There's no error feedback from iOS here to return.
  }

  @override
  Future<bool> buyConsumable(
      {@required PurchaseParam purchaseParam, bool autoConsume = true}) {
    assert(autoConsume == true, 'On iOS, we should always auto consume');
    return buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<BillingResultWrapper> completePurchase(PurchaseDetails purchase,
      {String developerPayload}) async {
    await _skPaymentQueueWrapper
        .finishTransaction(purchase.skPaymentTransaction);
    return BillingResultWrapper(responseCode: BillingResponse.ok);
  }

  @override
  Future<BillingResultWrapper> consumePurchase(PurchaseDetails purchase,
      {String developerPayload}) {
    throw UnsupportedError('consume purchase is not available on Android');
  }

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases(
      {String applicationUserName}) async {
    IAPError error;
    List<PurchaseDetails> pastPurchases = [];

    try {
      String receiptData = await _observer.getReceiptData();
      final List<SKPaymentTransactionWrapper> restoredTransactions =
          await _observer.getRestoredTransactions(
              queue: _skPaymentQueueWrapper,
              applicationUserName: applicationUserName);
      _observer.cleanUpRestoredTransactions();
      pastPurchases =
          restoredTransactions.map((SKPaymentTransactionWrapper transaction) {
        assert(transaction.transactionState ==
            SKPaymentTransactionStateWrapper.restored);
        return PurchaseDetails.fromSKTransaction(transaction, receiptData)
          ..status = SKTransactionStatusConverter()
              .toPurchaseStatus(transaction.transactionState)
          ..error = transaction.error != null
              ? IAPError(
                  source: IAPSource.AppStore,
                  code: kPurchaseErrorCode,
                  message: transaction.error.domain,
                  details: transaction.error.userInfo,
                )
              : null;
      }).toList();
    } on PlatformException catch (e) {
      error = IAPError(
          source: IAPSource.AppStore,
          code: e.code,
          message: e.message,
          details: e.details);
    } on SKError catch (e) {
      error = IAPError(
          source: IAPSource.AppStore,
          code: kRestoredPurchaseErrorCode,
          message: e.domain,
          details: e.userInfo);
    }
    return QueryPurchaseDetailsResponse(
        pastPurchases: pastPurchases, error: error);
  }

  @override
  Future<PurchaseVerificationData> refreshPurchaseVerificationData() async {
    await SKRequestMaker().startRefreshReceiptRequest();
    String receipt = await SKReceiptManager.retrieveReceiptData();
    return PurchaseVerificationData(
        localVerificationData: receipt,
        serverVerificationData: receipt,
        source: IAPSource.AppStore);
  }

  /// Query the product detail list.
  ///
  /// This method only returns [ProductDetailsResponse].
  /// To get detailed Store Kit product list, use [SkProductResponseWrapper.startProductRequest]
  /// to get the [SKProductResponseWrapper].
  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    final SKRequestMaker requestMaker = SKRequestMaker();
    SkProductResponseWrapper response;
    PlatformException exception;
    try {
      response = await requestMaker.startProductRequest(identifiers.toList());
    } on PlatformException catch (e) {
      exception = e;
      response = SkProductResponseWrapper(
          products: [], invalidProductIdentifiers: identifiers.toList());
    }
    List<ProductDetails> productDetails = [];
    if (response.products != null) {
      productDetails = response.products
          .map((SKProductWrapper productWrapper) =>
              ProductDetails.fromSKProduct(productWrapper))
          .toList();
    }
    List<String> invalidIdentifiers = response.invalidProductIdentifiers ?? [];
    if (productDetails.isEmpty) {
      invalidIdentifiers = identifiers.toList();
    }
    ProductDetailsResponse productDetailsResponse = ProductDetailsResponse(
      productDetails: productDetails,
      notFoundIDs: invalidIdentifiers,
      error: exception == null
          ? null
          : IAPError(
              source: IAPSource.AppStore,
              code: exception.code,
              message: exception.message,
              details: exception.details),
    );
    return productDetailsResponse;
  }
}

class _TransactionObserver implements SKTransactionObserverWrapper {
  final StreamController<List<PurchaseDetails>> purchaseUpdatedController;

  Completer<List<SKPaymentTransactionWrapper>> _restoreCompleter;
  List<SKPaymentTransactionWrapper> _restoredTransactions;
  String _receiptData;

  _TransactionObserver(this.purchaseUpdatedController);

  Future<List<SKPaymentTransactionWrapper>> getRestoredTransactions(
      {@required SKPaymentQueueWrapper queue, String applicationUserName}) {
    assert(queue != null);
    _restoreCompleter = Completer();
    queue.restoreTransactions(applicationUserName: applicationUserName);
    return _restoreCompleter.future;
  }

  void cleanUpRestoredTransactions() {
    _restoredTransactions = null;
    _restoreCompleter = null;
  }

  void updatedTransactions(
      {List<SKPaymentTransactionWrapper> transactions}) async {
    if (_restoreCompleter != null) {
      if (_restoredTransactions == null) {
        _restoredTransactions = [];
      }
      _restoredTransactions
          .addAll(transactions.where((SKPaymentTransactionWrapper wrapper) {
        return wrapper.transactionState ==
            SKPaymentTransactionStateWrapper.restored;
      }).map((SKPaymentTransactionWrapper wrapper) => wrapper));
    }

    String receiptData = await getReceiptData();
    purchaseUpdatedController
        .add(transactions.where((SKPaymentTransactionWrapper wrapper) {
      return wrapper.transactionState !=
          SKPaymentTransactionStateWrapper.restored;
    }).map((SKPaymentTransactionWrapper transaction) {
      PurchaseDetails purchaseDetails =
          PurchaseDetails.fromSKTransaction(transaction, receiptData);
      return purchaseDetails;
    }).toList());
  }

  void removedTransactions({List<SKPaymentTransactionWrapper> transactions}) {}

  /// Triggered when there is an error while restoring transactions.
  void restoreCompletedTransactionsFailed({SKError error}) {
    _restoreCompleter.completeError(error);
  }

  void paymentQueueRestoreCompletedTransactionsFinished() {
    _restoreCompleter.complete(_restoredTransactions ?? []);
  }

  bool shouldAddStorePayment(
      {SKPaymentWrapper payment, SKProductWrapper product}) {
    // In this unified API, we always return true to keep it consistent with the behavior on Google Play.
    return true;
  }

  Future<String> getReceiptData() async {
    try {
      _receiptData = await SKReceiptManager.retrieveReceiptData();
    } catch (e) {
      _receiptData = null;
    }
    return _receiptData;
  }
}
