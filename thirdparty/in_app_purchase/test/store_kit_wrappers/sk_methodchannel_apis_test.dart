// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/src/channel.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'sk_test_stub_objects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final FakeIOSPlatform fakeIOSPlatform = FakeIOSPlatform();

  setUpAll(() {
    SystemChannels.platform
        .setMockMethodCallHandler(fakeIOSPlatform.onMethodCall);
  });

  setUp(() {});

  group('sk_request_maker', () {
    test('get products method channel', () async {
      SkProductResponseWrapper productResponseWrapper =
          await SKRequestMaker().startProductRequest(['xxx']);
      expect(
        productResponseWrapper.products,
        isNotEmpty,
      );
      expect(
        productResponseWrapper.products.first.priceLocale.currencySymbol,
        '\$',
      );

      expect(
        productResponseWrapper.products.first.priceLocale.currencySymbol,
        isNot('A'),
      );
      expect(
        productResponseWrapper.products.first.priceLocale.currencyCode,
        'USD',
      );
      expect(
        productResponseWrapper.invalidProductIdentifiers,
        isNotEmpty,
      );

      expect(
        fakeIOSPlatform.startProductRequestParam,
        ['xxx'],
      );
    });

    test('get products method channel should throw exception', () async {
      fakeIOSPlatform.getProductRequestFailTest = true;
      expect(
        SKRequestMaker().startProductRequest(['xxx']),
        throwsException,
      );
      fakeIOSPlatform.getProductRequestFailTest = false;
    });

    test('refreshed receipt', () async {
      int receiptCountBefore = fakeIOSPlatform.refreshReceipt;
      await SKRequestMaker()
          .startRefreshReceiptRequest(receiptProperties: {"isExpired": true});
      expect(fakeIOSPlatform.refreshReceipt, receiptCountBefore + 1);
      expect(fakeIOSPlatform.refreshReceiptParam, {"isExpired": true});
    });
  });

  group('sk_receipt_manager', () {
    test('should get receipt (faking it by returning a `receipt data` string)',
        () async {
      String receiptData = await SKReceiptManager.retrieveReceiptData();
      expect(receiptData, 'receipt data');
    });
  });

  group('sk_payment_queue', () {
    test('canMakePayment should return true', () async {
      expect(await SKPaymentQueueWrapper.canMakePayments(), true);
    });

    test('transactions should return a valid list of transactions', () async {
      expect(await SKPaymentQueueWrapper().transactions(), isNotEmpty);
    });

    test(
        'throws if observer is not set for payment queue before adding payment',
        () async {
      expect(SKPaymentQueueWrapper().addPayment(dummyPayment),
          throwsAssertionError);
    });

    test('should add payment to the payment queue', () async {
      SKPaymentQueueWrapper queue = SKPaymentQueueWrapper();
      TestPaymentTransactionObserver observer =
          TestPaymentTransactionObserver();
      queue.setTransactionObserver(observer);
      await queue.addPayment(dummyPayment);
      expect(fakeIOSPlatform.payments.first, equals(dummyPayment));
    });

    test('should finish transaction', () async {
      SKPaymentQueueWrapper queue = SKPaymentQueueWrapper();
      TestPaymentTransactionObserver observer =
          TestPaymentTransactionObserver();
      queue.setTransactionObserver(observer);
      await queue.finishTransaction(dummyTransaction);
      expect(fakeIOSPlatform.transactionsFinished.first,
          equals(dummyTransaction.toFinishMap()));
    });

    test('should restore transaction', () async {
      SKPaymentQueueWrapper queue = SKPaymentQueueWrapper();
      TestPaymentTransactionObserver observer =
          TestPaymentTransactionObserver();
      queue.setTransactionObserver(observer);
      await queue.restoreTransactions(applicationUserName: 'aUserID');
      expect(fakeIOSPlatform.applicationNameHasTransactionRestored, 'aUserID');
    });
  });
}

class FakeIOSPlatform {
  FakeIOSPlatform() {
    channel.setMockMethodCallHandler(onMethodCall);
    getProductRequestFailTest = false;
  }
  // get product request
  List startProductRequestParam;
  bool getProductRequestFailTest;

  // refresh receipt request
  int refreshReceipt = 0;
  Map refreshReceiptParam;

  // payment queue
  List<SKPaymentWrapper> payments = [];
  List<Map<String, String>> transactionsFinished = [];
  String applicationNameHasTransactionRestored;

  Future<dynamic> onMethodCall(MethodCall call) {
    switch (call.method) {
      // request makers
      case '-[InAppPurchasePlugin startProductRequest:result:]':
        List<String> productIDS =
            List.castFrom<dynamic, String>(call.arguments);
        assert(productIDS is List<String>, 'invalid argument type');
        startProductRequestParam = call.arguments;
        if (getProductRequestFailTest) {
          return Future<Map<String, dynamic>>.value(null);
        }
        return Future<Map<String, dynamic>>.value(
            buildProductResponseMap(dummyProductResponseWrapper));
      case '-[InAppPurchasePlugin refreshReceipt:result:]':
        refreshReceipt++;
        refreshReceiptParam = call.arguments;
        return Future<void>.sync(() {});
      // receipt manager
      case '-[InAppPurchasePlugin retrieveReceiptData:result:]':
        return Future<String>.value('receipt data');
      // payment queue
      case '-[SKPaymentQueue canMakePayments:]':
        return Future<bool>.value(true);
      case '-[SKPaymentQueue transactions]':
        return Future<List<Map>>.value([buildTransactionMap(dummyTransaction)]);
      case '-[InAppPurchasePlugin addPayment:result:]':
        payments.add(SKPaymentWrapper.fromJson(call.arguments));
        return Future<void>.sync(() {});
      case '-[InAppPurchasePlugin finishTransaction:result:]':
        transactionsFinished.add(Map<String, String>.from(call.arguments));
        return Future<void>.sync(() {});
      case '-[InAppPurchasePlugin restoreTransactions:result:]':
        applicationNameHasTransactionRestored = call.arguments;
        return Future<void>.sync(() {});
    }
    return Future<void>.sync(() {});
  }
}

class TestPaymentTransactionObserver extends SKTransactionObserverWrapper {
  void updatedTransactions({List<SKPaymentTransactionWrapper> transactions}) {}

  void removedTransactions({List<SKPaymentTransactionWrapper> transactions}) {}

  void restoreCompletedTransactionsFailed({SKError error}) {}

  void paymentQueueRestoreCompletedTransactionsFinished() {}

  bool shouldAddStorePayment(
      {SKPaymentWrapper payment, SKProductWrapper product}) {
    return true;
  }
}
