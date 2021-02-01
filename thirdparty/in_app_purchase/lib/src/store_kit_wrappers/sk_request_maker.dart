// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/src/channel.dart';
import 'sk_product_wrapper.dart';

/// A request maker that handles all the requests made by SKRequest subclasses.
///
/// There are multiple [SKRequest](https://developer.apple.com/documentation/storekit/skrequest?language=objc) subclasses handling different requests in the `StoreKit` with multiple delegate methods,
/// we consolidated all the `SKRequest` subclasses into this class to make requests in a more straightforward way.
/// The request maker will create a SKRequest object, immediately starting it, and completing the future successfully or throw an exception depending on what happened to the request.
class SKRequestMaker {
  /// Fetches product information for a list of given product identifiers.
  ///
  /// The `productIdentifiers` should contain legitimate product identifiers that you declared for the products in the iTunes Connect. Invalid identifiers
  /// will be stored and returned in [SkProductResponseWrapper.invalidProductIdentifiers]. Duplicate values in `productIdentifiers` will be omitted.
  /// If `productIdentifiers` is null, an `storekit_invalid_argument` error will be returned. If `productIdentifiers` is empty, a [SkProductResponseWrapper]
  /// will still be returned with [SkProductResponseWrapper.products] being null.
  ///
  /// [SkProductResponseWrapper] is returned if there is no error during the request.
  /// A [PlatformException] is thrown if the platform code making the request fails.
  Future<SkProductResponseWrapper> startProductRequest(
      List<String> productIdentifiers) async {
    final Map<String, dynamic> productResponseMap =
        await channel.invokeMapMethod<String, dynamic>(
      '-[InAppPurchasePlugin startProductRequest:result:]',
      productIdentifiers,
    );
    if (productResponseMap == null) {
      throw PlatformException(
        code: 'storekit_no_response',
        message: 'StoreKit: Failed to get response from platform.',
      );
    }
    return SkProductResponseWrapper.fromJson(productResponseMap);
  }

  /// Uses [SKReceiptRefreshRequest](https://developer.apple.com/documentation/storekit/skreceiptrefreshrequest?language=objc) to request a new receipt.
  ///
  /// If the receipt is invalid or missing, you can use this API to request a new receipt.
  /// The [receiptProperties] is optional and it exists only for [sandbox testing](https://developer.apple.com/apple-pay/sandbox-testing/). In the production app, call this API without pass in the [receiptProperties] parameter.
  /// To test in the sandbox, you can request a receipt with any combination of properties to test the state transitions related to [`Volume Purchase Plan`](https://www.apple.com/business/site/docs/VPP_Business_Guide.pdf) receipts.
  /// The valid keys in the receiptProperties are below (All of them are of type bool):
  /// * isExpired: whether the receipt is expired.
  /// * isRevoked: whether the receipt has been revoked.
  /// * isVolumePurchase: whether the receipt is a Volume Purchase Plan receipt.
  Future<void> startRefreshReceiptRequest({Map receiptProperties}) {
    return channel.invokeMethod<void>(
      '-[InAppPurchasePlugin refreshReceipt:result:]',
      receiptProperties,
    );
  }
}
