import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class EndpointFinder {
  final _dio = Dio();

  EndpointFinder._privateConstructor() {
    _dio.options = BaseOptions(connectTimeout: 200);
  }

  static final EndpointFinder instance = EndpointFinder._privateConstructor();

  Future<String> findEndpoint() {
    return (Connectivity().getWifiIP()).then((ip) async {
      Logger().i(ip);
      final ipSplit = ip.split(".");
      var prefix = "";
      for (int index = 0; index < ipSplit.length; index++) {
        if (index != ipSplit.length - 1) {
          prefix += ipSplit[index] + ".";
        }
      }
      Logger().i(prefix);

      for (int i = 1; i <= 255; i++) {
        var endpoint = prefix + i.toString();
        try {
          final success = await ping(endpoint);
          if (success) {
            return endpoint;
          }
        } catch (e) {
          // Do nothing
        }
      }
      throw TimeoutException("Could not find a valid endpoint");
    });
  }

  Future<bool> ping(String endpoint) async {
    return _dio.get("http://" + endpoint + ":8080/ping").then((response) {
      if (response.data["message"] == "pong") {
        Logger().i("Found " + endpoint);
        return true;
      } else {
        return false;
      }
    });
  }
}
