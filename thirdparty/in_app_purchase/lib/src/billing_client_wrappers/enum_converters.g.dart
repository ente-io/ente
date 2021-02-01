// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_converters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SerializedEnums _$_SerializedEnumsFromJson(Map json) {
  return _SerializedEnums()
    ..response = _$enumDecode(_$BillingResponseEnumMap, json['response'])
    ..type = _$enumDecode(_$SkuTypeEnumMap, json['type'])
    ..purchaseState =
        _$enumDecode(_$PurchaseStateWrapperEnumMap, json['purchaseState'])
    ..prorationMode =
        _$enumDecode(_$ProrationModeEnumMap, json['prorationMode']);
}

Map<String, dynamic> _$_SerializedEnumsToJson(_SerializedEnums instance) =>
    <String, dynamic>{
      'response': _$BillingResponseEnumMap[instance.response],
      'type': _$SkuTypeEnumMap[instance.type],
      'purchaseState': _$PurchaseStateWrapperEnumMap[instance.purchaseState],
      'prorationMode': _$ProrationModeEnumMap[instance.prorationMode],
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

const _$BillingResponseEnumMap = {
  BillingResponse.serviceTimeout: -3,
  BillingResponse.featureNotSupported: -2,
  BillingResponse.serviceDisconnected: -1,
  BillingResponse.ok: 0,
  BillingResponse.userCanceled: 1,
  BillingResponse.serviceUnavailable: 2,
  BillingResponse.billingUnavailable: 3,
  BillingResponse.itemUnavailable: 4,
  BillingResponse.developerError: 5,
  BillingResponse.error: 6,
  BillingResponse.itemAlreadyOwned: 7,
  BillingResponse.itemNotOwned: 8,
};

const _$SkuTypeEnumMap = {
  SkuType.inapp: 'inapp',
  SkuType.subs: 'subs',
};

const _$PurchaseStateWrapperEnumMap = {
  PurchaseStateWrapper.unspecified_state: 0,
  PurchaseStateWrapper.purchased: 1,
  PurchaseStateWrapper.pending: 2,
};

const _$ProrationModeEnumMap = {
  ProrationMode.unknownSubscriptionUpgradeDowngradePolicy: 0,
  ProrationMode.immediateWithTimeProration: 1,
  ProrationMode.immediateAndChargeProratedPrice: 2,
  ProrationMode.immediateWithoutProration: 3,
  ProrationMode.deferred: 4,
};
