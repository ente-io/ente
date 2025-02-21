import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/endpoint_updated_event.dart';
import 'package:ente_auth/utils/package_info_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/foundation.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:uuid/uuid.dart';

int kConnectTimeout = 15000;

class Network {
  late Dio _dio;
  late Dio _enteDio;

  Future<void> init() async {
    if (PlatformUtil.isMobile()) await FkUserAgent.init();
    final packageInfo = await PackageInfoUtil().getPackageInfo();
    final version = PackageInfoUtil().getVersion(packageInfo);
    final packageName = PackageInfoUtil().getPackageName(packageInfo);
    final endpoint = Configuration.instance.getHttpEndpoint();

    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: kConnectTimeout),
        headers: {
          HttpHeaders.userAgentHeader: PlatformUtil.isMobile()
              ? FkUserAgent.userAgent
              : Platform.operatingSystem,
          'X-Client-Version': version,
          'X-Client-Package': packageName,
        },
      ),
    );

    _enteDio = Dio(
      BaseOptions(
        baseUrl: endpoint,
        connectTimeout: Duration(milliseconds: kConnectTimeout),
        headers: {
          if (PlatformUtil.isMobile())
            HttpHeaders.userAgentHeader: FkUserAgent.userAgent
          else
            HttpHeaders.userAgentHeader: Platform.operatingSystem,
          'X-Client-Version': version,
          'X-Client-Package': packageName,
        },
      ),
    );

    _dio.httpClientAdapter = NativeAdapter();
    _enteDio.httpClientAdapter = NativeAdapter();

    _setupInterceptors(endpoint);

    Bus.instance.on<EndpointUpdatedEvent>().listen((event) {
      final endpoint = Configuration.instance.getHttpEndpoint();
      _enteDio.options.baseUrl = endpoint;
      _setupInterceptors(endpoint);
    });
  }

  Network._privateConstructor();

  static Network instance = Network._privateConstructor();

  Dio getDio() => _dio;
  Dio get enteDio => _enteDio;

  void _setupInterceptors(String endpoint) {
    _dio.interceptors.clear();
    _dio.interceptors.add(RequestIdInterceptor());

    _enteDio.interceptors.clear();
    _enteDio.interceptors.add(EnteRequestInterceptor(endpoint));
  }
}

class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers
        .putIfAbsent("x-request-id", () => const Uuid().v4().toString());
    return super.onRequest(options, handler);
  }
}

class EnteRequestInterceptor extends Interceptor {
  final String endpoint;

  EnteRequestInterceptor(this.endpoint);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      assert(
        options.baseUrl == endpoint,
        "interceptor should only be used for API endpoint",
      );
    }
    options.headers
        .putIfAbsent("x-request-id", () => const Uuid().v4().toString());
    final String? tokenValue = Configuration.instance.getToken();
    if (tokenValue != null) {
      options.headers.putIfAbsent("X-Auth-Token", () => tokenValue);
    }
    return super.onRequest(options, handler);
  }
}
