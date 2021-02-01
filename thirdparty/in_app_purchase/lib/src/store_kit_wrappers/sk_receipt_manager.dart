// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:in_app_purchase/src/channel.dart';

///This class contains static methods to manage StoreKit receipts.
class SKReceiptManager {
  /// Retrieve the receipt data from your application's main bundle.
  ///
  /// The receipt data will be based64 encoded. The structure of the payload is defined using ASN.1.
  /// You can use the receipt data retrieved by this method to validate users' purchases.
  /// There are 2 ways to do so. Either validate locally or validate with App Store.
  /// For more details on how to validate the receipt data, you can refer to Apple's document about [`About Receipt Validation`](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Introduction.html#//apple_ref/doc/uid/TP40010573-CH105-SW1).
  /// If the receipt is invalid or missing, you can use [SKRequestMaker.startRefreshReceiptRequest] to request a new receipt.
  static Future<String> retrieveReceiptData() {
    return channel.invokeMethod<String>(
        '-[InAppPurchasePlugin retrieveReceiptData:result:]');
  }
}
