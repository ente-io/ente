import 'dart:async';
import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/scanner_camera_view.dart';
import 'package:ente_auth/ui/settings/data/import/google_auth_import.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScannerGoogleAuthPage extends StatefulWidget {
  const ScannerGoogleAuthPage({super.key});

  @override
  State<ScannerGoogleAuthPage> createState() => ScannerGoogleAuthPageState();
}

class ScannerGoogleAuthPageState extends State<ScannerGoogleAuthPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  StreamSubscription<Barcode>? _scanSubscription;
  String? totp;
  bool _hasCompletedScan = false;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      unawaited(controller?.pauseCamera());
    } else if (Platform.isIOS) {
      unawaited(controller?.resumeCamera());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scan)),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: ScannerCameraView(
              qrKey: qrKey,
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
    // Retain the Android camera restart workaround for scanner black screens.
    if (Platform.isAndroid) {
      unawaited(controller.pauseCamera());
      unawaited(controller.resumeCamera());
    }
    _cancelScanSubscription();
    _scanSubscription = controller.scannedDataStream.listen(_handleScanData);
  }

  void _handleScanData(Barcode scanData) {
    if (_hasCompletedScan) {
      return;
    }

    final qrCode = scanData.code;
    if (qrCode == null) {
      return;
    }

    if (!qrCode.startsWith(kGoogleAuthExportPrefix)) {
      if (mounted) {
        showToast(context, "Invalid QR code");
      }
      return;
    }

    try {
      final codes = parseGoogleAuth(qrCode);
      _completeWithCodes(codes);
    } catch (e) {
      _completeWithError(e);
    }
  }

  void _completeWithCodes(List<Code> codes) {
    if (_hasCompletedScan) {
      return;
    }
    _hasCompletedScan = true;
    _cancelScanSubscription();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(codes);
  }

  void _completeWithError(Object error) {
    if (_hasCompletedScan) {
      return;
    }
    _hasCompletedScan = true;
    _cancelScanSubscription();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    showToast(context, "Error $error");
  }

  void _cancelScanSubscription() {
    final scanSubscription = _scanSubscription;
    _scanSubscription = null;
    unawaited(scanSubscription?.cancel());
  }

  @override
  void dispose() {
    _cancelScanSubscription();
    super.dispose();
  }
}
