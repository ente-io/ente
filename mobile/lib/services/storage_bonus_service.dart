import "package:photos/core/network/network.dart";
import "package:photos/gateways/storage_bonus_gw.dart";
import "package:shared_preferences/shared_preferences.dart";

class StorageBonusService {
  late StorageBonusGateway gateway;
  late SharedPreferences prefs;

  final int minTapCountBeforeHidingBanner = 5;
  final String _showStorageBonusTapCount = "showStorageBonus.tap_count";

  void init(SharedPreferences preferences) {
    prefs = preferences;
    gateway = StorageBonusGateway(NetworkClient.instance.enteDio);
  }

  StorageBonusService._privateConstructor();

  static StorageBonusService instance =
      StorageBonusService._privateConstructor();

  // returns true if _showStorageBonusTapCount value is less than minTapCountBeforeHidingBanner
  bool shouldShowStorageBonus() {
    final tapCount = prefs.getInt(_showStorageBonusTapCount) ?? 0;
    return tapCount <= minTapCountBeforeHidingBanner;
  }

  void markStorageBonusAsDone() {
    final tapCount = prefs.getInt(_showStorageBonusTapCount) ?? 0;
    prefs.setInt(_showStorageBonusTapCount, tapCount + 1).ignore();
  }

  // getter for gateway
  StorageBonusGateway getGateway() {
    return gateway;
  }
}
