// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:in_app_purchase/billing_client_wrappers.dart';
import 'package:in_app_purchase/src/billing_client_wrappers/enum_converters.dart';
import 'package:in_app_purchase/src/channel.dart';
import '../stub_in_app_purchase_platform.dart';
import 'sku_details_wrapper_test.dart';
import 'purchase_wrapper_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final StubInAppPurchasePlatform stubPlatform = StubInAppPurchasePlatform();
  BillingClient billingClient;

  setUpAll(() =>
      channel.setMockMethodCallHandler(stubPlatform.fakeMethodCallHandler));

  setUp(() {
    billingClient = BillingClient((PurchasesResultWrapper _) {});
    billingClient.enablePendingPurchases();
    stubPlatform.reset();
  });

  group('isReady', () {
    test('true', () async {
      stubPlatform.addResponse(name: 'BillingClient#isReady()', value: true);
      expect(await billingClient.isReady(), isTrue);
    });

    test('false', () async {
      stubPlatform.addResponse(name: 'BillingClient#isReady()', value: false);
      expect(await billingClient.isReady(), isFalse);
    });
  });

  // Make sure that the enum values are supported and that the converter call
  // does not fail
  test('response states', () async {
    BillingResponseConverter converter = BillingResponseConverter();
    converter.fromJson(-3);
    converter.fromJson(-2);
    converter.fromJson(-1);
    converter.fromJson(0);
    converter.fromJson(1);
    converter.fromJson(2);
    converter.fromJson(3);
    converter.fromJson(4);
    converter.fromJson(5);
    converter.fromJson(6);
    converter.fromJson(7);
    converter.fromJson(8);
  });

  group('startConnection', () {
    final String methodName =
        'BillingClient#startConnection(BillingClientStateListener)';
    test('returns BillingResultWrapper', () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.developerError;
      stubPlatform.addResponse(
        name: methodName,
        value: <String, dynamic>{
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'debugMessage': debugMessage,
        },
      );

      BillingResultWrapper billingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      expect(
          await billingClient.startConnection(
              onBillingServiceDisconnected: () {}),
          equals(billingResult));
    });

    test('passes handle to onBillingServiceDisconnected', () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.developerError;
      stubPlatform.addResponse(
        name: methodName,
        value: <String, dynamic>{
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'debugMessage': debugMessage,
        },
      );
      await billingClient.startConnection(onBillingServiceDisconnected: () {});
      final MethodCall call = stubPlatform.previousCallMatching(methodName);
      expect(
          call.arguments,
          equals(
              <dynamic, dynamic>{'handle': 0, 'enablePendingPurchases': true}));
    });
  });

  test('endConnection', () async {
    final String endConnectionName = 'BillingClient#endConnection()';
    expect(stubPlatform.countPreviousCalls(endConnectionName), equals(0));
    stubPlatform.addResponse(name: endConnectionName, value: null);
    await billingClient.endConnection();
    expect(stubPlatform.countPreviousCalls(endConnectionName), equals(1));
  });

  group('querySkuDetails', () {
    final String queryMethodName =
        'BillingClient#querySkuDetailsAsync(SkuDetailsParams, SkuDetailsResponseListener)';

    test('handles empty skuDetails', () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.developerError;
      stubPlatform.addResponse(name: queryMethodName, value: <dynamic, dynamic>{
        'billingResult': <String, dynamic>{
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'debugMessage': debugMessage,
        },
        'skuDetailsList': <Map<String, dynamic>>[]
      });

      final SkuDetailsResponseWrapper response = await billingClient
          .querySkuDetails(
              skuType: SkuType.inapp, skusList: <String>['invalid']);

      BillingResultWrapper billingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      expect(response.billingResult, equals(billingResult));
      expect(response.skuDetailsList, isEmpty);
    });

    test('returns SkuDetailsResponseWrapper', () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.ok;
      stubPlatform.addResponse(name: queryMethodName, value: <String, dynamic>{
        'billingResult': <String, dynamic>{
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'debugMessage': debugMessage,
        },
        'skuDetailsList': <Map<String, dynamic>>[buildSkuMap(dummySkuDetails)]
      });

      final SkuDetailsResponseWrapper response = await billingClient
          .querySkuDetails(
              skuType: SkuType.inapp, skusList: <String>['invalid']);

      BillingResultWrapper billingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      expect(response.billingResult, equals(billingResult));
      expect(response.skuDetailsList, contains(dummySkuDetails));
    });
  });

  group('launchBillingFlow', () {
    final String launchMethodName =
        'BillingClient#launchBillingFlow(Activity, BillingFlowParams)';

    test('serializes and deserializes data', () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.ok;
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
        name: launchMethodName,
        value: buildBillingResultMap(expectedBillingResult),
      );
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";

      expect(
          await billingClient.launchBillingFlow(
              sku: skuDetails.sku, accountId: accountId),
          equals(expectedBillingResult));
      Map<dynamic, dynamic> arguments =
          stubPlatform.previousCallMatching(launchMethodName).arguments;
      expect(arguments['sku'], equals(skuDetails.sku));
      expect(arguments['accountId'], equals(accountId));
    });

    test(
        'serializes and deserializes data on change subscription without proration',
        () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.ok;
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
        name: launchMethodName,
        value: buildBillingResultMap(expectedBillingResult),
      );
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";

      expect(
          await billingClient.launchBillingFlow(
              sku: skuDetails.sku,
              accountId: accountId,
              oldSku: dummyOldPurchase.sku),
          equals(expectedBillingResult));
      Map<dynamic, dynamic> arguments =
          stubPlatform.previousCallMatching(launchMethodName).arguments;
      expect(arguments['sku'], equals(skuDetails.sku));
      expect(arguments['accountId'], equals(accountId));
      expect(arguments['oldSku'], equals(dummyOldPurchase.sku));
    });

    test(
        'serializes and deserializes data on change subscription with proration',
        () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.ok;
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
        name: launchMethodName,
        value: buildBillingResultMap(expectedBillingResult),
      );
      final SkuDetailsWrapper skuDetails = dummySkuDetails;
      final String accountId = "hashedAccountId";
      final prorationMode = ProrationMode.immediateAndChargeProratedPrice;

      expect(
          await billingClient.launchBillingFlow(
              sku: skuDetails.sku,
              accountId: accountId,
              oldSku: dummyOldPurchase.sku,
              prorationMode: prorationMode),
          equals(expectedBillingResult));
      Map<dynamic, dynamic> arguments =
          stubPlatform.previousCallMatching(launchMethodName).arguments;
      expect(arguments['sku'], equals(skuDetails.sku));
      expect(arguments['accountId'], equals(accountId));
      expect(arguments['oldSku'], equals(dummyOldPurchase.sku));
      expect(arguments['prorationMode'],
          ProrationModeConverter().toJson(prorationMode));
    });

    test('handles null accountId', () async {
      const String debugMessage = 'dummy message';
      final BillingResponse responseCode = BillingResponse.ok;
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
        name: launchMethodName,
        value: buildBillingResultMap(expectedBillingResult),
      );
      final SkuDetailsWrapper skuDetails = dummySkuDetails;

      expect(await billingClient.launchBillingFlow(sku: skuDetails.sku),
          equals(expectedBillingResult));
      Map<dynamic, dynamic> arguments =
          stubPlatform.previousCallMatching(launchMethodName).arguments;
      expect(arguments['sku'], equals(skuDetails.sku));
      expect(arguments['accountId'], isNull);
    });
  });

  group('queryPurchases', () {
    const String queryPurchasesMethodName =
        'BillingClient#queryPurchases(String)';

    test('serializes and deserializes data', () async {
      final BillingResponse expectedCode = BillingResponse.ok;
      final List<PurchaseWrapper> expectedList = <PurchaseWrapper>[
        dummyPurchase
      ];
      const String debugMessage = 'dummy message';
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: expectedCode, debugMessage: debugMessage);
      stubPlatform
          .addResponse(name: queryPurchasesMethodName, value: <String, dynamic>{
        'billingResult': buildBillingResultMap(expectedBillingResult),
        'responseCode': BillingResponseConverter().toJson(expectedCode),
        'purchasesList': expectedList
            .map((PurchaseWrapper purchase) => buildPurchaseMap(purchase))
            .toList(),
      });

      final PurchasesResultWrapper response =
          await billingClient.queryPurchases(SkuType.inapp);

      expect(response.billingResult, equals(expectedBillingResult));
      expect(response.responseCode, equals(expectedCode));
      expect(response.purchasesList, equals(expectedList));
    });

    test('checks for null params', () async {
      expect(() => billingClient.queryPurchases(null), throwsAssertionError);
    });

    test('handles empty purchases', () async {
      final BillingResponse expectedCode = BillingResponse.userCanceled;
      const String debugMessage = 'dummy message';
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: expectedCode, debugMessage: debugMessage);
      stubPlatform
          .addResponse(name: queryPurchasesMethodName, value: <String, dynamic>{
        'billingResult': buildBillingResultMap(expectedBillingResult),
        'responseCode': BillingResponseConverter().toJson(expectedCode),
        'purchasesList': [],
      });

      final PurchasesResultWrapper response =
          await billingClient.queryPurchases(SkuType.inapp);

      expect(response.billingResult, equals(expectedBillingResult));
      expect(response.responseCode, equals(expectedCode));
      expect(response.purchasesList, isEmpty);
    });
  });

  group('queryPurchaseHistory', () {
    const String queryPurchaseHistoryMethodName =
        'BillingClient#queryPurchaseHistoryAsync(String, PurchaseHistoryResponseListener)';

    test('serializes and deserializes data', () async {
      final BillingResponse expectedCode = BillingResponse.ok;
      final List<PurchaseHistoryRecordWrapper> expectedList =
          <PurchaseHistoryRecordWrapper>[
        dummyPurchaseHistoryRecord,
      ];
      const String debugMessage = 'dummy message';
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: expectedCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
          name: queryPurchaseHistoryMethodName,
          value: <String, dynamic>{
            'billingResult': buildBillingResultMap(expectedBillingResult),
            'purchaseHistoryRecordList': expectedList
                .map((PurchaseHistoryRecordWrapper purchaseHistoryRecord) =>
                    buildPurchaseHistoryRecordMap(purchaseHistoryRecord))
                .toList(),
          });

      final PurchasesHistoryResult response =
          await billingClient.queryPurchaseHistory(SkuType.inapp);
      expect(response.billingResult, equals(expectedBillingResult));
      expect(response.purchaseHistoryRecordList, equals(expectedList));
    });

    test('checks for null params', () async {
      expect(
          () => billingClient.queryPurchaseHistory(null), throwsAssertionError);
    });

    test('handles empty purchases', () async {
      final BillingResponse expectedCode = BillingResponse.userCanceled;
      const String debugMessage = 'dummy message';
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: expectedCode, debugMessage: debugMessage);
      stubPlatform.addResponse(name: queryPurchaseHistoryMethodName, value: {
        'billingResult': buildBillingResultMap(expectedBillingResult),
        'purchaseHistoryRecordList': [],
      });

      final PurchasesHistoryResult response =
          await billingClient.queryPurchaseHistory(SkuType.inapp);

      expect(response.billingResult, equals(expectedBillingResult));
      expect(response.purchaseHistoryRecordList, isEmpty);
    });
  });

  group('consume purchases', () {
    const String consumeMethodName =
        'BillingClient#consumeAsync(String, ConsumeResponseListener)';
    test('consume purchase async success', () async {
      final BillingResponse expectedCode = BillingResponse.ok;
      const String debugMessage = 'dummy message';
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: expectedCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
          name: consumeMethodName,
          value: buildBillingResultMap(expectedBillingResult));

      final BillingResultWrapper billingResult = await billingClient
          .consumeAsync('dummy token', developerPayload: 'dummy payload');

      expect(billingResult, equals(expectedBillingResult));
    });
  });

  group('acknowledge purchases', () {
    const String acknowledgeMethodName =
        'BillingClient#(AcknowledgePurchaseParams params, (AcknowledgePurchaseParams, AcknowledgePurchaseResponseListener)';
    test('acknowledge purchase success', () async {
      final BillingResponse expectedCode = BillingResponse.ok;
      const String debugMessage = 'dummy message';
      final BillingResultWrapper expectedBillingResult = BillingResultWrapper(
          responseCode: expectedCode, debugMessage: debugMessage);
      stubPlatform.addResponse(
          name: acknowledgeMethodName,
          value: buildBillingResultMap(expectedBillingResult));

      final BillingResultWrapper billingResult =
          await billingClient.acknowledgePurchase('dummy token',
              developerPayload: 'dummy payload');

      expect(billingResult, equals(expectedBillingResult));
    });
  });
}
