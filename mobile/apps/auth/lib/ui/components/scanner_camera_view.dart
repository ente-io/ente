import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ente_qr_scanner/ente_qr_scanner.dart';
import 'package:flutter/material.dart';

class ScannerCameraView extends StatefulWidget {
  const ScannerCameraView({
    required this.overlay,
    required this.onScannerCreated,
    this.onError,
    super.key,
  });

  final EnteQrScannerOverlay overlay;
  final ValueChanged<EnteQrScannerController> onScannerCreated;
  final ValueChanged<String>? onError;

  @override
  State<ScannerCameraView> createState() => _ScannerCameraViewState();
}

class _ScannerCameraViewState extends State<ScannerCameraView> {
  late final Future<bool> _isCameraScannerAvailable =
      _isCameraScannerAvailableOnDevice();

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return _buildScannerView();
    }

    return FutureBuilder<bool>(
      future: _isCameraScannerAvailable,
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return _buildScannerView();
        }
        return const ColoredBox(color: Colors.black);
      },
    );
  }

  Widget _buildScannerView() {
    return EnteQrScannerView(
      overlay: widget.overlay,
      onScannerCreated: widget.onScannerCreated,
      onError: widget.onError,
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
