import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';

class Network {
  Dio _dio;

  Future<void> init() async {
    await FlutterUserAgent.init();
    _dio = Dio(BaseOptions(
        headers: {HttpHeaders.userAgentHeader: FlutterUserAgent.userAgent}));
  }

  Network._privateConstructor();
  static Network instance = Network._privateConstructor();

  Dio getDio() => _dio;
}
