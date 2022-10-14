import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

int kConnectTimeout = 15000;

class Network {
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
    enteDio.interceptors.add(EnteRequestInterceptor(preferences));
  }

  Network._privateConstructor();

  static Network instance = Network._privateConstructor();

  Dio getDio() => _dio;

  Dio get enteDio => _enteDio;
}

class EnteRequestInterceptor extends Interceptor {
  final SharedPreferences preferences;

  EnteRequestInterceptor(this.preferences);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      assert(options.baseUrl == Network.apiEndpoint, "request should be");
    }
    // ignore: prefer_const_constructors
    options.headers.putIfAbsent("x-request-id", () => Uuid().v4().toString());
    final String? tokenValue = preferences.getString(Configuration.tokenKey);
    if (tokenValue != null) {
      options.headers.putIfAbsent("X-Auth-Token", () => tokenValue);
    }
    return super.onRequest(options, handler);
  }
}
