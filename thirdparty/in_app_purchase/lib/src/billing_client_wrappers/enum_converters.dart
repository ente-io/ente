// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:in_app_purchase/billing_client_wrappers.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enum_converters.g.dart';

/// Serializer for [BillingResponse].
///
/// Use these in `@JsonSerializable()` classes by annotating them with
/// `@BillingResponseConverter()`.
class BillingResponseConverter implements JsonConverter<BillingResponse, int> {
  /// Default const constructor.
  const BillingResponseConverter();

  @override
  BillingResponse fromJson(int json) => _$enumDecode<BillingResponse>(
      _$BillingResponseEnumMap.cast<BillingResponse, dynamic>(), json);

  @override
  int toJson(BillingResponse object) => _$BillingResponseEnumMap[object];
}

/// Serializer for [SkuType].
///
/// Use these in `@JsonSerializable()` classes by annotating them with
/// `@SkuTypeConverter()`.
class SkuTypeConverter implements JsonConverter<SkuType, String> {
  /// Default const constructor.
  const SkuTypeConverter();

  @override
  SkuType fromJson(String json) =>
      _$enumDecode<SkuType>(_$SkuTypeEnumMap.cast<SkuType, dynamic>(), json);

  @override
  String toJson(SkuType object) => _$SkuTypeEnumMap[object];
}

/// Serializer for [ProrationMode].
///
/// Use these in `@JsonSerializable()` classes by annotating them with
/// `@ProrationModeConverter()`.
class ProrationModeConverter implements JsonConverter<ProrationMode, int> {
  /// Default const constructor.
  const ProrationModeConverter();

  @override
  ProrationMode fromJson(int json) => _$enumDecode<ProrationMode>(
      _$ProrationModeEnumMap.cast<ProrationMode, dynamic>(), json);

  @override
  int toJson(ProrationMode object) => _$ProrationModeEnumMap[object];
}

// Define a class so we generate serializer helper methods for the enums
@JsonSerializable()
class _SerializedEnums {
  BillingResponse response;
  SkuType type;
  PurchaseStateWrapper purchaseState;
  ProrationMode prorationMode;
}

/// Serializer for [PurchaseStateWrapper].
///
/// Use these in `@JsonSerializable()` classes by annotating them with
/// `@PurchaseStateConverter()`.
class PurchaseStateConverter
    implements JsonConverter<PurchaseStateWrapper, int> {
  /// Default const constructor.
  const PurchaseStateConverter();

  @override
  PurchaseStateWrapper fromJson(int json) => _$enumDecode<PurchaseStateWrapper>(
      _$PurchaseStateWrapperEnumMap.cast<PurchaseStateWrapper, dynamic>(),
      json);

  @override
  int toJson(PurchaseStateWrapper object) =>
      _$PurchaseStateWrapperEnumMap[object];

  /// Converts the purchase state stored in `object` to a [PurchaseStatus].
  ///
  /// [PurchaseStateWrapper.unspecified_state] is mapped to [PurchaseStatus.error].
  PurchaseStatus toPurchaseStatus(PurchaseStateWrapper object) {
    switch (object) {
      case PurchaseStateWrapper.pending:
        return PurchaseStatus.pending;
      case PurchaseStateWrapper.purchased:
        return PurchaseStatus.purchased;
      case PurchaseStateWrapper.unspecified_state:
        return PurchaseStatus.error;
    }

    throw ArgumentError('$object isn\'t mapped to PurchaseStatus');
  }
}
