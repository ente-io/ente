import 'dart:convert';

class Subscription {
  final int id;
  final String productID;
  final int storageInMBs;
  final String originalTransactionID;
  final String paymentProvider;
  final int expiryTime;

  Subscription({
    this.id,
    this.productID,
    this.storageInMBs,
    this.originalTransactionID,
    this.paymentProvider,
    this.expiryTime,
  });

  bool isValid() {
    return expiryTime > DateTime.now().microsecondsSinceEpoch;
  }

  Subscription copyWith({
    int id,
    int productID,
    int storageInMBs,
    int originalTransactionID,
    int paymentProvider,
    int expiryTime,
  }) {
    return Subscription(
      id: id ?? this.id,
      productID: productID ?? this.productID,
      storageInMBs: storageInMBs ?? this.storageInMBs,
      originalTransactionID:
          originalTransactionID ?? this.originalTransactionID,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      expiryTime: expiryTime ?? this.expiryTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productID': productID,
      'storageInMBs': storageInMBs,
      'originalTransactionID': originalTransactionID,
      'paymentProvider': paymentProvider,
      'expiryTime': expiryTime,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Subscription(
      id: map['id'],
      productID: map['productID'],
      storageInMBs: map['storageInMBs'],
      originalTransactionID: map['originalTransactionID'],
      paymentProvider: map['paymentProvider'],
      expiryTime: map['expiryTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Subscription.fromJson(String source) =>
      Subscription.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Subscription(id: $id, productID: $productID, storageInMBs: $storageInMBs, originalTransactionID: $originalTransactionID, paymentProvider: $paymentProvider, expiryTime: $expiryTime)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Subscription &&
        o.id == id &&
        o.productID == productID &&
        o.storageInMBs == storageInMBs &&
        o.originalTransactionID == originalTransactionID &&
        o.paymentProvider == paymentProvider &&
        o.expiryTime == expiryTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productID.hashCode ^
        storageInMBs.hashCode ^
        originalTransactionID.hashCode ^
        paymentProvider.hashCode ^
        expiryTime.hashCode;
  }
}
