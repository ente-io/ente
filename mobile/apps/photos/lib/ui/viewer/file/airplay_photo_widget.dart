import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/airplay_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/file_util.dart';

class AirPlayPhotoWidget extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;

  const AirPlayPhotoWidget(
    this.file, {
    this.tagPrefix,
    super.key,
  });

  @override
  State<AirPlayPhotoWidget> createState() => _AirPlayPhotoWidgetState();
}

class _AirPlayPhotoWidgetState extends State<AirPlayPhotoWidget> {
  final _logger = Logger('AirPlayPhotoWidget');
  final AirPlayService _airPlayService = AirPlayService.instance;
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Download the file locally first
      final file = await getFileFromServer(widget.file);
      if (file != null && mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      _logger.severe('Failed to load photo for AirPlay', e, s);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load photo: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);

    if (!_airPlayService.isSupported) {
      return Center(
        child: Text(
          'AirPlay is not supported on this device',
          style: textTheme.body,
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: EnteLoadingWidget(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: getEnteColorScheme(context).warning700,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: textTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPhoto,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return Center(
        child: Text(
          'No photo available',
          style: textTheme.body,
        ),
      );
    }

    // For photos, we'll display the image locally and provide AirPlay button
    return Stack(
      children: [
        Center(
          child: Image.file(
            File(_localPath!),
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: _airPlayService.buildAirPlayIconButton(
              tintColor: Colors.white,
              activeTintColor: Colors.blue,
            ),
          ),
        ),
        // Add instruction text
        Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tap the AirPlay button to display this photo on your TV',
              style: textTheme.small.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
