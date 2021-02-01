// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//
//  FIAPReceiptManager.m
//  in_app_purchase
//
//  Created by Chris Yang on 3/2/19.
//

#import "FIAPReceiptManager.h"
#import <Flutter/Flutter.h>

@implementation FIAPReceiptManager

- (NSString *)retrieveReceiptWithError:(FlutterError **)error {
  NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
  NSData *receipt = [self getReceiptData:receiptURL];
  if (!receipt) {
    *error = [FlutterError errorWithCode:@"storekit_no_receipt"
                                 message:@"Cannot find receipt for the current main bundle."
                                 details:nil];
    return nil;
  }
  return [receipt base64EncodedStringWithOptions:kNilOptions];
}

- (NSData *)getReceiptData:(NSURL *)url {
  return [NSData dataWithContentsOfURL:url];
}

@end
