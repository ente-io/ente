import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/public_keys_db.dart';

import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/public_key.dart';
import 'package:photos/ui/ott_verification_page.dart';
import 'package:photos/ui/passphrase_entry_page.dart';
import 'package:photos/ui/passphrase_reentry_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

class UserService {
  final _dio = Dio();
  final _logger = Logger("UserAuthenticator");

  UserService._privateConstructor();

  static final UserService instance = UserService._privateConstructor();

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

  Future<String> getPublicKey(String email) async {
    try {
      final response = await _dio.get(
        Configuration.instance.getHttpEndpoint() + "/users/public-key",
        queryParameters: {"email": email},
        options: Options(
          headers: {
            "X-Auth-Token": Configuration.instance.getToken(),
          },
        ),
      );
      final publicKey = response.data["publicKey"];
      await PublicKeysDB.instance.setKey(PublicKey(email, publicKey));
      return publicKey;
    } on DioError catch (e) {
      _logger.info(e);
      return null;
    }
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
        await _saveConfiguration(response);
        showToast("Email verification successful!");
        var page;
        if (Configuration.instance.getKeyAttributes() != null) {
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

  Future<void> setupKey(BuildContext context, String passphrase) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    final keyAttributes =
        await Configuration.instance.generateAndSaveKey(passphrase);
    await _dio
        .put(
      Configuration.instance.getHttpEndpoint() + "/users/key-attributes",
      data: keyAttributes.toMap(),
      options: Options(
        headers: {
          "X-Auth-Token": Configuration.instance.getToken(),
        },
      ),
    )
        .catchError((e) async {
      await dialog.hide();
      await Configuration.instance.setKey(null);
      await Configuration.instance.setKeyAttributes(null);
      _logger.severe(e);
      showGenericErrorDialog(context);
    }).then((response) async {
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        Bus.instance.fire(UserAuthenticatedEvent());
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        await Configuration.instance.setKey(null);
        await Configuration.instance.setKeyAttributes(null);
        showGenericErrorDialog(context);
      }
    });
  }

  Future<void> _saveConfiguration(Response response) async {
    await Configuration.instance.setUserID(response.data["id"]);
    await Configuration.instance.setToken(response.data["token"]);
    final keyAttributes = response.data["keyAttributes"];
    if (keyAttributes != null) {
      await Configuration.instance
          .setKeyAttributes(KeyAttributes.fromMap(keyAttributes));
    }
  }
}
