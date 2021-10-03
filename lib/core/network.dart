import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:package_info_plus/package_info_plus.dart';

int kConnectTimeout = 15000;

class Network {
  Dio _dio;

  Future<void> init() async {
    await FkUserAgent.init();
    final packageInfo = await PackageInfo.fromPlatform();
    _dio = Dio(BaseOptions(connectTimeout: kConnectTimeout, headers: {
      HttpHeaders.userAgentHeader: FkUserAgent.userAgent,
      'X-Client-Version': packageInfo.version,
      'X-Client-Package': packageInfo.packageName,
    }));
  }

  Network._privateConstructor();

  static Network instance = Network._privateConstructor();

  Dio getDio() => _dio;
}
