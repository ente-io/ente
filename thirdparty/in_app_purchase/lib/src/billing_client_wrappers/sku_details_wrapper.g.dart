// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sku_details_wrapper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkuDetailsWrapper _$SkuDetailsWrapperFromJson(Map json) {
  return SkuDetailsWrapper(
    description: json['description'] as String,
    freeTrialPeriod: json['freeTrialPeriod'] as String,
    introductoryPrice: json['introductoryPrice'] as String,
    introductoryPriceMicros: json['introductoryPriceMicros'] as String,
    introductoryPriceCycles: json['introductoryPriceCycles'] as String,
    introductoryPricePeriod: json['introductoryPricePeriod'] as String,
    price: json['price'] as String,
    priceAmountMicros: json['priceAmountMicros'] as int,
    priceCurrencyCode: json['priceCurrencyCode'] as String,
    sku: json['sku'] as String,
    subscriptionPeriod: json['subscriptionPeriod'] as String,
    title: json['title'] as String,
    type: const SkuTypeConverter().fromJson(json['type'] as String),
    isRewarded: json['isRewarded'] as bool,
    originalPrice: json['originalPrice'] as String,
    originalPriceAmountMicros: json['originalPriceAmountMicros'] as int,
  );
}

Map<String, dynamic> _$SkuDetailsWrapperToJson(SkuDetailsWrapper instance) =>
    <String, dynamic>{
      'description': instance.description,
      'freeTrialPeriod': instance.freeTrialPeriod,
      'introductoryPrice': instance.introductoryPrice,
      'introductoryPriceMicros': instance.introductoryPriceMicros,
      'introductoryPriceCycles': instance.introductoryPriceCycles,
      'introductoryPricePeriod': instance.introductoryPricePeriod,
      'price': instance.price,
      'priceAmountMicros': instance.priceAmountMicros,
      'priceCurrencyCode': instance.priceCurrencyCode,
      'sku': instance.sku,
      'subscriptionPeriod': instance.subscriptionPeriod,
      'title': instance.title,
      'type': const SkuTypeConverter().toJson(instance.type),
      'isRewarded': instance.isRewarded,
      'originalPrice': instance.originalPrice,
      'originalPriceAmountMicros': instance.originalPriceAmountMicros,
    };

SkuDetailsResponseWrapper _$SkuDetailsResponseWrapperFromJson(Map json) {
  return SkuDetailsResponseWrapper(
    billingResult: BillingResultWrapper.fromJson(json['billingResult'] as Map),
    skuDetailsList: (json['skuDetailsList'] as List)
        .map((e) => SkuDetailsWrapper.fromJson(e as Map))
        .toList(),
  );
}

Map<String, dynamic> _$SkuDetailsResponseWrapperToJson(
        SkuDetailsResponseWrapper instance) =>
    <String, dynamic>{
      'billingResult': instance.billingResult,
      'skuDetailsList': instance.skuDetailsList,
    };

BillingResultWrapper _$BillingResultWrapperFromJson(Map json) {
  return BillingResultWrapper(
    responseCode:
        const BillingResponseConverter().fromJson(json['responseCode'] as int),
    debugMessage: json['debugMessage'] as String,
  );
}

Map<String, dynamic> _$BillingResultWrapperToJson(
        BillingResultWrapper instance) =>
    <String, dynamic>{
      'responseCode':
          const BillingResponseConverter().toJson(instance.responseCode),
      'debugMessage': instance.debugMessage,
    };
