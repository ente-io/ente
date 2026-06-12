import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScannerCameraView extends StatefulWidget {
  const ScannerCameraView({
    required this.qrKey,
    required this.onQRViewCreated,
    required this.formatsAllowed,
    this.overlay,
    super.key,
  });

  final GlobalKey qrKey;
  final QRViewCreatedCallback onQRViewCreated;
  final List<BarcodeFormat> formatsAllowed;
  final QrScannerOverlayShape? overlay;

  @override
  State<ScannerCameraView> createState() => _ScannerCameraViewState();
}

class _ScannerCameraViewState extends State<ScannerCameraView> {
  late final Future<bool> _isCameraScannerAvailable =
      _isCameraScannerAvailableOnDevice();

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return _buildQRView();
    }

    return FutureBuilder<bool>(
      future: _isCameraScannerAvailable,
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return _buildQRView();
        }
        return const ColoredBox(color: Colors.black);
      },
    );
  }

  Widget _buildQRView() {
    return QRView(
      key: widget.qrKey,
      overlay: widget.overlay,
      onQRViewCreated: widget.onQRViewCreated,
      formatsAllowed: widget.formatsAllowed,
    );
  }
}

Future<bool> _isCameraScannerAvailableOnDevice() async {
  if (!Platform.isIOS) {
    return true;
  }

  try {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    return iosInfo.isPhysicalDevice;
  } catch (_) {
    return true;
  }
}
