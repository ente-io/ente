// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_wrapper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseWrapper _$PurchaseWrapperFromJson(Map json) {
  return PurchaseWrapper(
    orderId: json['orderId'] as String,
    packageName: json['packageName'] as String,
    purchaseTime: json['purchaseTime'] as int,
    purchaseToken: json['purchaseToken'] as String,
    signature: json['signature'] as String,
    sku: json['sku'] as String,
    isAutoRenewing: json['isAutoRenewing'] as bool,
    originalJson: json['originalJson'] as String,
    developerPayload: json['developerPayload'] as String,
    isAcknowledged: json['isAcknowledged'] as bool,
    purchaseState:
        const PurchaseStateConverter().fromJson(json['purchaseState'] as int),
  );
}

Map<String, dynamic> _$PurchaseWrapperToJson(PurchaseWrapper instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'packageName': instance.packageName,
      'purchaseTime': instance.purchaseTime,
      'purchaseToken': instance.purchaseToken,
      'signature': instance.signature,
      'sku': instance.sku,
      'isAutoRenewing': instance.isAutoRenewing,
      'originalJson': instance.originalJson,
      'developerPayload': instance.developerPayload,
      'isAcknowledged': instance.isAcknowledged,
      'purchaseState':
          const PurchaseStateConverter().toJson(instance.purchaseState),
    };

PurchaseHistoryRecordWrapper _$PurchaseHistoryRecordWrapperFromJson(Map json) {
  return PurchaseHistoryRecordWrapper(
    purchaseTime: json['purchaseTime'] as int,
    purchaseToken: json['purchaseToken'] as String,
    signature: json['signature'] as String,
    sku: json['sku'] as String,
    originalJson: json['originalJson'] as String,
    developerPayload: json['developerPayload'] as String,
  );
}

Map<String, dynamic> _$PurchaseHistoryRecordWrapperToJson(
        PurchaseHistoryRecordWrapper instance) =>
    <String, dynamic>{
      'purchaseTime': instance.purchaseTime,
      'purchaseToken': instance.purchaseToken,
      'signature': instance.signature,
      'sku': instance.sku,
      'originalJson': instance.originalJson,
      'developerPayload': instance.developerPayload,
    };

PurchasesResultWrapper _$PurchasesResultWrapperFromJson(Map json) {
  return PurchasesResultWrapper(
    responseCode:
        const BillingResponseConverter().fromJson(json['responseCode'] as int),
    billingResult: BillingResultWrapper.fromJson(json['billingResult'] as Map),
    purchasesList: (json['purchasesList'] as List)
        .map((e) => PurchaseWrapper.fromJson(e as Map))
        .toList(),
  );
}

Map<String, dynamic> _$PurchasesResultWrapperToJson(
        PurchasesResultWrapper instance) =>
    <String, dynamic>{
      'billingResult': instance.billingResult,
      'responseCode':
          const BillingResponseConverter().toJson(instance.responseCode),
      'purchasesList': instance.purchasesList,
    };

PurchasesHistoryResult _$PurchasesHistoryResultFromJson(Map json) {
  return PurchasesHistoryResult(
    billingResult: BillingResultWrapper.fromJson(json['billingResult'] as Map),
    purchaseHistoryRecordList: (json['purchaseHistoryRecordList'] as List)
        .map((e) => PurchaseHistoryRecordWrapper.fromJson(e as Map))
        .toList(),
  );
}

Map<String, dynamic> _$PurchasesHistoryResultToJson(
        PurchasesHistoryResult instance) =>
    <String, dynamic>{
      'billingResult': instance.billingResult,
      'purchaseHistoryRecordList': instance.purchaseHistoryRecordList,
    };
