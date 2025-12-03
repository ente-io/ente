import 'package:ente_configuration/base_configuration.dart';

class Configuration extends BaseConfiguration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();

  @override
  // Provide all secure storage keys that should be wiped on logout.
  // Locker app uses the standard keys defined in BaseConfiguration.
  List<String> get secureStorageKeys => [
        BaseConfiguration.keyKey,
        BaseConfiguration.secretKeyKey,
      ];
}
