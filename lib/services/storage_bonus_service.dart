import "package:photos/core/network/network.dart";
import "package:photos/gateways/storage_bonus_gw.dart";
import "package:shared_preferences/shared_preferences.dart";

class StorageBonusService {
  late StorageBonusGateway gateway;
  late SharedPreferences prefs;

  final String _showStorageBonus = "showStorageBonus.showBanner";

  void init(SharedPreferences preferences) {
    prefs = preferences;
    gateway = StorageBonusGateway(NetworkClient.instance.enteDio);
  }

  StorageBonusService._privateConstructor();

  static StorageBonusService instance =
      StorageBonusService._privateConstructor();

  bool shouldShowStorageBonus() {
    return prefs.getBool(_showStorageBonus) ?? true;
  }

  void markStorageBonusAsDone() {
    prefs.setBool(_showStorageBonus, false).ignore();
  }

  // getter for gateway
  StorageBonusGateway getGateway() {
    return gateway;
  }
}
