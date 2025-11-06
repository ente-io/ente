import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/ui/components/buttons/icon_button_widget.dart';
import 'package:ente_auth/utils/gallery_import_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScannerPageResult {
  final Code code;
  final bool fromGallery;

  const ScannerPageResult({
    required this.code,
    required this.fromGallery,
  });
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
  String? totp;
  bool _isImportingFromGallery = false;

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
    final bool showGalleryImport = PlatformUtil.isMobile();
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color galleryBackgroundColor =
        isLight ? Colors.black.withOpacity(0.035) : Colors.white.withOpacity(0.18);
    final Color galleryPressedColor =
        isLight ? Colors.black.withOpacity(0.07) : Colors.white.withOpacity(0.26);
    final Color galleryIconColor = isLight ? Colors.black : Colors.white;
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
              onQRViewCreated: _onQRViewCreated,
              formatsAllowed: const [BarcodeFormat.qrcode],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: showGalleryImport
                    ? Row(
                        children: [
                          Expanded(
                            child: totp != null
                                ? Text(
                                    totp!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
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
        final code = Code.fromOTPAuthUrl(scanData.code!);
        controller.dispose();
        Navigator.of(context).pop(
          ScannerPageResult(code: code, fromGallery: false),
        );
      } catch (e) {
        // Log
        showToast(context, context.l10n.invalidQRCode);
      }
    });
  }

  Future<void> _handleImportFromGallery() async {
    if (_isImportingFromGallery) {
      return;
    }
    setState(() {
      _isImportingFromGallery = true;
    });
    try {
      final Code? code =
          await pickCodeFromGallery(context, logger: _logger);
      if (code == null) {
        return;
      }
      controller?.dispose();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        ScannerPageResult(code: code, fromGallery: true),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImportingFromGallery = false;
        });
      } else {
        _isImportingFromGallery = false;
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
