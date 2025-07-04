const freeProductID = "free";
const stripe = "stripe";
const appStore = "appstore";
const playStore = "playstore";

class Subscription {
  final String productID;
  final int storage;
  final String originalTransactionID;
  final String paymentProvider;
  final int expiryTime;
  final String price;
  final String period;
  final Attributes? attributes;

  Subscription({
    required this.productID,
    required this.storage,
    required this.originalTransactionID,
    required this.paymentProvider,
    required this.expiryTime,
    required this.price,
    required this.period,
    this.attributes,
  });

  bool isValid() {
    return expiryTime > DateTime.now().microsecondsSinceEpoch;
  }

  bool isYearlyPlan() {
    return 'year' == period;
  }

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return Subscription(
      productID: map['productID'],
      storage: map['storage'],
      originalTransactionID: map['originalTransactionID'],
      paymentProvider: map['paymentProvider'],
      expiryTime: map['expiryTime'],
      price: map['price'],
      period: map['period'],
      attributes: map["attributes"] != null
          ? Attributes.fromJson(map["attributes"])
          : null,
    );
  }
}

class Attributes {
  bool? isCancelled;
  String? customerID;

  Attributes({
    this.isCancelled,
    this.customerID,
  });

  Attributes.fromJson(dynamic json) {
    isCancelled = json["isCancelled"];
    customerID = json["customerID"];
  }
}
