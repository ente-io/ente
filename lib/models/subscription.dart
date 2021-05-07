import 'dart:convert';

const kFreeProductID = "free";
const kStripe = "stripe";

class Subscription {
  final int id;
  final String productID;
  final int storage;
  final String originalTransactionID;
  final String paymentProvider;
  final int expiryTime;

  Subscription({
    this.id,
    this.productID,
    this.storage,
    this.originalTransactionID,
    this.paymentProvider,
    this.expiryTime,
  });

  bool isValid() {
    return expiryTime > DateTime.now().microsecondsSinceEpoch;
  }

  Subscription copyWith({
    int id,
    String productID,
    int storage,
    String originalTransactionID,
    String paymentProvider,
    int expiryTime,
  }) {
    return Subscription(
      id: id ?? this.id,
      productID: productID ?? this.productID,
      storage: storage ?? this.storage,
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
      'storage': storage,
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
      storage: map['storage'],
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
    return 'Subscription(id: $id, productID: $productID, storage: $storage, originalTransactionID: $originalTransactionID, paymentProvider: $paymentProvider, expiryTime: $expiryTime)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Subscription &&
        o.id == id &&
        o.productID == productID &&
        o.storage == storage &&
        o.originalTransactionID == originalTransactionID &&
        o.paymentProvider == paymentProvider &&
        o.expiryTime == expiryTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productID.hashCode ^
        storage.hashCode ^
        originalTransactionID.hashCode ^
        paymentProvider.hashCode ^
        expiryTime.hashCode;
  }
}
