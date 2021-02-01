// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:in_app_purchase/billing_client_wrappers.dart';
import 'package:in_app_purchase/src/in_app_purchase/product_details.dart';
import 'package:in_app_purchase/src/billing_client_wrappers/enum_converters.dart';

final SkuDetailsWrapper dummySkuDetails = SkuDetailsWrapper(
  description: 'description',
  freeTrialPeriod: 'freeTrialPeriod',
  introductoryPrice: 'introductoryPrice',
  introductoryPriceMicros: 'introductoryPriceMicros',
  introductoryPriceCycles: 'introductoryPriceCycles',
  introductoryPricePeriod: 'introductoryPricePeriod',
  price: 'price',
  priceAmountMicros: 1000,
  priceCurrencyCode: 'priceCurrencyCode',
  sku: 'sku',
  subscriptionPeriod: 'subscriptionPeriod',
  title: 'title',
  type: SkuType.inapp,
  isRewarded: true,
  originalPrice: 'originalPrice',
  originalPriceAmountMicros: 1000,
);

void main() {
  group('SkuDetailsWrapper', () {
    test('converts from map', () {
      final SkuDetailsWrapper expected = dummySkuDetails;
      final SkuDetailsWrapper parsed =
          SkuDetailsWrapper.fromJson(buildSkuMap(expected));

      expect(parsed, equals(expected));
    });
  });

  group('SkuDetailsResponseWrapper', () {
    test('parsed from map', () {
      final BillingResponse responseCode = BillingResponse.ok;
      const String debugMessage = 'dummy message';
      final List<SkuDetailsWrapper> skusDetails = <SkuDetailsWrapper>[
        dummySkuDetails,
        dummySkuDetails
      ];
      BillingResultWrapper result = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      final SkuDetailsResponseWrapper expected = SkuDetailsResponseWrapper(
          billingResult: result, skuDetailsList: skusDetails);

      final SkuDetailsResponseWrapper parsed =
          SkuDetailsResponseWrapper.fromJson(<String, dynamic>{
        'billingResult': <String, dynamic>{
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'debugMessage': debugMessage,
        },
        'skuDetailsList': <Map<String, dynamic>>[
          buildSkuMap(dummySkuDetails),
          buildSkuMap(dummySkuDetails)
        ]
      });

      expect(parsed.billingResult, equals(expected.billingResult));
      expect(parsed.skuDetailsList, containsAll(expected.skuDetailsList));
    });

    test('toProductDetails() should return correct Product object', () {
      final SkuDetailsWrapper wrapper =
          SkuDetailsWrapper.fromJson(buildSkuMap(dummySkuDetails));
      final ProductDetails product = ProductDetails.fromSkuDetails(wrapper);
      expect(product.title, wrapper.title);
      expect(product.description, wrapper.description);
      expect(product.id, wrapper.sku);
      expect(product.price, wrapper.price);
      expect(product.skuDetail, wrapper);
      expect(product.skProduct, null);
    });

    test('handles empty list of skuDetails', () {
      final BillingResponse responseCode = BillingResponse.error;
      const String debugMessage = 'dummy message';
      final List<SkuDetailsWrapper> skusDetails = <SkuDetailsWrapper>[];
      BillingResultWrapper billingResult = BillingResultWrapper(
          responseCode: responseCode, debugMessage: debugMessage);
      final SkuDetailsResponseWrapper expected = SkuDetailsResponseWrapper(
          billingResult: billingResult, skuDetailsList: skusDetails);

      final SkuDetailsResponseWrapper parsed =
          SkuDetailsResponseWrapper.fromJson(<String, dynamic>{
        'billingResult': <String, dynamic>{
          'responseCode': BillingResponseConverter().toJson(responseCode),
          'debugMessage': debugMessage,
        },
        'skuDetailsList': <Map<String, dynamic>>[]
      });

      expect(parsed.billingResult, equals(expected.billingResult));
      expect(parsed.skuDetailsList, containsAll(expected.skuDetailsList));
    });
  });
}

Map<String, dynamic> buildSkuMap(SkuDetailsWrapper original) {
  return <String, dynamic>{
    'description': original.description,
    'freeTrialPeriod': original.freeTrialPeriod,
    'introductoryPrice': original.introductoryPrice,
    'introductoryPriceMicros': original.introductoryPriceMicros,
    'introductoryPriceCycles': original.introductoryPriceCycles,
    'introductoryPricePeriod': original.introductoryPricePeriod,
    'price': original.price,
    'priceAmountMicros': original.priceAmountMicros,
    'priceCurrencyCode': original.priceCurrencyCode,
    'sku': original.sku,
    'subscriptionPeriod': original.subscriptionPeriod,
    'title': original.title,
    'type': original.type.toString().substring(8),
    'isRewarded': original.isRewarded,
    'originalPrice': original.originalPrice,
    'originalPriceAmountMicros': original.originalPriceAmountMicros,
  };
}
