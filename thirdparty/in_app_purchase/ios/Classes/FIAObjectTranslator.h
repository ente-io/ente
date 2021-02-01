// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FIAObjectTranslator : NSObject

+ (NSDictionary *)getMapFromSKProduct:(SKProduct *)product;

+ (NSDictionary *)getMapFromSKProductSubscriptionPeriod:(SKProductSubscriptionPeriod *)period
    API_AVAILABLE(ios(11.2));

+ (NSDictionary *)getMapFromSKProductDiscount:(SKProductDiscount *)discount
    API_AVAILABLE(ios(11.2));

+ (NSDictionary *)getMapFromSKProductsResponse:(SKProductsResponse *)productResponse;

+ (NSDictionary *)getMapFromSKPayment:(SKPayment *)payment;

+ (NSDictionary *)getMapFromNSLocale:(NSLocale *)locale;

+ (SKMutablePayment *)getSKMutablePaymentFromMap:(NSDictionary *)map;

+ (NSDictionary *)getMapFromSKPaymentTransaction:(SKPaymentTransaction *)transaction;

+ (NSDictionary *)getMapFromNSError:(NSError *)error;

@end
;

NS_ASSUME_NONNULL_END
