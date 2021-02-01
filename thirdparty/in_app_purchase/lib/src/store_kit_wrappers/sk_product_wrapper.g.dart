// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sk_product_wrapper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkProductResponseWrapper _$SkProductResponseWrapperFromJson(Map json) {
  return SkProductResponseWrapper(
    products: (json['products'] as List)
        .map((e) => SKProductWrapper.fromJson(e as Map))
        .toList(),
    invalidProductIdentifiers: (json['invalidProductIdentifiers'] as List)
        .map((e) => e as String)
        .toList(),
  );
}

Map<String, dynamic> _$SkProductResponseWrapperToJson(
        SkProductResponseWrapper instance) =>
    <String, dynamic>{
      'products': instance.products,
      'invalidProductIdentifiers': instance.invalidProductIdentifiers,
    };

SKProductSubscriptionPeriodWrapper _$SKProductSubscriptionPeriodWrapperFromJson(
    Map json) {
  return SKProductSubscriptionPeriodWrapper(
    numberOfUnits: json['numberOfUnits'] as int,
    unit: _$enumDecodeNullable(_$SKSubscriptionPeriodUnitEnumMap, json['unit']),
  );
}

Map<String, dynamic> _$SKProductSubscriptionPeriodWrapperToJson(
        SKProductSubscriptionPeriodWrapper instance) =>
    <String, dynamic>{
      'numberOfUnits': instance.numberOfUnits,
      'unit': _$SKSubscriptionPeriodUnitEnumMap[instance.unit],
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

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$SKSubscriptionPeriodUnitEnumMap = {
  SKSubscriptionPeriodUnit.day: 0,
  SKSubscriptionPeriodUnit.week: 1,
  SKSubscriptionPeriodUnit.month: 2,
  SKSubscriptionPeriodUnit.year: 3,
};

SKProductDiscountWrapper _$SKProductDiscountWrapperFromJson(Map json) {
  return SKProductDiscountWrapper(
    price: json['price'] as String,
    priceLocale: json['priceLocale'] == null
        ? null
        : SKPriceLocaleWrapper.fromJson(json['priceLocale'] as Map),
    numberOfPeriods: json['numberOfPeriods'] as int,
    paymentMode: _$enumDecodeNullable(
        _$SKProductDiscountPaymentModeEnumMap, json['paymentMode']),
    subscriptionPeriod: json['subscriptionPeriod'] == null
        ? null
        : SKProductSubscriptionPeriodWrapper.fromJson(
            json['subscriptionPeriod'] as Map),
  );
}

Map<String, dynamic> _$SKProductDiscountWrapperToJson(
        SKProductDiscountWrapper instance) =>
    <String, dynamic>{
      'price': instance.price,
      'priceLocale': instance.priceLocale,
      'numberOfPeriods': instance.numberOfPeriods,
      'paymentMode':
          _$SKProductDiscountPaymentModeEnumMap[instance.paymentMode],
      'subscriptionPeriod': instance.subscriptionPeriod,
    };

const _$SKProductDiscountPaymentModeEnumMap = {
  SKProductDiscountPaymentMode.payAsYouGo: 0,
  SKProductDiscountPaymentMode.payUpFront: 1,
  SKProductDiscountPaymentMode.freeTrail: 2,
};

SKProductWrapper _$SKProductWrapperFromJson(Map json) {
  return SKProductWrapper(
    productIdentifier: json['productIdentifier'] as String,
    localizedTitle: json['localizedTitle'] as String,
    localizedDescription: json['localizedDescription'] as String,
    priceLocale: json['priceLocale'] == null
        ? null
        : SKPriceLocaleWrapper.fromJson(json['priceLocale'] as Map),
    subscriptionGroupIdentifier: json['subscriptionGroupIdentifier'] as String,
    price: json['price'] as String,
    subscriptionPeriod: json['subscriptionPeriod'] == null
        ? null
        : SKProductSubscriptionPeriodWrapper.fromJson(
            json['subscriptionPeriod'] as Map),
    introductoryPrice: json['introductoryPrice'] == null
        ? null
        : SKProductDiscountWrapper.fromJson(json['introductoryPrice'] as Map),
  );
}

Map<String, dynamic> _$SKProductWrapperToJson(SKProductWrapper instance) =>
    <String, dynamic>{
      'productIdentifier': instance.productIdentifier,
      'localizedTitle': instance.localizedTitle,
      'localizedDescription': instance.localizedDescription,
      'priceLocale': instance.priceLocale,
      'subscriptionGroupIdentifier': instance.subscriptionGroupIdentifier,
      'price': instance.price,
      'subscriptionPeriod': instance.subscriptionPeriod,
      'introductoryPrice': instance.introductoryPrice,
    };

SKPriceLocaleWrapper _$SKPriceLocaleWrapperFromJson(Map json) {
  return SKPriceLocaleWrapper(
    currencySymbol: json['currencySymbol'] as String,
    currencyCode: json['currencyCode'] as String,
  );
}

Map<String, dynamic> _$SKPriceLocaleWrapperToJson(
        SKPriceLocaleWrapper instance) =>
    <String, dynamic>{
      'currencySymbol': instance.currencySymbol,
      'currencyCode': instance.currencyCode,
    };
