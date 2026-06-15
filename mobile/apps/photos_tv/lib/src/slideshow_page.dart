import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';
import 'slideshow_service.dart';

/// Slideshow screen shown after pairing.
class SlideshowPage extends StatefulWidget {
  /// Cast payload used to load slideshow images.
  final CastPayload payload;

  /// Creates slideshow page.
  const SlideshowPage({super.key, required this.payload});

  @override
  State<SlideshowPage> createState() => _SlideshowPageState();
}

class _SlideshowPageState extends State<SlideshowPage> {
  late final SlideshowService _service;
  Uint8List? _imageBytes;
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _service = SlideshowService(http.Client(), widget.payload);
    unawaited(_showNext());
    _timer = Timer.periodic(slideDuration, (_) => unawaited(_showNext()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _service.close();
    super.dispose();
  }

  Future<void> _showNext() async {
    try {
      final imageBytes = await _service.nextImage();
      if (!mounted) return;
      setState(() {
        _imageBytes = imageBytes;
        _message = imageBytes == null ? 'Try another album' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Pairing expired');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        child: imageBytes == null
            ? _StatusMessage(message: _message ?? 'Pairing Complete')
            : _SlideImage(imageBytes: imageBytes),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;

  const _StatusMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SlideImage extends StatelessWidget {
  final Uint8List imageBytes;

  const _SlideImage({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(imageBytes, fit: BoxFit.cover, opacity: _opacity),
        const ColoredBox(color: Colors.black54),
        Image.memory(imageBytes, fit: BoxFit.contain),
      ],
    );
  }
}

final _opacity = const AlwaysStoppedAnimation<double>(0.25);
