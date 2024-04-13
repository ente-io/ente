import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import 'package:photos/core/network/ente_interceptor.dart';
import "package:photos/events/endpoint_updated_event.dart";

int kConnectTimeout = 15000;

class NetworkClient {
  late Dio _dio;
  late Dio _enteDio;

  Future<void> init() async {
    await FkUserAgent.init();
    final packageInfo = await PackageInfo.fromPlatform();
    final endpoint = Configuration.instance.getHttpEndpoint();
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
        baseUrl: endpoint,
        connectTimeout: kConnectTimeout,
        headers: {
          HttpHeaders.userAgentHeader: FkUserAgent.userAgent,
          'X-Client-Version': packageInfo.version,
          'X-Client-Package': packageInfo.packageName,
        },
      ),
    );
    _setupInterceptors(endpoint);

    Bus.instance.on<EndpointUpdatedEvent>().listen((event) {
      final endpoint = Configuration.instance.getHttpEndpoint();
      _enteDio.options.baseUrl = endpoint;
      _setupInterceptors(endpoint);
    });
  }

  void _setupInterceptors(String endpoint) {
    _enteDio.interceptors.clear();
    _enteDio.interceptors.add(EnteRequestInterceptor(endpoint));
  }

  NetworkClient._privateConstructor();

  static NetworkClient instance = NetworkClient._privateConstructor();

  Dio getDio() => _dio;

  Dio get enteDio => _enteDio;
}
