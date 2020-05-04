import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';

import 'package:photos/events/user_authenticated_event.dart';

class UserAuthenticator {
  final _dio = Dio();
  final _logger = Logger("UserAuthenticator");

  UserAuthenticator._privateConstructor();

  static final UserAuthenticator instance =
      UserAuthenticator._privateConstructor();

  Future<bool> login(String username, String password) {
    return _dio.post(
        "http://" + Configuration.instance.getEndpoint() + ":8080/users/login",
        queryParameters: {
          "username": username,
          "password": password
        }).then((response) {
      if (response.statusCode == 200 && response.data != null) {
        Configuration.instance.setUsername(username);
        Configuration.instance.setPassword(password);
        Configuration.instance.setToken(response.data["token"]);
        Bus.instance.fire(UserAuthenticatedEvent());
        return true;
      } else {
        return false;
      }
    }).catchError((e) {
      _logger.severe(e.toString());
      return false;
    });
  }

  Future<bool> create(String username, String password) {
    return _dio.post(
        "http://" + Configuration.instance.getEndpoint() + ":8080/users/create",
        queryParameters: {
          "username": username,
          "password": password
        }).then((response) {
      if (response.statusCode == 200 && response.data != null) {
        Configuration.instance.setUsername(username);
        Configuration.instance.setPassword(password);
        Configuration.instance.setToken(response.data["token"]);
        Bus.instance.fire(UserAuthenticatedEvent());
        return true;
      } else {
        if (response.data != null && response.data["message"] != null) {
          throw Exception(response.data["message"]);
        } else {
          throw Exception("Something went wrong");
        }
      }
    }).catchError((e) {
      _logger.severe(e.toString());
      throw e;
    });
  }
}
