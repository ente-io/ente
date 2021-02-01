// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

part 'enum_converters.g.dart';

/// Serializer for [SKPaymentTransactionStateWrapper].
///
/// Use these in `@JsonSerializable()` classes by annotating them with
/// `@SKTransactionStatusConverter()`.
class SKTransactionStatusConverter
    implements JsonConverter<SKPaymentTransactionStateWrapper, int> {
  /// Default const constructor.
  const SKTransactionStatusConverter();

  @override
  SKPaymentTransactionStateWrapper fromJson(int json) =>
      _$enumDecode<SKPaymentTransactionStateWrapper>(
          _$SKPaymentTransactionStateWrapperEnumMap
              .cast<SKPaymentTransactionStateWrapper, dynamic>(),
          json);

  /// Converts an [SKPaymentTransactionStateWrapper] to a [PurchaseStatus].
  PurchaseStatus toPurchaseStatus(SKPaymentTransactionStateWrapper object) {
    switch (object) {
      case SKPaymentTransactionStateWrapper.purchasing:
      case SKPaymentTransactionStateWrapper.deferred:
        return PurchaseStatus.pending;
      case SKPaymentTransactionStateWrapper.purchased:
      case SKPaymentTransactionStateWrapper.restored:
        return PurchaseStatus.purchased;
      case SKPaymentTransactionStateWrapper.failed:
        return PurchaseStatus.error;
    }

    throw ArgumentError('$object isn\'t mapped to PurchaseStatus');
  }

  @override
  int toJson(SKPaymentTransactionStateWrapper object) =>
      _$SKPaymentTransactionStateWrapperEnumMap[object];
}

// Define a class so we generate serializer helper methods for the enums
@JsonSerializable()
class _SerializedEnums {
  SKPaymentTransactionStateWrapper response;
}
