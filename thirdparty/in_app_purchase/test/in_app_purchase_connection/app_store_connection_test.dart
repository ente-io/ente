// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:in_app_purchase/src/in_app_purchase/purchase_details.dart';
import 'package:test/test.dart';

import 'package:in_app_purchase/src/channel.dart';
import 'package:in_app_purchase/src/in_app_purchase/app_store_connection.dart';
import 'package:in_app_purchase/src/in_app_purchase/in_app_purchase_connection.dart';
import 'package:in_app_purchase/src/in_app_purchase/product_details.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import '../store_kit_wrappers/sk_test_stub_objects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final FakeIOSPlatform fakeIOSPlatform = FakeIOSPlatform();

  setUpAll(() {
    SystemChannels.platform
        .setMockMethodCallHandler(fakeIOSPlatform.onMethodCall);
  });

  setUp(() => fakeIOSPlatform.reset());

  tearDown(() => fakeIOSPlatform.reset());

  group('isAvailable', () {
    test('true', () async {
      expect(await AppStoreConnection.instance.isAvailable(), isTrue);
    });
  });

  group('query product list', () {
    test('should get product list and correct invalid identifiers', () async {
      final AppStoreConnection connection = AppStoreConnection();
      final ProductDetailsResponse response = await connection
          .queryProductDetails(<String>['123', '456', '789'].toSet());
      List<ProductDetails> products = response.productDetails;
      expect(products.first.id, '123');
      expect(products[1].id, '456');
      expect(response.notFoundIDs, ['789']);
      expect(response.error, isNull);
    });

    test(
        'if query products throws error, should get error object in the response',
        () async {
      fakeIOSPlatform.queryProductException = PlatformException(
          code: 'error_code',
          message: 'error_message',
          details: {'info': 'error_info'});
      final AppStoreConnection connection = AppStoreConnection();
      final ProductDetailsResponse response = await connection
          .queryProductDetails(<String>['123', '456', '789'].toSet());
      expect(response.productDetails, []);
      expect(response.notFoundIDs, ['123', '456', '789']);
      expect(response.error.source, IAPSource.AppStore);
      expect(response.error.code, 'error_code');
      expect(response.error.message, 'error_message');
      expect(response.error.details, {'info': 'error_info'});
    });
  });

  group('query purchases list', () {
    test('should get purchase list', () async {
      QueryPurchaseDetailsResponse response =
          await AppStoreConnection.instance.queryPastPurchases();
      expect(response.pastPurchases.length, 2);
      expect(response.pastPurchases.first.purchaseID,
          fakeIOSPlatform.transactions.first.transactionIdentifier);
      expect(response.pastPurchases.last.purchaseID,
          fakeIOSPlatform.transactions.last.transactionIdentifier);
      expect(response.pastPurchases.first.purchaseID,
          fakeIOSPlatform.transactions.first.transactionIdentifier);
      expect(response.pastPurchases.last.purchaseID,
          fakeIOSPlatform.transactions.last.transactionIdentifier);
      expect(
          response.pastPurchases.first.verificationData.localVerificationData,
          'dummy base64data');
      expect(
          response.pastPurchases.first.verificationData.serverVerificationData,
          'dummy base64data');
      expect(response.error, isNull);
    });

    test('queryPastPurchases should not block transaction updates', () async {
      fakeIOSPlatform.transactions
          .add(fakeIOSPlatform.createPurchasedTransaction('foo', 'bar'));
      Completer completer = Completer();
      Stream<List<PurchaseDetails>> stream =
          AppStoreConnection.instance.purchaseUpdatedStream;

      StreamSubscription subscription;
      subscription = stream.listen((purchaseDetailsList) {
        if (purchaseDetailsList.first.status == PurchaseStatus.purchased) {
          completer.complete(purchaseDetailsList);
          subscription.cancel();
        }
      });
      QueryPurchaseDetailsResponse response =
          await AppStoreConnection.instance.queryPastPurchases();
      List<PurchaseDetails> result = await completer.future;
      expect(result.length, 1);
      expect(result.first.productID, 'foo');
      expect(response.error, isNull);
    });

    test('should get empty result if there is no restored transactions',
        () async {
      fakeIOSPlatform.testRestoredTransactionsNull = true;
      QueryPurchaseDetailsResponse response =
          await AppStoreConnection.instance.queryPastPurchases();
      expect(response.pastPurchases, isEmpty);
      expect(response.error, isNull);
      fakeIOSPlatform.testRestoredTransactionsNull = false;
    });

    test('test restore error', () async {
      fakeIOSPlatform.testRestoredError = SKError(
          code: 123,
          domain: 'error_test',
          userInfo: {'message': 'errorMessage'});
      QueryPurchaseDetailsResponse response =
          await AppStoreConnection.instance.queryPastPurchases();
      expect(response.pastPurchases, isEmpty);
      expect(response.error.source, IAPSource.AppStore);
      expect(response.error.message, 'error_test');
      expect(response.error.details, {'message': 'errorMessage'});
    });

    test('receipt error should populate null to verificationData.data',
        () async {
      fakeIOSPlatform.receiptData = null;
      QueryPurchaseDetailsResponse response =
          await AppStoreConnection.instance.queryPastPurchases();
      expect(
          response.pastPurchases.first.verificationData.localVerificationData,
          null);
      expect(
          response.pastPurchases.first.verificationData.serverVerificationData,
          null);
    });
  });

  group('refresh receipt data', () {
    test('should refresh receipt data', () async {
      PurchaseVerificationData receiptData =
          await AppStoreConnection.instance.refreshPurchaseVerificationData();
      expect(receiptData.source, IAPSource.AppStore);
      expect(receiptData.localVerificationData, 'refreshed receipt data');
      expect(receiptData.serverVerificationData, 'refreshed receipt data');
    });
  });

  group('make payment', () {
    test(
        'buying non consumable, should get purchase objects in the purchase update callback',
        () async {
      List<PurchaseDetails> details = [];
      Completer completer = Completer();
      Stream<List<PurchaseDetails>> stream =
          AppStoreConnection.instance.purchaseUpdatedStream;

      StreamSubscription subscription;
      subscription = stream.listen((purchaseDetailsList) {
        details.addAll(purchaseDetailsList);
        if (purchaseDetailsList.first.status == PurchaseStatus.purchased) {
          completer.complete(details);
          subscription.cancel();
        }
      });
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSKProduct(dummyProductWrapper),
          applicationUserName: 'appName');
      await AppStoreConnection.instance
          .buyNonConsumable(purchaseParam: purchaseParam);

      List<PurchaseDetails> result = await completer.future;
      expect(result.length, 2);
      expect(result.first.productID, dummyProductWrapper.productIdentifier);
    });

    test(
        'buying consumable, should get purchase objects in the purchase update callback',
        () async {
      List<PurchaseDetails> details = [];
      Completer completer = Completer();
      Stream<List<PurchaseDetails>> stream =
          AppStoreConnection.instance.purchaseUpdatedStream;

      StreamSubscription subscription;
      subscription = stream.listen((purchaseDetailsList) {
        details.addAll(purchaseDetailsList);
        if (purchaseDetailsList.first.status == PurchaseStatus.purchased) {
          completer.complete(details);
          subscription.cancel();
        }
      });
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSKProduct(dummyProductWrapper),
          applicationUserName: 'appName');
      await AppStoreConnection.instance
          .buyConsumable(purchaseParam: purchaseParam);

      List<PurchaseDetails> result = await completer.future;
      expect(result.length, 2);
      expect(result.first.productID, dummyProductWrapper.productIdentifier);
    });

    test('buying consumable, should throw when autoConsume is false', () async {
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSKProduct(dummyProductWrapper),
          applicationUserName: 'appName');
      expect(
          () => AppStoreConnection.instance
              .buyConsumable(purchaseParam: purchaseParam, autoConsume: false),
          throwsA(TypeMatcher<AssertionError>()));
    });

    test('should get failed purchase status', () async {
      fakeIOSPlatform.testTransactionFail = true;
      List<PurchaseDetails> details = [];
      Completer completer = Completer();
      IAPError error;

      Stream<List<PurchaseDetails>> stream =
          AppStoreConnection.instance.purchaseUpdatedStream;
      StreamSubscription subscription;
      subscription = stream.listen((purchaseDetailsList) {
        details.addAll(purchaseDetailsList);
        purchaseDetailsList.forEach((purchaseDetails) {
          if (purchaseDetails.status == PurchaseStatus.error) {
            error = purchaseDetails.error;
            completer.complete(error);
            subscription.cancel();
          }
        });
      });
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSKProduct(dummyProductWrapper),
          applicationUserName: 'appName');
      await AppStoreConnection.instance
          .buyNonConsumable(purchaseParam: purchaseParam);

      IAPError completerError = await completer.future;
      expect(completerError.code, 'purchase_error');
      expect(completerError.source, IAPSource.AppStore);
      expect(completerError.message, 'ios_domain');
      expect(completerError.details, {'message': 'an error message'});
    });
  });

  group('complete purchase', () {
    test('should complete purchase', () async {
      List<PurchaseDetails> details = [];
      Completer completer = Completer();
      Stream<List<PurchaseDetails>> stream =
          AppStoreConnection.instance.purchaseUpdatedStream;
      StreamSubscription subscription;
      subscription = stream.listen((purchaseDetailsList) {
        details.addAll(purchaseDetailsList);
        purchaseDetailsList.forEach((purchaseDetails) {
          if (purchaseDetails.pendingCompletePurchase) {
            AppStoreConnection.instance.completePurchase(purchaseDetails);
            completer.complete(details);
            subscription.cancel();
          }
        });
      });
      final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: ProductDetails.fromSKProduct(dummyProductWrapper),
          applicationUserName: 'appName');
      await AppStoreConnection.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
      List<PurchaseDetails> result = await completer.future;
      expect(result.length, 2);
      expect(result.first.productID, dummyProductWrapper.productIdentifier);
      expect(fakeIOSPlatform.finishedTransactions.length, 1);
    });
  });

  group('consume purchase', () {
    test('should throw when calling consume purchase on iOS', () async {
      expect(() => AppStoreConnection.instance.consumePurchase(null),
          throwsUnsupportedError);
    });
  });
}

class FakeIOSPlatform {
  FakeIOSPlatform() {
    channel.setMockMethodCallHandler(onMethodCall);
  }

  // pre-configured store informations
  String receiptData;
  Set<String> validProductIDs;
  Map<String, SKProductWrapper> validProducts;
  List<SKPaymentTransactionWrapper> transactions;
  List<SKPaymentTransactionWrapper> finishedTransactions;
  bool testRestoredTransactionsNull;
  bool testTransactionFail;
  PlatformException queryProductException;
  PlatformException restoreException;
  SKError testRestoredError;

  void reset() {
    transactions = [];
    receiptData = 'dummy base64data';
    validProductIDs = ['123', '456'].toSet();
    validProducts = Map();
    for (String validID in validProductIDs) {
      Map productWrapperMap = buildProductMap(dummyProductWrapper);
      productWrapperMap['productIdentifier'] = validID;
      validProducts[validID] = SKProductWrapper.fromJson(productWrapperMap);
    }

    SKPaymentTransactionWrapper tran1 = SKPaymentTransactionWrapper(
      transactionIdentifier: '123',
      payment: dummyPayment,
      originalTransaction: dummyTransaction,
      transactionTimeStamp: 123123123.022,
      transactionState: SKPaymentTransactionStateWrapper.restored,
      error: null,
    );
    SKPaymentTransactionWrapper tran2 = SKPaymentTransactionWrapper(
      transactionIdentifier: '1234',
      payment: dummyPayment,
      originalTransaction: dummyTransaction,
      transactionTimeStamp: 123123123.022,
      transactionState: SKPaymentTransactionStateWrapper.restored,
      error: null,
    );

    transactions.addAll([tran1, tran2]);
    finishedTransactions = [];
    testRestoredTransactionsNull = false;
    testTransactionFail = false;
    queryProductException = null;
    restoreException = null;
    testRestoredError = null;
  }

  SKPaymentTransactionWrapper createPendingTransaction(String id) {
    return SKPaymentTransactionWrapper(
        transactionIdentifier: null,
        payment: SKPaymentWrapper(productIdentifier: id),
        transactionState: SKPaymentTransactionStateWrapper.purchasing,
        transactionTimeStamp: 123123.121,
        error: null,
        originalTransaction: null);
  }

  SKPaymentTransactionWrapper createPurchasedTransaction(
      String productId, String transactionId) {
    return SKPaymentTransactionWrapper(
        payment: SKPaymentWrapper(productIdentifier: productId),
        transactionState: SKPaymentTransactionStateWrapper.purchased,
        transactionTimeStamp: 123123.121,
        transactionIdentifier: transactionId,
        error: null,
        originalTransaction: null);
  }

  SKPaymentTransactionWrapper createFailedTransaction(String productId) {
    return SKPaymentTransactionWrapper(
        transactionIdentifier: null,
        payment: SKPaymentWrapper(productIdentifier: productId),
        transactionState: SKPaymentTransactionStateWrapper.failed,
        transactionTimeStamp: 123123.121,
        error: SKError(
            code: 0,
            domain: 'ios_domain',
            userInfo: {'message': 'an error message'}),
        originalTransaction: null);
  }

  Future<dynamic> onMethodCall(MethodCall call) {
    switch (call.method) {
      case '-[SKPaymentQueue canMakePayments:]':
        return Future<bool>.value(true);
      case '-[InAppPurchasePlugin startProductRequest:result:]':
        if (queryProductException != null) {
          throw queryProductException;
        }
        List<String> productIDS =
            List.castFrom<dynamic, String>(call.arguments);
        assert(productIDS is List<String>, 'invalid argument type');
        List<String> invalidFound = [];
        List<SKProductWrapper> products = [];
        for (String productID in productIDS) {
          if (!validProductIDs.contains(productID)) {
            invalidFound.add(productID);
          } else {
            products.add(validProducts[productID]);
          }
        }
        SkProductResponseWrapper response = SkProductResponseWrapper(
            products: products, invalidProductIdentifiers: invalidFound);
        return Future<Map<String, dynamic>>.value(
            buildProductResponseMap(response));
      case '-[InAppPurchasePlugin restoreTransactions:result:]':
        if (restoreException != null) {
          throw restoreException;
        }
        if (testRestoredError != null) {
          AppStoreConnection.observer
              .restoreCompletedTransactionsFailed(error: testRestoredError);
          return Future<void>.sync(() {});
        }
        if (!testRestoredTransactionsNull) {
          AppStoreConnection.observer
              .updatedTransactions(transactions: transactions);
        }
        AppStoreConnection.observer
            .paymentQueueRestoreCompletedTransactionsFinished();
        return Future<void>.sync(() {});
      case '-[InAppPurchasePlugin retrieveReceiptData:result:]':
        if (receiptData != null) {
          return Future<void>.value(receiptData);
        } else {
          throw PlatformException(code: 'no_receipt_data');
        }
        break;
      case '-[InAppPurchasePlugin refreshReceipt:result:]':
        receiptData = 'refreshed receipt data';
        return Future<void>.sync(() {});
      case '-[InAppPurchasePlugin addPayment:result:]':
        String id = call.arguments['productIdentifier'];
        SKPaymentTransactionWrapper transaction = createPendingTransaction(id);
        AppStoreConnection.observer
            .updatedTransactions(transactions: [transaction]);
        sleep(const Duration(milliseconds: 30));
        if (testTransactionFail) {
          SKPaymentTransactionWrapper transaction_failed =
              createFailedTransaction(id);
          AppStoreConnection.observer
              .updatedTransactions(transactions: [transaction_failed]);
        } else {
          SKPaymentTransactionWrapper transaction_finished =
              createPurchasedTransaction(id, transaction.transactionIdentifier);
          AppStoreConnection.observer
              .updatedTransactions(transactions: [transaction_finished]);
        }
        break;
      case '-[InAppPurchasePlugin finishTransaction:result:]':
        finishedTransactions.add(createPurchasedTransaction(
            call.arguments["productIdentifier"],
            call.arguments["transactionIdentifier"]));
        break;
    }
    return Future<void>.sync(() {});
  }
}
