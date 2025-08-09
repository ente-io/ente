import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_events/models/endpoint_updated_event.dart';
import 'package:flutter/foundation.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ua_client_hints/ua_client_hints.dart';
import 'package:uuid/uuid.dart';

int kConnectTimeout = 15000;

class Network {
  late Dio _dio;
  late Dio _enteDio;

  Future<void> init(BaseConfiguration configuration) async {
    final String ua = await userAgent();
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final packageName = packageInfo.packageName;
    final endpoint = configuration.getHttpEndpoint();
    final isMobile = Platform.isAndroid || Platform.isIOS;

    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: kConnectTimeout),
        headers: {
          HttpHeaders.userAgentHeader: isMobile ? ua : Platform.operatingSystem,
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
          if (isMobile)
            HttpHeaders.userAgentHeader: ua
          else
            HttpHeaders.userAgentHeader: Platform.operatingSystem,
          'X-Client-Version': version,
          'X-Client-Package': packageName,
        },
      ),
    );

    _dio.httpClientAdapter = NativeAdapter();
    _enteDio.httpClientAdapter = NativeAdapter();

    _setupInterceptors(configuration);

    Bus.instance.on<EndpointUpdatedEvent>().listen((event) {
      final endpoint = configuration.getHttpEndpoint();
      _enteDio.options.baseUrl = endpoint;
      _setupInterceptors(configuration);
    });
  }

  Network._privateConstructor();

  static Network instance = Network._privateConstructor();

  Dio getDio() => _dio;
  Dio get enteDio => _enteDio;

  void _setupInterceptors(BaseConfiguration configuration) {
    _dio.interceptors.clear();
    _dio.interceptors.add(RequestIdInterceptor());

    _enteDio.interceptors.clear();
    _enteDio.interceptors.add(EnteRequestInterceptor(configuration));
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
  final BaseConfiguration configuration;

  EnteRequestInterceptor(this.configuration);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      assert(
        options.baseUrl == configuration.getHttpEndpoint(),
        "interceptor should only be used for API endpoint",
      );
    }
    options.headers
        .putIfAbsent("x-request-id", () => const Uuid().v4().toString());
    final String? tokenValue = configuration.getToken();
    if (tokenValue != null) {
      options.headers.putIfAbsent("X-Auth-Token", () => tokenValue);
    }
    return super.onRequest(options, handler);
  }
}
