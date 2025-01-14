import 'dart:math';

import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import "package:flutter/material.dart";
import 'package:qr_flutter/qr_flutter.dart';

class ViewQrPage extends StatelessWidget {
  final Code? code;

  ViewQrPage({this.code, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double qrSize = min(screenWidth - 80, 300.0);
    final enteTextTheme = getEnteTextTheme(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrCode),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 40),
            child: Column(
              children: [
                QrImageView(
                  data: code!.rawData
                      .replaceAll('algorithm=Algorithm.', 'algorithm='),
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  version: QrVersions.auto,
                  size: qrSize,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.account,
                      style: enteTextTheme.largeMuted,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      code?.account ?? '',
                      style: enteTextTheme.largeBold,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.codeIssuerHint,
                      style: enteTextTheme.largeMuted,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      code?.issuer ?? '',
                      style: enteTextTheme.largeBold,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 80,
                ),
                SizedBox(
                  width: 400,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4,
                      ),
                      child: Text(l10n.back),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
