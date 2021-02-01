// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@import in_app_purchase;

NS_ASSUME_NONNULL_BEGIN
API_AVAILABLE(ios(11.2), macos(10.13.2))
@interface SKProductSubscriptionPeriodStub : SKProductSubscriptionPeriod
- (instancetype)initWithMap:(NSDictionary *)map;
@end

API_AVAILABLE(ios(11.2), macos(10.13.2))
@interface SKProductDiscountStub : SKProductDiscount
- (instancetype)initWithMap:(NSDictionary *)map;
@end

@interface SKProductStub : SKProduct
- (instancetype)initWithMap:(NSDictionary *)map;
@end

@interface SKProductRequestStub : SKProductsRequest
- (instancetype)initWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers;
- (instancetype)initWithFailureError:(NSError *)error;
@end

@interface SKProductsResponseStub : SKProductsResponse
- (instancetype)initWithMap:(NSDictionary *)map;
@end

@interface InAppPurchasePluginStub : InAppPurchasePlugin
@end

@interface SKPaymentQueueStub : SKPaymentQueue
@property(assign, nonatomic) SKPaymentTransactionState testState;
@end

@interface SKPaymentTransactionStub : SKPaymentTransaction
- (instancetype)initWithMap:(NSDictionary *)map;
- (instancetype)initWithState:(SKPaymentTransactionState)state;
- (instancetype)initWithState:(SKPaymentTransactionState)state payment:(SKPayment *)payment;
@end

@interface SKMutablePaymentStub : SKMutablePayment
- (instancetype)initWithMap:(NSDictionary *)map;
@end

@interface NSErrorStub : NSError
- (instancetype)initWithMap:(NSDictionary *)map;
@end

@interface FIAPReceiptManagerStub : FIAPReceiptManager
@end

@interface SKReceiptRefreshRequestStub : SKReceiptRefreshRequest
- (instancetype)initWithFailureError:(NSError *)error;
@end

NS_ASSUME_NONNULL_END
