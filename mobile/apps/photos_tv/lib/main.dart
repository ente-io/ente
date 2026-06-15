import 'package:ente_crypto_api/ente_crypto_api.dart';
import 'package:ente_crypto_dart_adapter/ente_crypto_dart_adapter.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';

export 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCryptoApi(const EnteCryptoDartAdapter());
  await CryptoUtil.init();
  runApp(const PhotosTvApp());
}
