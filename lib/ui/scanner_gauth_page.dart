import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/settings/data/import/google_auth_import.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScannerGoogleAuthPage extends StatefulWidget {
  const ScannerGoogleAuthPage({super.key});

  @override
  State<ScannerGoogleAuthPage> createState() => ScannerGoogleAuthPageState();
}

class ScannerGoogleAuthPageState extends State<ScannerGoogleAuthPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? totp;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scan),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              overlay: QrScannerOverlayShape(
                borderColor: getEnteColorScheme(context).primary700,
              ),
              onQRViewCreated: _onQRViewCreated,
              formatsAllowed: const [BarcodeFormat.qrcode],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (totp != null) ? Text(totp!) : Text(l10n.scanACode),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    // h4ck to remove black screen on Android scanners: https://github.com/juliuscanute/qr_code_scanner/issues/560#issuecomment-1159611301
    if (Platform.isAndroid) {
      controller.pauseCamera();
      controller.resumeCamera();
    }
    controller.scannedDataStream.listen((scanData) {
      try {
        if (scanData.code == null) {
          return;
        }
        if (scanData.code!.startsWith(kGoogleAuthExportPrefix)) {
          List<Code> codes = parseGoogleAuth(scanData.code!);
          controller.dispose();
          Navigator.of(context).pop(codes);
        } else {
          showToast(context, "Invalid QR code");
        }
      } catch (e) {
        controller.dispose();
        Navigator.of(context).pop();
        showToast(context, "Error $e");
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
