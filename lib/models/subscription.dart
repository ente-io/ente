// @dart=2.9

const freeProductID = "free";
const stripe = "stripe";
const appStore = "appstore";
const playStore = "playstore";

class Subscription {
  final int id;
  final String productID;
  final int storage;
  final String originalTransactionID;
  final String paymentProvider;
  final int expiryTime;
  final String price;
  final String period;
  final Attributes attributes;

  Subscription({
    this.id,
    this.productID,
    this.storage,
    this.originalTransactionID,
    this.paymentProvider,
    this.expiryTime,
    this.price,
    this.period,
    this.attributes,
  });

  bool isValid() {
    return expiryTime > DateTime.now().microsecondsSinceEpoch;
  }

  bool isYearlyPlan() {
    return 'year' == period;
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    if (map == null) {
      throw ArgumentError("argument is null");
    }
    return Subscription(
      id: map['id'],
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
  bool isCancelled;
  String customerID;

  Attributes({
    this.isCancelled,
    this.customerID,
  });

  Attributes.fromJson(dynamic json) {
    isCancelled = json["isCancelled"];
    customerID = json["customerID"];
  }
}
