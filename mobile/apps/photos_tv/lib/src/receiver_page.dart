import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models.dart';
import 'pairing_service.dart';
import 'pairing_view.dart';
import 'slideshow_page.dart';

/// Receiver page that pairs TV and starts slideshow.
class ReceiverPage extends StatefulWidget {
  /// Creates receiver page.
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  final _pairing = PairingService(http.Client());
  Registration? _registration;
  CastPayload? _payload;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_startPairing());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pairing.close();
    super.dispose();
  }

  Future<void> _startPairing() async {
    _pollTimer?.cancel();
    setState(() {
      _registration = null;
      _payload = null;
      _error = null;
    });
    try {
      final registration = await _pairing.register();
      if (!mounted) return;
      setState(() => _registration = registration);
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(_pollPayload(registration));
      });
      unawaited(_pollPayload(registration));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _pollPayload(Registration registration) async {
    try {
      final payload = await _pairing.getCastPayload(registration);
      if (payload == null || !mounted) return;
      _pollTimer?.cancel();
      setState(() => _payload = payload);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) unawaited(_startPairing());
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    if (payload != null) return SlideshowPage(payload: payload);
    return PairingView(
      pairingCode: _registration?.pairingCode,
      error: _error,
      onRetry: _startPairing,
    );
  }
}
