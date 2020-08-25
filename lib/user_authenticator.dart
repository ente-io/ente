import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';

import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/ui/ott_verification_page.dart';
import 'package:photos/utils/dialog_util.dart';

class UserAuthenticator {
  final _dio = Dio();
  final _logger = Logger("UserAuthenticator");

  UserAuthenticator._privateConstructor();

  static final UserAuthenticator instance =
      UserAuthenticator._privateConstructor();

  Future<void> getOtt(BuildContext context, String email) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    await Dio().get(
      Configuration.instance.getHttpEndpoint() + "/users/ott",
      queryParameters: {
        "email": email,
      },
    ).catchError((e) async {
      _logger.severe(e);
      await dialog.hide();
      showGenericErrorDialog(context);
    }).then((response) async {
      await dialog.hide();
      if (response.statusCode == 200) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return OTTVerificationPage(email);
            },
          ),
        );
      } else {
        showGenericErrorDialog(context);
      }
    });
  }

  Future<void> getCredentials(
      BuildContext context, String email, String ott) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    await Dio().get(
      Configuration.instance.getHttpEndpoint() + "/users/credentials",
      queryParameters: {
        "email": email,
        "ott": ott,
      },
    ).catchError((e) async {
      _logger.severe(e);
      await dialog.hide();
      showGenericErrorDialog(context);
    }).then((response) async {
      await dialog.hide();
      if (response.statusCode == 200) {
        _saveConfiguration(email, response);
        Navigator.of(context).pop();
      } else {
        showErrorDialog(
            context, "Oops.", "Verification failed, please try again.");
      }
    });
  }

  Future<bool> login(String username, String password) {
    return _dio.post(
        Configuration.instance.getHttpEndpoint() + "/users/authenticate",
        data: {
          "username": username,
          "password": password,
        }).then((response) {
      if (response.statusCode == 200 && response.data != null) {
        _saveConfiguration(username, response);
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
    return _dio
        .post(Configuration.instance.getHttpEndpoint() + "/users", data: {
      "username": username,
      "password": password,
    }).then((response) {
      if (response.statusCode == 200 && response.data != null) {
        _saveConfiguration(username, response);
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

  Future<void> setEncryptedKeyOnServer() {
    return _dio.put(
      Configuration.instance.getHttpEndpoint() + "/users/encrypted-key",
      data: {
        "encryptedKey": Configuration.instance.getEncryptedKey(),
      },
      options: Options(headers: {
        "X-Auth-Token": Configuration.instance.getToken(),
      }),
    );
  }

  void _saveConfiguration(String email, Response response) {
    Configuration.instance.setEmail(email);
    Configuration.instance.setUserID(response.data["id"]);
    Configuration.instance.setToken(response.data["token"]);
    final String encryptedKey = response.data["encryptedKey"];
    if (encryptedKey != null && encryptedKey.isNotEmpty) {
      Configuration.instance.setEncryptedKey(encryptedKey);
    }
  }
}
