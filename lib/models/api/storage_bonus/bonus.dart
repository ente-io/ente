class Bonus {
  int storage;
  String type;
  int validTill;
  bool isRevoked;

  Bonus(this.storage, this.type, this.validTill, this.isRevoked);

  // fromJson
  factory Bonus.fromJson(Map<String, dynamic> json) {
    return Bonus(
      json['storage'],
      json['type'],
      json['validTill'],
      json['isRevoked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storage': storage,
      'type': type,
      'validTill': validTill,
      'isRevoked': isRevoked,
    };
  }
}

class BonusData {
  final List<Bonus> storageBonuses;

  BonusData(this.storageBonuses);

  factory BonusData.fromJson(Map<String, dynamic>? json) {
    if (json == null || json['storageBonuses'] == null) {
      return BonusData([]);
    }
    return BonusData(
      (json['storageBonuses'] as List)
          .map((bonus) => Bonus.fromJson(bonus))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storageBonuses': storageBonuses.map((bonus) => bonus.toJson()).toList(),
    };
  }
}
