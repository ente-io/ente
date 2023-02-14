import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:photos/core/configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class EnteRequestInterceptor extends Interceptor {
  final SharedPreferences _preferences;
  final String enteEndpoint;

  EnteRequestInterceptor(this._preferences, this.enteEndpoint);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      assert(
        options.baseUrl == enteEndpoint,
        "interceptor should only be used for API endpoint",
      );
    }
    // ignore: prefer_const_constructors
    options.headers.putIfAbsent("x-request-id", () => Uuid().v4().toString());
    final String? tokenValue = _preferences.getString(Configuration.tokenKey);
    if (tokenValue != null) {
      options.headers.putIfAbsent("X-Auth-Token", () => tokenValue);
    }
    return super.onRequest(options, handler);
  }
}
