import 'dart:async';
import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/ui/components/buttons/icon_button_widget.dart';
import 'package:ente_auth/ui/components/scanner_camera_view.dart';
import 'package:ente_auth/utils/gallery_import_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScannerPageResult {
  final Code code;
  final bool fromGallery;

  const ScannerPageResult({required this.code, required this.fromGallery});
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => ScannerPageState();
}

class ScannerPageState extends State<ScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final Logger _logger = Logger('ScannerPage');
  QRViewController? controller;
  StreamSubscription<Barcode>? _scanSubscription;
  String? totp;
  bool _isImportingFromGallery = false;
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
    final bool showGalleryImport = PlatformDetector.isMobile();
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color galleryBackgroundColor = isLight
        ? Colors.black.withValues(alpha: 0.035)
        : Colors.white.withValues(alpha: 0.18);
    final Color galleryPressedColor = isLight
        ? Colors.black.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.26);
    final Color galleryIconColor = isLight ? Colors.black : Colors.white;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scan)),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: ScannerCameraView(
              qrKey: qrKey,
              onQRViewCreated: _onQRViewCreated,
              formatsAllowed: const [BarcodeFormat.qrcode],
            ),
          ),
          Expanded(
            flex: 1,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: showGalleryImport
                      ? Row(
                          children: [
                            Expanded(
                              child: totp != null
                                  ? Text(
                                      totp!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            Semantics(
                              button: true,
                              label: l10n.importFromGallery,
                              child: Opacity(
                                opacity: _isImportingFromGallery ? 0.5 : 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: IconButtonWidget(
                                    icon: Icons.photo_library_outlined,
                                    iconButtonType: IconButtonType.rounded,
                                    onTap: _isImportingFromGallery
                                        ? null
                                        : _handleImportFromGallery,
                                    defaultColor: galleryBackgroundColor,
                                    iconColor: galleryIconColor,
                                    pressedColor: galleryPressedColor,
                                    size: 28,
                                    padding: const EdgeInsets.all(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          totp ?? l10n.scanACode,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                ),
              ),
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
    if (_hasCompletedScan || _isImportingFromGallery) {
      return;
    }

    final qrCode = scanData.code;
    if (qrCode == null) {
      return;
    }

    try {
      final code = Code.fromOTPAuthUrl(qrCode);
      _completeWithResult(ScannerPageResult(code: code, fromGallery: false));
    } catch (e) {
      if (mounted) {
        showToast(context, context.l10n.invalidQRCode);
      }
    }
  }

  Future<void> _handleImportFromGallery() async {
    if (_isImportingFromGallery || _hasCompletedScan) {
      return;
    }
    setState(() {
      _isImportingFromGallery = true;
    });
    bool shouldResumeCamera = true;
    try {
      await controller?.pauseCamera();
      final Code? code = await pickCodeFromGallery(context, logger: _logger);
      if (code == null) {
        return;
      }
      shouldResumeCamera = false;
      _completeWithResult(ScannerPageResult(code: code, fromGallery: true));
    } finally {
      if (shouldResumeCamera && mounted && !_hasCompletedScan) {
        await controller?.resumeCamera();
      }
      if (mounted && !_hasCompletedScan) {
        setState(() {
          _isImportingFromGallery = false;
        });
      } else {
        _isImportingFromGallery = false;
      }
    }
  }

  void _completeWithResult(ScannerPageResult result) {
    if (_hasCompletedScan) {
      return;
    }
    _hasCompletedScan = true;
    _cancelScanSubscription();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(result);
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
