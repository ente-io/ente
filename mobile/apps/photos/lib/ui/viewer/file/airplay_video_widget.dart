import 'package:flutter/material.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/airplay_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/file_util.dart';

class AirPlayVideoWidget extends StatefulWidget {
  final EnteFile file;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;

  const AirPlayVideoWidget(
    this.file, {
    this.tagPrefix,
    this.playbackCallback,
    super.key,
  });

  @override
  State<AirPlayVideoWidget> createState() => _AirPlayVideoWidgetState();
}

class _AirPlayVideoWidgetState extends State<AirPlayVideoWidget> {
  final _logger = Logger('AirPlayVideoWidget');
  final AirPlayService _airPlayService = AirPlayService.instance;
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
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
        widget.playbackCallback?.call(true);
      }
    } catch (e, s) {
      _logger.severe('Failed to load video for AirPlay', e, s);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: ${e.toString()}';
          _isLoading = false;
        });
      }
      widget.playbackCallback?.call(false);
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
              onPressed: _loadVideo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return Center(
        child: Text(
          'No video available',
          style: textTheme.body,
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: FlutterAVPlayerView(
            filePath: _localPath,
          ),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: _airPlayService.buildAirPlayIconButton(
            tintColor: Colors.white,
            activeTintColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}
