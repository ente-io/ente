import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file/file.dart';

class AirPlayService {
  static final AirPlayService _instance = AirPlayService._internal();
  factory AirPlayService() => _instance;
  AirPlayService._internal();

  static AirPlayService get instance => _instance;

  final Logger _logger = Logger('AirPlayService');

  bool get isSupported => Platform.isIOS;

  Widget buildAirPlayButton({
    Color? tintColor,
    Color? activeTintColor,
    Color? backgroundColor,
    double width = 44,
    double height = 44,
  }) {
    if (!isSupported) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: width,
      height: height,
      child: AirPlayRoutePickerView(
        tintColor: tintColor ?? Colors.white,
        activeTintColor: activeTintColor ?? Colors.blue,
        backgroundColor: backgroundColor ?? Colors.transparent,
      ),
    );
  }

  Widget buildAirPlayIconButton({
    Color? tintColor,
    Color? activeTintColor,
  }) {
    if (!isSupported) {
      return const SizedBox.shrink();
    }

    return const AirPlayIconButton();
  }

  Future<void> playVideo(String filePath, {String? urlString}) async {
    if (!isSupported) {
      _logger.warning('AirPlay is not supported on this platform');
      return;
    }

    try {
      _logger.info('Playing video via AirPlay: ${urlString ?? filePath}');
      // The FlutterAVPlayerView will handle AirPlay automatically
      // when the AirPlay button is tapped and a device is selected
    } catch (e, s) {
      _logger.severe('Failed to play video via AirPlay', e, s);
      rethrow;
    }
  }

  Future<void> playFile(EnteFile file, String localPath) async {
    if (!isSupported) {
      _logger.warning('AirPlay is not supported on this platform');
      return;
    }

    try {
      final fileType = file.fileType;
      _logger.info('Playing file via AirPlay: $localPath, type: $fileType');

      // For videos and live photos, we can directly play them
      // For images, we might need additional handling
      // The FlutterAVPlayerView will handle the actual playback
    } catch (e, s) {
      _logger.severe('Failed to play file via AirPlay', e, s);
      rethrow;
    }
  }

  Widget buildPlayerView({
    String? filePath,
    String? urlString,
    bool autoPlay = false,
  }) {
    if (!isSupported) {
      return const Center(
        child: Text('AirPlay is not supported on this platform'),
      );
    }

    return FlutterAVPlayerView(
      filePath: filePath,
      urlString: urlString,
    );
  }
}
