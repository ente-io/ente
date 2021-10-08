import 'dart:io';

import 'package:alice/alice.dart';
import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

int kConnectTimeout = 15000;

class Network {
  Dio _dio;
  Alice _alice;

  Future<void> init() async {
    _alice = Alice(darkTheme: true);
    await FkUserAgent.init();
    final packageInfo = await PackageInfo.fromPlatform();
    _dio = Dio(BaseOptions(connectTimeout: kConnectTimeout, headers: {
      HttpHeaders.userAgentHeader: FkUserAgent.userAgent,
      'X-Client-Version': packageInfo.version,
      'X-Client-Package': packageInfo.packageName,
    }));
    _dio.interceptors.add(_alice.getDioInterceptor());
  }

  Network._privateConstructor();

  static Network instance = Network._privateConstructor();

  Dio getDio() => _dio;
  Alice getAlice() => _alice;
}
