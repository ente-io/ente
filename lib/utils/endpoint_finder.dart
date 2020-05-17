import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

class EndpointFinder {
  final _dio = Dio();
  final logger = Logger("EndpointFinder");

  EndpointFinder._privateConstructor() {
    _dio.options = BaseOptions(connectTimeout: 200);
  }

  static final EndpointFinder instance = EndpointFinder._privateConstructor();

  bool _shouldContinueSearch;

  Future<String> findEndpoint() {
    _shouldContinueSearch = true;
    return (Connectivity().getWifiIP()).then((ip) async {
      logger.info(ip);
      final ipSplit = ip.split(".");
      var prefix = "";
      for (int index = 0; index < ipSplit.length; index++) {
        if (index != ipSplit.length - 1) {
          prefix += ipSplit[index] + ".";
        }
      }
      logger.info(prefix);

      for (int i = 1; i <= 255 && _shouldContinueSearch; i++) {
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
      if (_shouldContinueSearch) {
        throw TimeoutException("Could not find a valid endpoint");
      } else {
        // Exit gracefully
        return Future.value(null);
      }
    });
  }

  void cancelSearch() {
    _shouldContinueSearch = false;
  }

  Future<bool> ping(String endpoint) async {
    return _dio.get("http://" + endpoint + ":8080/ping").then((response) {
      if (response.data["message"] == "pong") {
        logger.info("Found " + endpoint);
        return true;
      } else {
        return false;
      }
    });
  }
}
