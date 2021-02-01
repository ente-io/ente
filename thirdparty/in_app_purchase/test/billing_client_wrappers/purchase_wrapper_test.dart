// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:in_app_purchase/src/in_app_purchase/purchase_details.dart';
import 'package:test/test.dart';
import 'package:in_app_purchase/billing_client_wrappers.dart';
import 'package:in_app_purchase/src/billing_client_wrappers/enum_converters.dart';
import 'package:in_app_purchase/src/in_app_purchase/in_app_purchase_connection.dart';

final PurchaseWrapper dummyPurchase = PurchaseWrapper(
  orderId: 'orderId',
  packageName: 'packageName',
  purchaseTime: 0,
  signature: 'signature',
  sku: 'sku',
  purchaseToken: 'purchaseToken',
  isAutoRenewing: false,
  originalJson: '',
  developerPayload: 'dummy payload',
  isAcknowledged: true,
  purchaseState: PurchaseStateWrapper.purchased,
);

final PurchaseWrapper dummyUnacknowledgedPurchase = PurchaseWrapper(
  orderId: 'orderId',
  packageName: 'packageName',
  purchaseTime: 0,
  signature: 'signature',
  sku: 'sku',
  purchaseToken: 'purchaseToken',
  isAutoRenewing: false,
  originalJson: '',
  developerPayload: 'dummy payload',
  isAcknowledged: false,
  purchaseState: PurchaseStateWrapper.purchased,
);

final PurchaseHistoryRecordWrapper dummyPurchaseHistoryRecord =
    PurchaseHistoryRecordWrapper(
  purchaseTime: 0,
  signature: 'signature',
  sku: 'sku',
  purchaseToken: 'purchaseToken',
  originalJson: '',
  developerPayload: 'dummy payload',
);

final PurchaseWrapper dummyOldPurchase = PurchaseWrapper(
  orderId: 'oldOrderId',
  packageName: 'oldPackageName',
  purchaseTime: 0,
  signature: 'oldSignature',
  sku: 'oldSku',
  purchaseToken: 'oldPurchaseToken',
  isAutoRenewing: false,
  originalJson: '',
  developerPayload: 'old dummy payload',
  isAcknowledged: true,
  purchaseState: PurchaseStateWrapper.purchased,
);

void main() {
  group('PurchaseWrapper', () {
    test('converts from map', () {
      final PurchaseWrapper expected = dummyPurchase;
      final PurchaseWrapper parsed =
          PurchaseWrapper.fromJson(buildPurchaseMap(expected));

      expect(parsed, equals(expected));
    });

    test('toPurchaseDetails() should return correct PurchaseDetail object', () {
      final PurchaseDetails details =
          PurchaseDetails.fromPurchase(dummyPurchase);
      expect(details.purchaseID, dummyPurchase.orderId);
      expect(details.productID, dummyPurchase.sku);
      expect(details.transactionDate, dummyPurchase.purchaseTime.toString());
      expect(details.verificationData.source, IAPSource.GooglePlay);
      expect(details.verificationData.localVerificationData,
          dummyPurchase.originalJson);
      expect(details.verificationData.serverVerificationData,
          dummyPurchase.purchaseToken);
      expect(details.skPaymentTransaction, null);
      expect(details.billingClientPurchase, dummyPurchase);
      expect(details.pendingCompletePurchase, true);
    });
  });

  group('PurchaseHistoryRecordWrapper', () {
    test('converts from map', () {
      final PurchaseHistoryRecordWrapper expected = dummyPurchaseHistoryRecord;
      final PurchaseHistoryRecordWrapper parsed =
          PurchaseHistoryRecordWrapper.fromJson(
              buildPurchaseHistoryRecordMap(expected));

      expect(parsed, equals(expected));
    });
  });

  group('PurchasesResultWrapper', () {
    test('parsed from map', () {
      final BillingResponse responseCode = BillingResponse.ok;
      final List<PurchaseWrapper> purchases = <PurchaseWrapper>[
        dummyPurchase,
        dummyPurchase
      ];
      const String debugMessage = 'dummy Message';
      final BillingResultWrapper billingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      final PurchasesResultWrapper expected = PurchasesResultWrapper(
          billingResult: billingResult,
          responseCode: responseCode,
          purchasesList: purchases);
      final PurchasesResultWrapper parsed =
          PurchasesResultWrapper.fromJson(<String, dynamic>{
        'billingResult': buildBillingResultMap(billingResult),
        'responseCode': BillingResponseConverter().toJson(responseCode),
        'purchasesList': <Map<String, dynamic>>[
          buildPurchaseMap(dummyPurchase),
          buildPurchaseMap(dummyPurchase)
        ]
      });
      expect(parsed.billingResult, equals(expected.billingResult));
      expect(parsed.responseCode, equals(expected.responseCode));
      expect(parsed.purchasesList, containsAll(expected.purchasesList));
    });
  });

  group('PurchasesHistoryResult', () {
    test('parsed from map', () {
      final BillingResponse responseCode = BillingResponse.ok;
      final List<PurchaseHistoryRecordWrapper> purchaseHistoryRecordList =
          <PurchaseHistoryRecordWrapper>[
        dummyPurchaseHistoryRecord,
        dummyPurchaseHistoryRecord
      ];
      const String debugMessage = 'dummy Message';
      final BillingResultWrapper billingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      final PurchasesHistoryResult expected = PurchasesHistoryResult(
          billingResult: billingResult,
          purchaseHistoryRecordList: purchaseHistoryRecordList);
      final PurchasesHistoryResult parsed =
          PurchasesHistoryResult.fromJson(<String, dynamic>{
        'billingResult': buildBillingResultMap(billingResult),
        'purchaseHistoryRecordList': <Map<String, dynamic>>[
          buildPurchaseHistoryRecordMap(dummyPurchaseHistoryRecord),
          buildPurchaseHistoryRecordMap(dummyPurchaseHistoryRecord)
        ]
      });
      expect(parsed.billingResult, equals(billingResult));
      expect(parsed.purchaseHistoryRecordList,
          containsAll(expected.purchaseHistoryRecordList));
    });
  });
}

Map<String, dynamic> buildPurchaseMap(PurchaseWrapper original) {
  return <String, dynamic>{
    'orderId': original.orderId,
    'packageName': original.packageName,
    'purchaseTime': original.purchaseTime,
    'signature': original.signature,
    'sku': original.sku,
    'purchaseToken': original.purchaseToken,
    'isAutoRenewing': original.isAutoRenewing,
    'originalJson': original.originalJson,
    'developerPayload': original.developerPayload,
    'purchaseState': PurchaseStateConverter().toJson(original.purchaseState),
    'isAcknowledged': original.isAcknowledged,
  };
}

Map<String, dynamic> buildPurchaseHistoryRecordMap(
    PurchaseHistoryRecordWrapper original) {
  return <String, dynamic>{
    'purchaseTime': original.purchaseTime,
    'signature': original.signature,
    'sku': original.sku,
    'purchaseToken': original.purchaseToken,
    'originalJson': original.originalJson,
    'developerPayload': original.developerPayload,
  };
}

Map<String, dynamic> buildBillingResultMap(BillingResultWrapper original) {
  return <String, dynamic>{
    'responseCode': BillingResponseConverter().toJson(original.responseCode),
    'debugMessage': original.debugMessage,
  };
}
