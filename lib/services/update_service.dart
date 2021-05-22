import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photos/core/network.dart';

class UpdateService {
  UpdateService._privateConstructor();
  static final UpdateService instance = UpdateService._privateConstructor();

  final _logger = Logger("UpdateService");
  LatestVersionInfo _latestVersion;
  PackageInfo _packageInfo;

  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  Future<bool> shouldUpdate() async {
    _logger.info(_packageInfo.packageName);
    if (!isIndependent()) {
      return false;
    }
    try {
    _latestVersion = await _getLatestVersionInfo();
    final currentVersionCode = int.parse(_packageInfo.buildNumber);
    return currentVersionCode < _latestVersion.code;
    } catch (e) {
      _logger.severe(e);
      return false;
    }
  }

  LatestVersionInfo getLatestVersionInfo() {
    return _latestVersion;
  }

  Future<LatestVersionInfo> _getLatestVersionInfo() async {
    final response = await Network.instance
        .getDio()
        .get("https://static.ente.io/independent-release-info.json");
    return LatestVersionInfo.fromMap(response.data["latestVersion"]);
  }

  bool isIndependent() {
    if (Platform.isIOS) {
      return false;
    }
    if (!kDebugMode &&
        _packageInfo.packageName != "io.ente.photos.independent") {
      return false;
    }
    return true;
  }
}

class LatestVersionInfo {
  final String name;
  final int code;
  final List<String> changelog;
  final bool shouldForceUpdate;
  final String url;
  final int size;

  LatestVersionInfo(
    this.name,
    this.code,
    this.changelog,
    this.shouldForceUpdate,
    this.url,
    this.size,
  );

  factory LatestVersionInfo.fromMap(Map<String, dynamic> map) {
    return LatestVersionInfo(
      map['name'],
      map['code'],
      List<String>.from(map['changelog']),
      map['shouldForceUpdate'],
      map['url'],
      map['size'],
    );
  }
}
