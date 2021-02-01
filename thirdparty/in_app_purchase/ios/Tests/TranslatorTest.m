// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>
#import "Stubs.h"

@import in_app_purchase;

@interface TranslatorTest : XCTestCase

@property(strong, nonatomic) NSDictionary *periodMap;
@property(strong, nonatomic) NSDictionary *discountMap;
@property(strong, nonatomic) NSMutableDictionary *productMap;
@property(strong, nonatomic) NSDictionary *productResponseMap;
@property(strong, nonatomic) NSDictionary *paymentMap;
@property(strong, nonatomic) NSDictionary *transactionMap;
@property(strong, nonatomic) NSDictionary *errorMap;
@property(strong, nonatomic) NSDictionary *localeMap;

@end

@implementation TranslatorTest

- (void)setUp {
  self.periodMap = @{@"numberOfUnits" : @(0), @"unit" : @(0)};
  self.discountMap = @{
    @"price" : @"1",
    @"priceLocale" : [FIAObjectTranslator getMapFromNSLocale:NSLocale.systemLocale],
    @"numberOfPeriods" : @1,
    @"subscriptionPeriod" : self.periodMap,
    @"paymentMode" : @1
  };

  self.productMap = [[NSMutableDictionary alloc] initWithDictionary:@{
    @"price" : @"1",
    @"priceLocale" : [FIAObjectTranslator getMapFromNSLocale:NSLocale.systemLocale],
    @"productIdentifier" : @"123",
    @"localizedTitle" : @"title",
    @"localizedDescription" : @"des",
  }];
  if (@available(iOS 11.2, *)) {
    self.productMap[@"subscriptionPeriod"] = self.periodMap;
    self.productMap[@"introductoryPrice"] = self.discountMap;
  }

  if (@available(iOS 12.0, *)) {
    self.productMap[@"subscriptionGroupIdentifier"] = @"com.group";
  }

  self.productResponseMap =
      @{@"products" : @[ self.productMap ], @"invalidProductIdentifiers" : @[]};
  self.paymentMap = @{
    @"productIdentifier" : @"123",
    @"requestData" : @"abcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefghabcdefgh",
    @"quantity" : @(2),
    @"applicationUsername" : @"app user name",
    @"simulatesAskToBuyInSandbox" : @(NO)
  };
  NSDictionary *originalTransactionMap = @{
    @"transactionIdentifier" : @"567",
    @"transactionState" : @(SKPaymentTransactionStatePurchasing),
    @"payment" : [NSNull null],
    @"error" : [FIAObjectTranslator getMapFromNSError:[NSError errorWithDomain:@"test_stub"
                                                                          code:123
                                                                      userInfo:@{}]],
    @"transactionTimeStamp" : @([NSDate date].timeIntervalSince1970),
    @"originalTransaction" : [NSNull null],
  };
  self.transactionMap = @{
    @"transactionIdentifier" : @"567",
    @"transactionState" : @(SKPaymentTransactionStatePurchasing),
    @"payment" : [NSNull null],
    @"error" : [FIAObjectTranslator getMapFromNSError:[NSError errorWithDomain:@"test_stub"
                                                                          code:123
                                                                      userInfo:@{}]],
    @"transactionTimeStamp" : @([NSDate date].timeIntervalSince1970),
    @"originalTransaction" : originalTransactionMap,
  };
  self.errorMap = @{
    @"code" : @(123),
    @"domain" : @"test_domain",
    @"userInfo" : @{
      @"key" : @"value",
    }
  };
}

- (void)testSKProductSubscriptionPeriodStubToMap {
  if (@available(iOS 11.2, *)) {
    SKProductSubscriptionPeriodStub *period =
        [[SKProductSubscriptionPeriodStub alloc] initWithMap:self.periodMap];
    NSDictionary *map = [FIAObjectTranslator getMapFromSKProductSubscriptionPeriod:period];
    XCTAssertEqualObjects(map, self.periodMap);
  }
}

- (void)testSKProductDiscountStubToMap {
  if (@available(iOS 11.2, *)) {
    SKProductDiscountStub *discount = [[SKProductDiscountStub alloc] initWithMap:self.discountMap];
    NSDictionary *map = [FIAObjectTranslator getMapFromSKProductDiscount:discount];
    XCTAssertEqualObjects(map, self.discountMap);
  }
}

- (void)testProductToMap {
  SKProductStub *product = [[SKProductStub alloc] initWithMap:self.productMap];
  NSDictionary *map = [FIAObjectTranslator getMapFromSKProduct:product];
  XCTAssertEqualObjects(map, self.productMap);
}

- (void)testProductResponseToMap {
  SKProductsResponseStub *response =
      [[SKProductsResponseStub alloc] initWithMap:self.productResponseMap];
  NSDictionary *map = [FIAObjectTranslator getMapFromSKProductsResponse:response];
  XCTAssertEqualObjects(map, self.productResponseMap);
}

- (void)testPaymentToMap {
  SKMutablePayment *payment = [FIAObjectTranslator getSKMutablePaymentFromMap:self.paymentMap];
  NSDictionary *map = [FIAObjectTranslator getMapFromSKPayment:payment];
  XCTAssertEqualObjects(map, self.paymentMap);
}

- (void)testPaymentTransactionToMap {
  // payment is not KVC, cannot test payment field.
  SKPaymentTransactionStub *paymentTransaction =
      [[SKPaymentTransactionStub alloc] initWithMap:self.transactionMap];
  NSDictionary *map = [FIAObjectTranslator getMapFromSKPaymentTransaction:paymentTransaction];
  XCTAssertEqualObjects(map, self.transactionMap);
}

- (void)testError {
  NSErrorStub *error = [[NSErrorStub alloc] initWithMap:self.errorMap];
  NSDictionary *map = [FIAObjectTranslator getMapFromNSError:error];
  XCTAssertEqualObjects(map, self.errorMap);
}

- (void)testLocaleToMap {
  if (@available(iOS 10.0, *)) {
    NSLocale *system = NSLocale.systemLocale;
    NSDictionary *map = [FIAObjectTranslator getMapFromNSLocale:system];
    XCTAssertEqualObjects(map[@"currencySymbol"], system.currencySymbol);
  }
}

@end
