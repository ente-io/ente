// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class SKPaymentTransaction;

NS_ASSUME_NONNULL_BEGIN

typedef void (^TransactionsUpdated)(NSArray<SKPaymentTransaction *> *transactions);
typedef void (^TransactionsRemoved)(NSArray<SKPaymentTransaction *> *transactions);
typedef void (^RestoreTransactionFailed)(NSError *error);
typedef void (^RestoreCompletedTransactionsFinished)(void);
typedef BOOL (^ShouldAddStorePayment)(SKPayment *payment, SKProduct *product);
typedef void (^UpdatedDownloads)(NSArray<SKDownload *> *downloads);

@interface FIAPaymentQueueHandler : NSObject <SKPaymentTransactionObserver>

- (instancetype)initWithQueue:(nonnull SKPaymentQueue *)queue
                     transactionsUpdated:(nullable TransactionsUpdated)transactionsUpdated
                      transactionRemoved:(nullable TransactionsRemoved)transactionsRemoved
                restoreTransactionFailed:(nullable RestoreTransactionFailed)restoreTransactionFailed
    restoreCompletedTransactionsFinished:
        (nullable RestoreCompletedTransactionsFinished)restoreCompletedTransactionsFinished
                   shouldAddStorePayment:(nullable ShouldAddStorePayment)shouldAddStorePayment
                        updatedDownloads:(nullable UpdatedDownloads)updatedDownloads;
// Can throw exceptions if the transaction type is purchasing, should always used in a @try block.
- (void)finishTransaction:(nonnull SKPaymentTransaction *)transaction;
- (void)restoreTransactions:(nullable NSString *)applicationName;
- (NSArray<SKPaymentTransaction *> *)getUnfinishedTransactions;

// This method needs to be called before any other methods.
- (void)startObservingPaymentQueue;

// Appends a payment to the SKPaymentQueue.
//
// @param payment Payment object to be added to the payment queue.
// @return whether "addPayment" was successful.
- (BOOL)addPayment:(SKPayment *)payment;

@end

NS_ASSUME_NONNULL_END
