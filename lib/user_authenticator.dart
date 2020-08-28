import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';

import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/ui/ott_verification_page.dart';
import 'package:photos/ui/passphrase_entry_page.dart';
import 'package:photos/ui/passphrase_reentry_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

class UserAuthenticator {
  final _dio = Dio();
  final _logger = Logger("UserAuthenticator");

  UserAuthenticator._privateConstructor();

  static final UserAuthenticator instance =
      UserAuthenticator._privateConstructor();

  Future<void> getOtt(BuildContext context, String email) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    await _dio.get(
      Configuration.instance.getHttpEndpoint() + "/users/ott",
      queryParameters: {
        "email": email,
      },
    ).catchError((e) async {
      _logger.severe(e);
    }).then((response) async {
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return OTTVerificationPage();
            },
          ),
        );
      } else {
        showGenericErrorDialog(context);
      }
    });
  }

  Future<void> getCredentials(BuildContext context, String ott) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    await _dio.get(
      Configuration.instance.getHttpEndpoint() + "/users/credentials",
      queryParameters: {
        "email": Configuration.instance.getEmail(),
        "ott": ott,
      },
    ).catchError((e) async {
      _logger.severe(e);
    }).then((response) async {
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        _saveConfiguration(response);
        showToast("Email verification successful!");
        var page;
        if (Configuration.instance.getEncryptedKey() != null) {
          page = PassphraseReentryPage();
        } else {
          page = PassphraseEntryPage();
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return page;
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        showErrorDialog(
            context, "Oops.", "Verification failed, please try again.");
      }
    });
  }

  Future<void> setPassphrase(BuildContext context, String passphrase) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    await Configuration.instance.generateAndSaveKey(passphrase);
    await _dio
        .put(
      Configuration.instance.getHttpEndpoint() + "/users/encrypted-key",
      data: {
        "encryptedKey": Configuration.instance.getEncryptedKey(),
      },
      options: Options(
        headers: {
          "X-Auth-Token": Configuration.instance.getToken(),
        },
      ),
    )
        .catchError((e) async {
      await dialog.hide();
      Configuration.instance.setKey(null);
      Configuration.instance.setEncryptedKey(null);
      _logger.severe(e);
      showGenericErrorDialog(context);
    }).then((response) async {
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        Bus.instance.fire(UserAuthenticatedEvent());
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Configuration.instance.setKey(null);
        Configuration.instance.setEncryptedKey(null);
        showGenericErrorDialog(context);
      }
    });
  }

  @deprecated
  Future<bool> login(String username, String password) {
    return _dio.post(
        Configuration.instance.getHttpEndpoint() + "/users/authenticate",
        data: {
          "username": username,
          "password": password,
        }).then((response) {
      if (response.statusCode == 200 && response.data != null) {
        _saveConfiguration(response);
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

  @deprecated
  Future<bool> create(String username, String password) {
    return _dio
        .post(Configuration.instance.getHttpEndpoint() + "/users", data: {
      "username": username,
      "password": password,
    }).then((response) {
      if (response.statusCode == 200 && response.data != null) {
        _saveConfiguration(response);
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

  void _saveConfiguration(Response response) {
    Configuration.instance.setUserID(response.data["id"]);
    Configuration.instance.setToken(response.data["token"]);
    final String encryptedKey = response.data["encryptedKey"];
    if (encryptedKey != null && encryptedKey.isNotEmpty) {
      Configuration.instance.setEncryptedKey(encryptedKey);
    }
  }
}
