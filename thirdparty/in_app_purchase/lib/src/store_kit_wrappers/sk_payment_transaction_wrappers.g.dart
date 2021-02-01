// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sk_payment_transaction_wrappers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SKPaymentTransactionWrapper _$SKPaymentTransactionWrapperFromJson(Map json) {
  return SKPaymentTransactionWrapper(
    payment: json['payment'] == null
        ? null
        : SKPaymentWrapper.fromJson(json['payment'] as Map),
    transactionState: const SKTransactionStatusConverter()
        .fromJson(json['transactionState'] as int),
    originalTransaction: json['originalTransaction'] == null
        ? null
        : SKPaymentTransactionWrapper.fromJson(
            json['originalTransaction'] as Map),
    transactionTimeStamp: (json['transactionTimeStamp'] as num)?.toDouble(),
    transactionIdentifier: json['transactionIdentifier'] as String,
    error:
        json['error'] == null ? null : SKError.fromJson(json['error'] as Map),
  );
}

Map<String, dynamic> _$SKPaymentTransactionWrapperToJson(
        SKPaymentTransactionWrapper instance) =>
    <String, dynamic>{
      'transactionState': const SKTransactionStatusConverter()
          .toJson(instance.transactionState),
      'payment': instance.payment,
      'originalTransaction': instance.originalTransaction,
      'transactionTimeStamp': instance.transactionTimeStamp,
      'transactionIdentifier': instance.transactionIdentifier,
      'error': instance.error,
    };
