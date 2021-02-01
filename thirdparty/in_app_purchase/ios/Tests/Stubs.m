// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "Stubs.h"

@implementation SKProductSubscriptionPeriodStub

- (instancetype)initWithMap:(NSDictionary *)map {
  self = [super init];
  if (self) {
    [self setValue:map[@"numberOfUnits"] ?: @(0) forKey:@"numberOfUnits"];
    [self setValue:map[@"unit"] ?: @(0) forKey:@"unit"];
  }
  return self;
}

@end

@implementation SKProductDiscountStub

- (instancetype)initWithMap:(NSDictionary *)map {
  self = [super init];
  if (self) {
    [self setValue:[[NSDecimalNumber alloc] initWithString:map[@"price"]] ?: [NSNull null]
            forKey:@"price"];
    NSLocale *locale = NSLocale.systemLocale;
    [self setValue:locale ?: [NSNull null] forKey:@"priceLocale"];
    [self setValue:map[@"numberOfPeriods"] ?: @(0) forKey:@"numberOfPeriods"];
    SKProductSubscriptionPeriodStub *subscriptionPeriodSub =
        [[SKProductSubscriptionPeriodStub alloc] initWithMap:map[@"subscriptionPeriod"]];
    [self setValue:subscriptionPeriodSub forKey:@"subscriptionPeriod"];
    [self setValue:map[@"paymentMode"] ?: @(0) forKey:@"paymentMode"];
  }
  return self;
}

@end

@implementation SKProductStub

- (instancetype)initWithMap:(NSDictionary *)map {
  self = [super init];
  if (self) {
    [self setValue:map[@"productIdentifier"] ?: [NSNull null] forKey:@"productIdentifier"];
    [self setValue:map[@"localizedDescription"] ?: [NSNull null] forKey:@"localizedDescription"];
    [self setValue:map[@"localizedTitle"] ?: [NSNull null] forKey:@"localizedTitle"];
    [self setValue:map[@"downloadable"] ?: @NO forKey:@"downloadable"];
    [self setValue:[[NSDecimalNumber alloc] initWithString:map[@"price"]] ?: [NSNull null]
            forKey:@"price"];
    NSLocale *locale = NSLocale.systemLocale;
    [self setValue:locale ?: [NSNull null] forKey:@"priceLocale"];
    [self setValue:map[@"downloadContentLengths"] ?: @(0) forKey:@"downloadContentLengths"];
    if (@available(iOS 11.2, *)) {
      SKProductSubscriptionPeriodStub *period =
          [[SKProductSubscriptionPeriodStub alloc] initWithMap:map[@"subscriptionPeriod"]];
      [self setValue:period ?: [NSNull null] forKey:@"subscriptionPeriod"];
      SKProductDiscountStub *discount =
          [[SKProductDiscountStub alloc] initWithMap:map[@"introductoryPrice"]];
      [self setValue:discount ?: [NSNull null] forKey:@"introductoryPrice"];
      [self setValue:map[@"subscriptionGroupIdentifier"] ?: [NSNull null]
              forKey:@"subscriptionGroupIdentifier"];
    }
  }
  return self;
}

- (instancetype)initWithProductID:(NSString *)productIdentifier {
  self = [super init];
  if (self) {
    [self setValue:productIdentifier forKey:@"productIdentifier"];
  }
  return self;
}

@end

@interface SKProductRequestStub ()

@property(strong, nonatomic) NSSet *identifers;
@property(strong, nonatomic) NSError *error;

@end

@implementation SKProductRequestStub

- (instancetype)initWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers {
  self = [super initWithProductIdentifiers:productIdentifiers];
  self.identifers = productIdentifiers;
  return self;
}

- (instancetype)initWithFailureError:(NSError *)error {
  self = [super init];
  self.error = error;
  return self;
}

- (void)start {
  NSMutableArray *productArray = [NSMutableArray new];
  for (NSString *identifier in self.identifers) {
    [productArray addObject:@{@"productIdentifier" : identifier}];
  }
  SKProductsResponseStub *response =
      [[SKProductsResponseStub alloc] initWithMap:@{@"products" : productArray}];
  if (self.error) {
    [self.delegate request:self didFailWithError:self.error];
  } else {
    [self.delegate productsRequest:self didReceiveResponse:response];
  }
}

@end

@implementation SKProductsResponseStub

- (instancetype)initWithMap:(NSDictionary *)map {
  self = [super init];
  if (self) {
    NSMutableArray *products = [NSMutableArray new];
    for (NSDictionary *productMap in map[@"products"]) {
      SKProductStub *product = [[SKProductStub alloc] initWithMap:productMap];
      [products addObject:product];
    }
    [self setValue:products forKey:@"products"];
  }
  return self;
}

@end

@interface InAppPurchasePluginStub ()

@end

@implementation InAppPurchasePluginStub

- (SKProductRequestStub *)getProductRequestWithIdentifiers:(NSSet *)identifiers {
  return [[SKProductRequestStub alloc] initWithProductIdentifiers:identifiers];
}

- (SKProduct *)getProduct:(NSString *)productID {
  return [[SKProductStub alloc] initWithProductID:productID];
}

- (SKReceiptRefreshRequestStub *)getRefreshReceiptRequest:(NSDictionary *)properties {
  return [[SKReceiptRefreshRequestStub alloc] initWithReceiptProperties:properties];
}

@end

@interface SKPaymentQueueStub ()

@property(strong, nonatomic) id<SKPaymentTransactionObserver> observer;

@end

@implementation SKPaymentQueueStub

- (void)addTransactionObserver:(id<SKPaymentTransactionObserver>)observer {
  self.observer = observer;
}

- (void)addPayment:(SKPayment *)payment {
  SKPaymentTransactionStub *transaction =
      [[SKPaymentTransactionStub alloc] initWithState:self.testState payment:payment];
  [self.observer paymentQueue:self updatedTransactions:@[ transaction ]];
}

- (void)restoreCompletedTransactions {
  if ([self.observer
          respondsToSelector:@selector(paymentQueueRestoreCompletedTransactionsFinished:)]) {
    [self.observer paymentQueueRestoreCompletedTransactionsFinished:self];
  }
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
  if ([self.observer respondsToSelector:@selector(paymentQueue:removedTransactions:)]) {
    [self.observer paymentQueue:self removedTransactions:@[ transaction ]];
  }
}

@end

@implementation SKPaymentTransactionStub {
  SKPayment *_payment;
}

- (instancetype)initWithID:(NSString *)identifier {
  self = [super init];
  if (self) {
    [self setValue:identifier forKey:@"transactionIdentifier"];
  }
  return self;
}

- (instancetype)initWithMap:(NSDictionary *)map {
  self = [super init];
  if (self) {
    [self setValue:map[@"transactionIdentifier"] forKey:@"transactionIdentifier"];
    [self setValue:map[@"transactionState"] forKey:@"transactionState"];
    if (![map[@"originalTransaction"] isKindOfClass:[NSNull class]] &&
        map[@"originalTransaction"]) {
      [self setValue:[[SKPaymentTransactionStub alloc] initWithMap:map[@"originalTransaction"]]
              forKey:@"originalTransaction"];
    }
    [self setValue:map[@"error"] ? [[NSErrorStub alloc] initWithMap:map[@"error"]] : [NSNull null]
            forKey:@"error"];
    [self setValue:[NSDate dateWithTimeIntervalSince1970:[map[@"transactionTimeStamp"] doubleValue]]
            forKey:@"transactionDate"];
  }
  return self;
}

- (instancetype)initWithState:(SKPaymentTransactionState)state {
  self = [super init];
  if (self) {
    // Only purchased and restored transactions have transactionIdentifier:
    // https://developer.apple.com/documentation/storekit/skpaymenttransaction/1411288-transactionidentifier?language=objc
    if (state == SKPaymentTransactionStatePurchased || state == SKPaymentTransactionStateRestored) {
      [self setValue:@"fakeID" forKey:@"transactionIdentifier"];
    }
    [self setValue:@(state) forKey:@"transactionState"];
  }
  return self;
}

- (instancetype)initWithState:(SKPaymentTransactionState)state payment:(SKPayment *)payment {
  self = [super init];
  if (self) {
    // Only purchased and restored transactions have transactionIdentifier:
    // https://developer.apple.com/documentation/storekit/skpaymenttransaction/1411288-transactionidentifier?language=objc
    if (state == SKPaymentTransactionStatePurchased || state == SKPaymentTransactionStateRestored) {
      [self setValue:@"fakeID" forKey:@"transactionIdentifier"];
    }
    [self setValue:@(state) forKey:@"transactionState"];
    _payment = payment;
  }
  return self;
}

- (SKPayment *)payment {
  return _payment;
}

@end

@implementation NSErrorStub

- (instancetype)initWithMap:(NSDictionary *)map {
  return [self initWithDomain:[map objectForKey:@"domain"]
                         code:[[map objectForKey:@"code"] integerValue]
                     userInfo:[map objectForKey:@"userInfo"]];
}

@end

@implementation FIAPReceiptManagerStub : FIAPReceiptManager

- (NSData *)getReceiptData:(NSURL *)url {
  NSString *originalString = [NSString stringWithFormat:@"test"];
  return [[NSData alloc] initWithBase64EncodedString:originalString options:kNilOptions];
}

@end

@implementation SKReceiptRefreshRequestStub {
  NSError *_error;
}

- (instancetype)initWithReceiptProperties:(NSDictionary<NSString *, id> *)properties {
  self = [super initWithReceiptProperties:properties];
  return self;
}

- (instancetype)initWithFailureError:(NSError *)error {
  self = [super init];
  _error = error;
  return self;
}

- (void)start {
  if (_error) {
    [self.delegate request:self didFailWithError:_error];
  } else {
    [self.delegate requestDidFinish:self];
  }
}

@end
