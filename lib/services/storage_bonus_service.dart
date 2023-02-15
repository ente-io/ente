import "package:photos/core/network/network.dart";
import "package:photos/gateways/storage_bonus_gw.dart";
import "package:shared_preferences/shared_preferences.dart";

class StorageBonusService {
  late StorageBonusGateway gateway;
  late SharedPreferences prefs;

  void init(SharedPreferences preferences) {
    prefs = preferences;
    gateway = StorageBonusGateway(NetworkClient.instance.enteDio);
  }

  StorageBonusService._privateConstructor();

  static StorageBonusService instance =
      StorageBonusService._privateConstructor();

  // getter for gateway
  StorageBonusGateway getGateway() {
    return gateway;
  }
}
