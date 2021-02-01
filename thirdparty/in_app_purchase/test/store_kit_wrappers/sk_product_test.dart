// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:in_app_purchase/src/in_app_purchase/purchase_details.dart';
import 'package:test/test.dart';
import 'package:in_app_purchase/src/store_kit_wrappers/sk_product_wrapper.dart';
import 'package:in_app_purchase/src/in_app_purchase/in_app_purchase_connection.dart';
import 'package:in_app_purchase/src/in_app_purchase/product_details.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'sk_test_stub_objects.dart';

void main() {
  group('product related object wrapper test', () {
    test(
        'SKProductSubscriptionPeriodWrapper should have property values consistent with map',
        () {
      final SKProductSubscriptionPeriodWrapper wrapper =
          SKProductSubscriptionPeriodWrapper.fromJson(
              buildSubscriptionPeriodMap(dummySubscription));
      expect(wrapper, equals(dummySubscription));
    });

    test(
        'SKProductSubscriptionPeriodWrapper should have properties to be null if map is empty',
        () {
      final SKProductSubscriptionPeriodWrapper wrapper =
          SKProductSubscriptionPeriodWrapper.fromJson(<String, dynamic>{});
      expect(wrapper.numberOfUnits, null);
      expect(wrapper.unit, null);
    });

    test(
        'SKProductDiscountWrapper should have property values consistent with map',
        () {
      final SKProductDiscountWrapper wrapper =
          SKProductDiscountWrapper.fromJson(buildDiscountMap(dummyDiscount));
      expect(wrapper, equals(dummyDiscount));
    });

    test(
        'SKProductDiscountWrapper should have properties to be null if map is empty',
        () {
      final SKProductDiscountWrapper wrapper =
          SKProductDiscountWrapper.fromJson(<String, dynamic>{});
      expect(wrapper.price, null);
      expect(wrapper.priceLocale, null);
      expect(wrapper.numberOfPeriods, null);
      expect(wrapper.paymentMode, null);
      expect(wrapper.subscriptionPeriod, null);
    });

    test('SKProductWrapper should have property values consistent with map',
        () {
      final SKProductWrapper wrapper =
          SKProductWrapper.fromJson(buildProductMap(dummyProductWrapper));
      expect(wrapper, equals(dummyProductWrapper));
    });

    test('SKProductWrapper should have properties to be null if map is empty',
        () {
      final SKProductWrapper wrapper =
          SKProductWrapper.fromJson(<String, dynamic>{});
      expect(wrapper.productIdentifier, null);
      expect(wrapper.localizedTitle, null);
      expect(wrapper.localizedDescription, null);
      expect(wrapper.priceLocale, null);
      expect(wrapper.subscriptionGroupIdentifier, null);
      expect(wrapper.price, null);
      expect(wrapper.subscriptionPeriod, null);
    });

    test('toProductDetails() should return correct Product object', () {
      final SKProductWrapper wrapper =
          SKProductWrapper.fromJson(buildProductMap(dummyProductWrapper));
      final ProductDetails product = ProductDetails.fromSKProduct(wrapper);
      expect(product.title, wrapper.localizedTitle);
      expect(product.description, wrapper.localizedDescription);
      expect(product.id, wrapper.productIdentifier);
      expect(product.price,
          wrapper.priceLocale.currencySymbol + wrapper.price.toString());
      expect(product.skProduct, wrapper);
      expect(product.skuDetail, null);
    });

    test('SKProductResponse wrapper should match', () {
      final SkProductResponseWrapper wrapper =
          SkProductResponseWrapper.fromJson(
              buildProductResponseMap(dummyProductResponseWrapper));
      expect(wrapper, equals(dummyProductResponseWrapper));
    });
    test('SKProductResponse wrapper should default to empty list', () {
      final Map<String, List<dynamic>> productResponseMapEmptyList =
          <String, List<dynamic>>{
        'products': <Map<String, dynamic>>[],
        'invalidProductIdentifiers': <String>[],
      };
      final SkProductResponseWrapper wrapper =
          SkProductResponseWrapper.fromJson(productResponseMapEmptyList);
      expect(wrapper.products.length, 0);
      expect(wrapper.invalidProductIdentifiers.length, 0);
    });

    test('LocaleWrapper should have property values consistent with map', () {
      final SKPriceLocaleWrapper wrapper =
          SKPriceLocaleWrapper.fromJson(buildLocaleMap(dummyLocale));
      expect(wrapper, equals(dummyLocale));
    });
  });

  group('Payment queue related object tests', () {
    test('Should construct correct SKPaymentWrapper from json', () {
      SKPaymentWrapper payment =
          SKPaymentWrapper.fromJson(dummyPayment.toMap());
      expect(payment, equals(dummyPayment));
    });

    test('Should construct correct SKError from json', () {
      SKError error = SKError.fromJson(buildErrorMap(dummyError));
      expect(error, equals(dummyError));
    });

    test('Should construct correct SKTransactionWrapper from json', () {
      SKPaymentTransactionWrapper transaction =
          SKPaymentTransactionWrapper.fromJson(
              buildTransactionMap(dummyTransaction));
      expect(transaction, equals(dummyTransaction));
    });

    test('toPurchaseDetails() should return correct PurchaseDetail object', () {
      PurchaseDetails details =
          PurchaseDetails.fromSKTransaction(dummyTransaction, 'receipt data');
      expect(dummyTransaction.transactionIdentifier, details.purchaseID);
      expect(dummyTransaction.payment.productIdentifier, details.productID);
      expect((dummyTransaction.transactionTimeStamp * 1000).toInt().toString(),
          details.transactionDate);
      expect(details.verificationData.localVerificationData, 'receipt data');
      expect(details.verificationData.serverVerificationData, 'receipt data');
      expect(details.verificationData.source, IAPSource.AppStore);
      expect(details.skPaymentTransaction, dummyTransaction);
      expect(details.billingClientPurchase, null);
      expect(details.pendingCompletePurchase, true);
    });
    test('Should generate correct map of the payment object', () {
      Map map = dummyPayment.toMap();
      expect(map['productIdentifier'], dummyPayment.productIdentifier);
      expect(map['applicationUsername'], dummyPayment.applicationUsername);

      expect(map['requestData'], dummyPayment.requestData);

      expect(map['quantity'], dummyPayment.quantity);

      expect(map['simulatesAskToBuyInSandbox'],
          dummyPayment.simulatesAskToBuyInSandbox);
    });
  });
}
