import 'package:flutter/material.dart';
import 'package:ente_qr/ente_qr.dart';

class QrTestPage extends StatefulWidget {
  @override
  _QrTestPageState createState() => _QrTestPageState();
}

class _QrTestPageState extends State<QrTestPage> {
  String _platformVersion = 'Unknown';
  final _enteQr = EnteQr();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _enteQr.getPlatformVersion() ?? 'Unknown platform version';
    } catch (e) {
      platformVersion = 'Failed to get platform version: $e';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Plugin Test'),
      ),
      body: Center(
        child: Text('Running on: $_platformVersion\n'),
      ),
    );
  }
}
