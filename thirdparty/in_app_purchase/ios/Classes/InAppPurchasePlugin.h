// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
@class FIAPaymentQueueHandler;
@class FIAPReceiptManager;

@interface InAppPurchasePlugin : NSObject <FlutterPlugin>

@property(strong, nonatomic) FIAPaymentQueueHandler *paymentQueueHandler;

- (instancetype)initWithReceiptManager:(FIAPReceiptManager *)receiptManager
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
