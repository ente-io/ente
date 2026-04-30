import "dart:async";
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import 'package:photos/core/network/ente_interceptor.dart';
import "package:photos/events/endpoint_updated_event.dart";
import "package:ua_client_hints/ua_client_hints.dart";

class NetworkClient {
  final _logger = Logger("NetworkClient");
  final _http2FallbackPolicy = _Http2FallbackPolicy();
  late Dio _dio;
  late Dio _enteDio;
  StreamSubscription<EndpointUpdatedEvent>? _endpointUpdatedSubscription;
  static const kConnectTimeout = 15;
  static const _connectTimeout = Duration(seconds: kConnectTimeout);

  Future<void> init(PackageInfo packageInfo) async {
    final String ua = await userAgent();
    final endpoint = Configuration.instance.getHttpEndpoint();
    _dio = Dio(
      BaseOptions(
        connectTimeout: _connectTimeout,
        headers: {
          HttpHeaders.userAgentHeader: ua,
          'X-Client-Version': packageInfo.version,
          'X-Client-Package': packageInfo.packageName,
        },
      ),
    );
    _enteDio = Dio(
      BaseOptions(
        baseUrl: endpoint,
        connectTimeout: _connectTimeout,
        headers: {
          HttpHeaders.userAgentHeader: ua,
          'X-Client-Version': packageInfo.version,
          'X-Client-Package': packageInfo.packageName,
        },
      ),
    );

    _dio.httpClientAdapter = _newAdaptiveHttpClientAdapter(_connectTimeout);
    _enteDio.httpClientAdapter = _newAdaptiveHttpClientAdapter(_connectTimeout);

    _setupInterceptors(endpoint);

    if (_endpointUpdatedSubscription != null) {
      await _endpointUpdatedSubscription!.cancel();
    }
    _endpointUpdatedSubscription =
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

  HttpClientAdapter _newAdaptiveHttpClientAdapter(Duration connectTimeout) {
    final fallbackAdapter = IOHttpClientAdapter();
    final fallbackPolicy = _http2FallbackPolicy;
    final http2Adapter = Http2Adapter(
      ConnectionManager(
        handshakeTimout: connectTimeout,
      ),
      fallbackAdapter: fallbackAdapter,
      onNotSupported: (options, requestStream, cancelFuture, exception) {
        _logHttp2UnsupportedOriginOnce(
          logger: _logger,
          fallbackPolicy: fallbackPolicy,
          uri: exception.uri,
          reason: "HTTP/2 not supported for ${options.method}",
        );
        return fallbackAdapter.fetch(options, requestStream, cancelFuture);
      },
    );
    return _AdaptiveHttpClientAdapter(
      http2Adapter: http2Adapter,
      fallbackAdapter: fallbackAdapter,
      logger: _logger,
      fallbackPolicy: fallbackPolicy,
    );
  }

  NetworkClient._privateConstructor();

  static NetworkClient instance = NetworkClient._privateConstructor();

  Dio getDio() => _dio;

  Dio get enteDio => _enteDio;
}

class _AdaptiveHttpClientAdapter implements HttpClientAdapter {
  _AdaptiveHttpClientAdapter({
    required HttpClientAdapter http2Adapter,
    required HttpClientAdapter fallbackAdapter,
    required Logger logger,
    required _Http2FallbackPolicy fallbackPolicy,
  })  : _http2Adapter = http2Adapter,
        _fallbackAdapter = fallbackAdapter,
        _logger = logger,
        _fallbackPolicy = fallbackPolicy;

  final HttpClientAdapter _http2Adapter;
  final HttpClientAdapter _fallbackAdapter;
  final Logger _logger;
  final _Http2FallbackPolicy _fallbackPolicy;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.scheme != "https") {
      return _fallbackAdapter.fetch(options, requestStream, cancelFuture);
    }
    if (_fallbackPolicy.isUnsupported(options.uri)) {
      return _fallbackAdapter.fetch(options, requestStream, cancelFuture);
    }
    // Keep explicit body send-timeout behavior on Dio's IO adapter. The app
    // does not set this globally, but per-request timeouts should not inherit
    // dio_http2_adapter's stream-close behavior after a timed-out body stream.
    if (_hasRequestBodySendTimeout(options, requestStream)) {
      return _fallbackAdapter.fetch(options, requestStream, cancelFuture);
    }
    // Keep cancellable body streams on Dio's IO adapter. dio_http2_adapter closes
    // the HTTP/2 outgoing stream on cancellation, which can race with active file
    // streams and surface stream-close errors instead of a clean Dio cancellation.
    if (_hasCancellableRequestBody(requestStream, cancelFuture)) {
      return _fallbackAdapter.fetch(options, requestStream, cancelFuture);
    }

    try {
      return await _http2Adapter.fetch(options, requestStream, cancelFuture);
    } catch (e, s) {
      if (e is TimeoutException) {
        throw DioException.connectionTimeout(
          requestOptions: options,
          timeout: options.connectTimeout ?? Duration.zero,
          error: e,
        );
      }
      if (_isFallbackHandshakeError(e)) {
        _logHttp2UnsupportedOriginOnce(
          logger: _logger,
          fallbackPolicy: _fallbackPolicy,
          uri: options.uri,
          reason: "HTTP/2 TLS negotiation failed for ${options.method}",
        );
        return _fallbackAdapter.fetch(options, requestStream, cancelFuture);
      }
      Error.throwWithStackTrace(e, s);
    }
  }

  @override
  void close({bool force = false}) {
    _http2Adapter.close(force: force);
    _fallbackAdapter.close(force: force);
  }

  bool _isFallbackHandshakeError(Object e) {
    if (e is HandshakeException) {
      return _isNoApplicationProtocolError(e);
    }
    if (e is DioException && e.error is HandshakeException) {
      return _isNoApplicationProtocolError(e.error! as HandshakeException);
    }
    return false;
  }

  bool _isNoApplicationProtocolError(HandshakeException e) {
    final message = "${e.message} $e".toLowerCase();
    return message.contains("no_application_protocol") ||
        message.contains("no application protocol");
  }

  bool _hasRequestBodySendTimeout(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  ) {
    final sendTimeout = options.sendTimeout ?? Duration.zero;
    return requestStream != null && sendTimeout > Duration.zero;
  }

  bool _hasCancellableRequestBody(
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return requestStream != null && cancelFuture != null;
  }
}

class _Http2FallbackPolicy {
  final _unsupportedOriginKeys = <String>{};

  bool isUnsupported(Uri uri) {
    return _unsupportedOriginKeys.contains(_originKey(uri));
  }

  bool markUnsupported(Uri uri) {
    return _unsupportedOriginKeys.add(_originKey(uri));
  }

  String originForLog(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final port =
        uri.hasPort && !_isDefaultPort(scheme, uri.port) ? ":${uri.port}" : "";
    return "$scheme://${_formatHost(uri.host)}$port";
  }

  String _originKey(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return "$scheme://${uri.host.toLowerCase()}:${_effectivePort(uri, scheme)}";
  }

  int _effectivePort(Uri uri, String scheme) {
    if (uri.hasPort) {
      return uri.port;
    }
    if (scheme == "https") {
      return 443;
    }
    if (scheme == "http") {
      return 80;
    }
    return uri.port;
  }

  bool _isDefaultPort(String scheme, int port) {
    return (scheme == "https" && port == 443) ||
        (scheme == "http" && port == 80);
  }

  String _formatHost(String host) {
    return host.contains(":") ? "[$host]" : host;
  }
}

void _logHttp2UnsupportedOriginOnce({
  required Logger logger,
  required _Http2FallbackPolicy fallbackPolicy,
  required Uri uri,
  required String reason,
}) {
  if (fallbackPolicy.markUnsupported(uri)) {
    logger.info(
      "$reason ${fallbackPolicy.originForLog(uri)}; "
      "using IO adapter for this app session",
    );
  }
}
