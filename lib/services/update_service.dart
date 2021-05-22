import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:photos/core/network.dart';

class UpdateService {
  UpdateService._privateConstructor();
  static final UpdateService instance = UpdateService._privateConstructor();

  LatestVersionInfo _latestVersion;

  Future<bool> shouldUpdate() async {
    if (Platform.isIOS) {
      return false;
    }
    _latestVersion = await _getLatestVersionInfo();
    final currentVersionCode =
        int.parse((await PackageInfo.fromPlatform()).buildNumber);
    return currentVersionCode < _latestVersion.code;
  }

  LatestVersionInfo getLatestVersionInfo() {
    return _latestVersion;
  }

  Future<LatestVersionInfo> _getLatestVersionInfo() async {
    final response = await Network.instance
        .getDio()
        .get("https://android.ente.io/release-info.json");
    return LatestVersionInfo.fromMap(response.data["latestVersion"]);
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
