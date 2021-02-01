// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>
#import "Stubs.h"

@import in_app_purchase;

@interface PaymentQueueTest : XCTestCase

@property(strong, nonatomic) NSDictionary *periodMap;
@property(strong, nonatomic) NSDictionary *discountMap;
@property(strong, nonatomic) NSDictionary *productMap;
@property(strong, nonatomic) NSDictionary *productResponseMap;

@end

@implementation PaymentQueueTest

- (void)setUp {
  self.periodMap = @{@"numberOfUnits" : @(0), @"unit" : @(0)};
  self.discountMap = @{
    @"price" : @1.0,
    @"currencyCode" : @"USD",
    @"numberOfPeriods" : @1,
    @"subscriptionPeriod" : self.periodMap,
    @"paymentMode" : @1
  };
  self.productMap = @{
    @"price" : @1.0,
    @"currencyCode" : @"USD",
    @"productIdentifier" : @"123",
    @"localizedTitle" : @"title",
    @"localizedDescription" : @"des",
    @"subscriptionPeriod" : self.periodMap,
    @"introductoryPrice" : self.discountMap,
    @"subscriptionGroupIdentifier" : @"com.group"
  };
  self.productResponseMap =
      @{@"products" : @[ self.productMap ], @"invalidProductIdentifiers" : [NSNull null]};
}

- (void)testTransactionPurchased {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"expect to get purchased transcation."];
  SKPaymentQueueStub *queue = [[SKPaymentQueueStub alloc] init];
  queue.testState = SKPaymentTransactionStatePurchased;
  __block SKPaymentTransactionStub *tran;
  FIAPaymentQueueHandler *handler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
        SKPaymentTransaction *transaction = transactions[0];
        tran = (SKPaymentTransactionStub *)transaction;
        [expectation fulfill];
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment *_Nonnull payment, SKProduct *_Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:handler];
  SKPayment *payment =
      [SKPayment paymentWithProduct:[[SKProductStub alloc] initWithMap:self.productResponseMap]];
  [handler addPayment:payment];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(tran.transactionState, SKPaymentTransactionStatePurchased);
  XCTAssertEqual(tran.transactionIdentifier, @"fakeID");
}

- (void)testTransactionFailed {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"expect to get failed transcation."];
  SKPaymentQueueStub *queue = [[SKPaymentQueueStub alloc] init];
  queue.testState = SKPaymentTransactionStateFailed;
  __block SKPaymentTransactionStub *tran;
  FIAPaymentQueueHandler *handler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
        SKPaymentTransaction *transaction = transactions[0];
        tran = (SKPaymentTransactionStub *)transaction;
        [expectation fulfill];
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment *_Nonnull payment, SKProduct *_Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:handler];
  SKPayment *payment =
      [SKPayment paymentWithProduct:[[SKProductStub alloc] initWithMap:self.productResponseMap]];
  [handler addPayment:payment];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(tran.transactionState, SKPaymentTransactionStateFailed);
  XCTAssertEqual(tran.transactionIdentifier, nil);
}

- (void)testTransactionRestored {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"expect to get restored transcation."];
  SKPaymentQueueStub *queue = [[SKPaymentQueueStub alloc] init];
  queue.testState = SKPaymentTransactionStateRestored;
  __block SKPaymentTransactionStub *tran;
  FIAPaymentQueueHandler *handler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
        SKPaymentTransaction *transaction = transactions[0];
        tran = (SKPaymentTransactionStub *)transaction;
        [expectation fulfill];
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment *_Nonnull payment, SKProduct *_Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:handler];
  SKPayment *payment =
      [SKPayment paymentWithProduct:[[SKProductStub alloc] initWithMap:self.productResponseMap]];
  [handler addPayment:payment];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(tran.transactionState, SKPaymentTransactionStateRestored);
  XCTAssertEqual(tran.transactionIdentifier, @"fakeID");
}

- (void)testTransactionPurchasing {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"expect to get purchasing transcation."];
  SKPaymentQueueStub *queue = [[SKPaymentQueueStub alloc] init];
  queue.testState = SKPaymentTransactionStatePurchasing;
  __block SKPaymentTransactionStub *tran;
  FIAPaymentQueueHandler *handler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
        SKPaymentTransaction *transaction = transactions[0];
        tran = (SKPaymentTransactionStub *)transaction;
        [expectation fulfill];
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment *_Nonnull payment, SKProduct *_Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:handler];
  SKPayment *payment =
      [SKPayment paymentWithProduct:[[SKProductStub alloc] initWithMap:self.productResponseMap]];
  [handler addPayment:payment];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(tran.transactionState, SKPaymentTransactionStatePurchasing);
  XCTAssertEqual(tran.transactionIdentifier, nil);
}

- (void)testTransactionDeferred {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"expect to get deffered transcation."];
  SKPaymentQueueStub *queue = [[SKPaymentQueueStub alloc] init];
  queue.testState = SKPaymentTransactionStateDeferred;
  __block SKPaymentTransactionStub *tran;
  FIAPaymentQueueHandler *handler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
        SKPaymentTransaction *transaction = transactions[0];
        tran = (SKPaymentTransactionStub *)transaction;
        [expectation fulfill];
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment *_Nonnull payment, SKProduct *_Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:handler];
  SKPayment *payment =
      [SKPayment paymentWithProduct:[[SKProductStub alloc] initWithMap:self.productResponseMap]];
  [handler addPayment:payment];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(tran.transactionState, SKPaymentTransactionStateDeferred);
  XCTAssertEqual(tran.transactionIdentifier, nil);
}

- (void)testFinishTransaction {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"handler.transactions should be empty."];
  SKPaymentQueueStub *queue = [[SKPaymentQueueStub alloc] init];
  queue.testState = SKPaymentTransactionStateDeferred;
  __block FIAPaymentQueueHandler *handler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
        XCTAssertEqual(transactions.count, 1);
        SKPaymentTransaction *transaction = transactions[0];
        [handler finishTransaction:transaction];
      }
      transactionRemoved:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
        XCTAssertEqual(transactions.count, 1);
        [expectation fulfill];
      }
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment *_Nonnull payment, SKProduct *_Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:handler];
  SKPayment *payment =
      [SKPayment paymentWithProduct:[[SKProductStub alloc] initWithMap:self.productResponseMap]];
  [handler addPayment:payment];
  [self waitForExpectations:@[ expectation ] timeout:5];
}

@end
