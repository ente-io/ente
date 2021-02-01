// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "FIAPaymentQueueHandler.h"
#import "Stubs.h"

@import in_app_purchase;

@interface InAppPurchasePluginTest : XCTestCase

@property(strong, nonatomic) InAppPurchasePlugin* plugin;

@end

@implementation InAppPurchasePluginTest

- (void)setUp {
  self.plugin =
      [[InAppPurchasePluginStub alloc] initWithReceiptManager:[FIAPReceiptManagerStub new]];
}

- (void)tearDown {
}

- (void)testInvalidMethodCall {
  XCTestExpectation* expectation =
      [self expectationWithDescription:@"expect result to be not implemented"];
  FlutterMethodCall* call = [FlutterMethodCall methodCallWithMethodName:@"invalid" arguments:NULL];
  __block id result;
  [self.plugin handleMethodCall:call
                         result:^(id r) {
                           [expectation fulfill];
                           result = r;
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(result, FlutterMethodNotImplemented);
}

- (void)testCanMakePayments {
  XCTestExpectation* expectation = [self expectationWithDescription:@"expect result to be YES"];
  FlutterMethodCall* call =
      [FlutterMethodCall methodCallWithMethodName:@"-[SKPaymentQueue canMakePayments:]"
                                        arguments:NULL];
  __block id result;
  [self.plugin handleMethodCall:call
                         result:^(id r) {
                           [expectation fulfill];
                           result = r;
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(result, [NSNumber numberWithBool:YES]);
}

- (void)testGetProductResponse {
  XCTestExpectation* expectation =
      [self expectationWithDescription:@"expect response contains 1 item"];
  FlutterMethodCall* call = [FlutterMethodCall
      methodCallWithMethodName:@"-[InAppPurchasePlugin startProductRequest:result:]"
                     arguments:@[ @"123" ]];
  __block id result;
  [self.plugin handleMethodCall:call
                         result:^(id r) {
                           [expectation fulfill];
                           result = r;
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssert([result isKindOfClass:[NSDictionary class]]);
  NSArray* resultArray = [result objectForKey:@"products"];
  XCTAssertEqual(resultArray.count, 1);
  XCTAssertTrue([resultArray.firstObject[@"productIdentifier"] isEqualToString:@"123"]);
}

- (void)testAddPaymentFailure {
  XCTestExpectation* expectation =
      [self expectationWithDescription:@"result should return failed state"];
  FlutterMethodCall* call =
      [FlutterMethodCall methodCallWithMethodName:@"-[InAppPurchasePlugin addPayment:result:]"
                                        arguments:@{
                                          @"productIdentifier" : @"123",
                                          @"quantity" : @(1),
                                          @"simulatesAskToBuyInSandbox" : @YES,
                                        }];
  SKPaymentQueueStub* queue = [SKPaymentQueueStub new];
  queue.testState = SKPaymentTransactionStateFailed;
  __block SKPaymentTransaction* transactionForUpdateBlock;
  self.plugin.paymentQueueHandler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction*>* _Nonnull transactions) {
        SKPaymentTransaction* transaction = transactions[0];
        if (transaction.transactionState == SKPaymentTransactionStateFailed) {
          transactionForUpdateBlock = transaction;
          [expectation fulfill];
        }
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment* _Nonnull payment, SKProduct* _Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:self.plugin.paymentQueueHandler];

  [self.plugin handleMethodCall:call
                         result:^(id r){
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(transactionForUpdateBlock.transactionState, SKPaymentTransactionStateFailed);
}

- (void)testAddPaymentSuccessWithMockQueue {
  XCTestExpectation* expectation =
      [self expectationWithDescription:@"result should return success state"];
  FlutterMethodCall* call =
      [FlutterMethodCall methodCallWithMethodName:@"-[InAppPurchasePlugin addPayment:result:]"
                                        arguments:@{
                                          @"productIdentifier" : @"123",
                                          @"quantity" : @(1),
                                          @"simulatesAskToBuyInSandbox" : @YES,
                                        }];
  SKPaymentQueueStub* queue = [SKPaymentQueueStub new];
  queue.testState = SKPaymentTransactionStatePurchased;
  __block SKPaymentTransaction* transactionForUpdateBlock;
  self.plugin.paymentQueueHandler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction*>* _Nonnull transactions) {
        SKPaymentTransaction* transaction = transactions[0];
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
          transactionForUpdateBlock = transaction;
          [expectation fulfill];
        }
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment* _Nonnull payment, SKProduct* _Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:self.plugin.paymentQueueHandler];
  [self.plugin handleMethodCall:call
                         result:^(id r){
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqual(transactionForUpdateBlock.transactionState, SKPaymentTransactionStatePurchased);
}

- (void)testAddPaymentWithNullSandboxArgument {
  XCTestExpectation* expectation =
      [self expectationWithDescription:@"result should return success state"];
  XCTestExpectation* simulatesAskToBuyInSandboxExpectation =
      [self expectationWithDescription:@"payment isn't simulatesAskToBuyInSandbox"];
  FlutterMethodCall* call =
      [FlutterMethodCall methodCallWithMethodName:@"-[InAppPurchasePlugin addPayment:result:]"
                                        arguments:@{
                                          @"productIdentifier" : @"123",
                                          @"quantity" : @(1),
                                          @"simulatesAskToBuyInSandbox" : [NSNull null],
                                        }];
  SKPaymentQueueStub* queue = [SKPaymentQueueStub new];
  queue.testState = SKPaymentTransactionStatePurchased;
  __block SKPaymentTransaction* transactionForUpdateBlock;
  self.plugin.paymentQueueHandler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction*>* _Nonnull transactions) {
        SKPaymentTransaction* transaction = transactions[0];
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
          transactionForUpdateBlock = transaction;
          [expectation fulfill];
        }
        if (@available(iOS 8.3, *)) {
          if (!transaction.payment.simulatesAskToBuyInSandbox) {
            [simulatesAskToBuyInSandboxExpectation fulfill];
          }
        } else {
          [simulatesAskToBuyInSandboxExpectation fulfill];
        }
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:nil
      shouldAddStorePayment:^BOOL(SKPayment* _Nonnull payment, SKProduct* _Nonnull product) {
        return YES;
      }
      updatedDownloads:nil];
  [queue addTransactionObserver:self.plugin.paymentQueueHandler];
  [self.plugin handleMethodCall:call
                         result:^(id r){
                         }];
  [self waitForExpectations:@[ expectation, simulatesAskToBuyInSandboxExpectation ] timeout:5];
  XCTAssertEqual(transactionForUpdateBlock.transactionState, SKPaymentTransactionStatePurchased);
}

- (void)testRestoreTransactions {
  XCTestExpectation* expectation =
      [self expectationWithDescription:@"result successfully restore transactions"];
  FlutterMethodCall* call = [FlutterMethodCall
      methodCallWithMethodName:@"-[InAppPurchasePlugin restoreTransactions:result:]"
                     arguments:nil];
  SKPaymentQueueStub* queue = [SKPaymentQueueStub new];
  queue.testState = SKPaymentTransactionStatePurchased;
  __block BOOL callbackInvoked = NO;
  self.plugin.paymentQueueHandler = [[FIAPaymentQueueHandler alloc] initWithQueue:queue
      transactionsUpdated:^(NSArray<SKPaymentTransaction*>* _Nonnull transactions) {
      }
      transactionRemoved:nil
      restoreTransactionFailed:nil
      restoreCompletedTransactionsFinished:^() {
        callbackInvoked = YES;
        [expectation fulfill];
      }
      shouldAddStorePayment:nil
      updatedDownloads:nil];
  [queue addTransactionObserver:self.plugin.paymentQueueHandler];
  [self.plugin handleMethodCall:call
                         result:^(id r){
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertTrue(callbackInvoked);
}

- (void)testRetrieveReceiptData {
  XCTestExpectation* expectation = [self expectationWithDescription:@"receipt data retrieved"];
  FlutterMethodCall* call = [FlutterMethodCall
      methodCallWithMethodName:@"-[InAppPurchasePlugin retrieveReceiptData:result:]"
                     arguments:nil];
  __block NSDictionary* result;
  [self.plugin handleMethodCall:call
                         result:^(id r) {
                           result = r;
                           [expectation fulfill];
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  NSLog(@"%@", result);
  XCTAssertNotNil(result);
}

- (void)testRefreshReceiptRequest {
  XCTestExpectation* expectation = [self expectationWithDescription:@"expect success"];
  FlutterMethodCall* call =
      [FlutterMethodCall methodCallWithMethodName:@"-[InAppPurchasePlugin refreshReceipt:result:]"
                                        arguments:nil];
  __block BOOL result = NO;
  [self.plugin handleMethodCall:call
                         result:^(id r) {
                           result = YES;
                           [expectation fulfill];
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertTrue(result);
}

- (void)testGetPendingTransactions {
  XCTestExpectation* expectation = [self expectationWithDescription:@"expect success"];
  FlutterMethodCall* call =
      [FlutterMethodCall methodCallWithMethodName:@"-[SKPaymentQueue transactions]" arguments:nil];
  SKPaymentQueue* mockQueue = OCMClassMock(SKPaymentQueue.class);
  NSDictionary* transactionMap = @{
    @"transactionIdentifier" : [NSNull null],
    @"transactionState" : @(SKPaymentTransactionStatePurchasing),
    @"payment" : [NSNull null],
    @"error" : [FIAObjectTranslator getMapFromNSError:[NSError errorWithDomain:@"test_stub"
                                                                          code:123
                                                                      userInfo:@{}]],
    @"transactionTimeStamp" : @([NSDate date].timeIntervalSince1970),
    @"originalTransaction" : [NSNull null],
  };
  OCMStub(mockQueue.transactions).andReturn(@[ [[SKPaymentTransactionStub alloc]
      initWithMap:transactionMap] ]);

  __block NSArray* resultArray;
  self.plugin.paymentQueueHandler = [[FIAPaymentQueueHandler alloc] initWithQueue:mockQueue
                                                              transactionsUpdated:nil
                                                               transactionRemoved:nil
                                                         restoreTransactionFailed:nil
                                             restoreCompletedTransactionsFinished:nil
                                                            shouldAddStorePayment:nil
                                                                 updatedDownloads:nil];
  [self.plugin handleMethodCall:call
                         result:^(id r) {
                           resultArray = r;
                           [expectation fulfill];
                         }];
  [self waitForExpectations:@[ expectation ] timeout:5];
  XCTAssertEqualObjects(resultArray, @[ transactionMap ]);
}

@end
