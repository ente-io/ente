import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

int kConnectTimeout = 15000;

class Network {
  late Dio _dio;

  Future<void> init() async {
    await FkUserAgent.init();
    final packageInfo = await PackageInfo.fromPlatform();
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
    _dio.interceptors.add(RequestIdInterceptor());
  }

  Network._privateConstructor();

  static Network instance = Network._privateConstructor();

  Dio getDio() => _dio;
}

class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: prefer_const_constructors
    options.headers.putIfAbsent("x-request-id", () => Uuid().v4().toString());
    return super.onRequest(options, handler);
  }
}
