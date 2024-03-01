import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/network/ente_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

int kConnectTimeout = 15000;

class NetworkClient {
  // apiEndpoint points to the Ente server's API endpoint
  static const apiEndpoint = String.fromEnvironment(
    "endpoint",
    defaultValue: kDefaultProductionEndpoint,
  );

  late Dio _dio;
  late Dio _enteDio;

  Future<void> init() async {
    await FkUserAgent.init();
    final packageInfo = await PackageInfo.fromPlatform();
    final preferences = await SharedPreferences.getInstance();
    _dio = Dio(
      BaseOptions(
        connectTimeout: kConnectTimeout,
        headers: {
          HttpHeaders.userAgentHeader: FkUserAgent.userAgent,
          'X-Client-Version': packageInfo.version,
          'X-Client-Package': packageInfo.packageName,
        },
      ),
    );
    _enteDio = Dio(
      BaseOptions(
        baseUrl: apiEndpoint,
        connectTimeout: kConnectTimeout,
        headers: {
          HttpHeaders.userAgentHeader: FkUserAgent.userAgent,
          'X-Client-Version': packageInfo.version,
          'X-Client-Package': packageInfo.packageName,
        },
      ),
    );
    _enteDio.interceptors.add(EnteRequestInterceptor(preferences, apiEndpoint));
  }

  NetworkClient._privateConstructor();

  static NetworkClient instance = NetworkClient._privateConstructor();

  Dio getDio() => _dio;

  Dio get enteDio => _enteDio;
}
