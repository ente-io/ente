class Bonus {
  int storage;
  String type;
  int validTill;
  bool isRevoked;

  Bonus(this.storage, this.type, this.validTill, this.isRevoked);

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
  static Set<String> signUpBonusTypes = {'SIGN_UP', 'REFERRAL'};
  final List<Bonus> storageBonuses;

  BonusData(this.storageBonuses);

  List<Bonus> getAddOnBonuses() {
    return storageBonuses
        .where((b) => !signUpBonusTypes.contains(b.type))
        .toList();
  }

  int totalAddOnBonus() {
    return getAddOnBonuses().fold(0, (sum, bonus) => sum + bonus.storage);
  }

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
