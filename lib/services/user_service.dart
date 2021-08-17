import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/public_keys_db.dart';
import 'package:photos/events/email_changed_event.dart';
import 'package:photos/events/two_factor_status_change_event.dart';
import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/key_gen_result.dart';
import 'package:photos/models/public_key.dart';
import 'package:photos/models/set_keys_request.dart';
import 'package:photos/models/set_recovery_key_request.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/ui/login_page.dart';
import 'package:photos/ui/ott_verification_page.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/password_reentry_page.dart';
import 'package:photos/ui/two_factor_authentication_page.dart';
import 'package:photos/ui/two_factor_recovery_page.dart';
import 'package:photos/ui/two_factor_setup_page.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class UserService {
  final _dio = Network.instance.getDio();
  final _logger = Logger("UserAuthenticator");
  final _config = Configuration.instance;

  UserService._privateConstructor();

  static final UserService instance = UserService._privateConstructor();

  Future<void> getOtt(
    BuildContext context,
    String email, {
    bool isChangeEmail = false,
  }) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/ott",
        queryParameters: {
          "email": email,
          "purpose": isChangeEmail ? "change" : ""
        },
      );
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return OTTVerificationPage(
                email,
                isChangeEmail: isChangeEmail,
              );
            },
          ),
        );
        return;
      }
      showGenericErrorDialog(context);
    } on DioError catch (e) {
      await dialog.hide();
      if (e.response != null && e.response.statusCode == 403) {
        showErrorDialog(context, AppLocalizations.of(context).oops,
            AppLocalizations.of(context).email_already_claimed);
      } else {
        showGenericErrorDialog(context);
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showGenericErrorDialog(context);
    }
  }

  Future<String> getPublicKey(String email) async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/public-key",
        queryParameters: {"email": email},
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
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

  Future<UserDetails> getUserDetails() async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/details",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      return UserDetails.fromMap(response.data["details"]);
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<void> logout(BuildContext context) async {
    final dialog = createProgressDialog(context, "logging out...");
    await dialog.show();
    try {
      final response =
          await _dio.post(_config.getHttpEndpoint() + "/users/logout",
              options: Options(
                headers: {
                  "X-Auth-Token": _config.getToken(),
                },
              ));
      if (response != null && response.statusCode == 200) {
        await Configuration.instance.logout();
        await dialog.hide();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception("log out action failed");
      }
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  Future<void> verifyEmail(BuildContext context, String ott) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/verify-email",
        data: {
          "email": _config.getEmail(),
          "ott": ott,
        },
      );
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        showToast("email verification successful!");
        Widget page;
        final String twoFASessionID = response.data["twoFactorSessionID"];
        if (twoFASessionID != null && twoFASessionID.isNotEmpty) {
          page = TwoFactorAuthenticationPage(twoFASessionID);
        } else {
          await _saveConfiguration(response);
          if (Configuration.instance.getEncryptedToken() != null) {
            page = PasswordReentryPage();
          } else {
            page = PasswordEntryPage();
          }
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
        showErrorDialog(context, AppLocalizations.of(context).oops,
            "verification failed, please try again");
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showErrorDialog(context, AppLocalizations.of(context).oops,
          "verification failed, please try again");
    }
  }

  Future<void> changeEmail(
    BuildContext context,
    String email,
    String ott,
  ) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/change-email",
        data: {
          "email": email,
          "ott": ott,
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        showToast("email changed to " + email);
        _config.setEmail(email);
        Navigator.of(context).popUntil((route) => route.isFirst);
        Bus.instance.fire(EmailChangedEvent());
        return;
      }
      showErrorDialog(context, AppLocalizations.of(context).oops,
          "verification failed, please try again");
    } on DioError catch (e) {
      await dialog.hide();
      if (e.response != null && e.response.statusCode == 403) {
        showErrorDialog(context, AppLocalizations.of(context).oops,
            AppLocalizations.of(context).email_already_claimed);
      } else {
        showErrorDialog(context, "incorrect code",
            "authentication failed, please try again");
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showErrorDialog(context, AppLocalizations.of(context).oops,
          "verification failed, please try again");
    }
  }

  Future<void> setAttributes(KeyGenResult result) async {
    try {
      final name = _config.getName();
      await _dio.put(
        _config.getHttpEndpoint() + "/users/attributes",
        data: {
          "name": name,
          "keyAttributes": result.keyAttributes.toMap(),
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      await _config.setKey(result.privateKeyAttributes.key);
      await _config.setSecretKey(result.privateKeyAttributes.secretKey);
      await _config.setKeyAttributes(result.keyAttributes);
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  Future<void> updateKeyAttributes(KeyAttributes keyAttributes) async {
    try {
      final setKeyRequest = SetKeysRequest(
        kekSalt: keyAttributes.kekSalt,
        encryptedKey: keyAttributes.encryptedKey,
        keyDecryptionNonce: keyAttributes.keyDecryptionNonce,
        memLimit: keyAttributes.memLimit,
        opsLimit: keyAttributes.opsLimit,
      );
      await _dio.put(
        _config.getHttpEndpoint() + "/users/keys",
        data: setKeyRequest.toMap(),
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      await _config.setKeyAttributes(keyAttributes);
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  Future<void> setRecoveryKey(KeyAttributes keyAttributes) async {
    try {
      final setRecoveryKeyRequest = SetRecoveryKeyRequest(
        keyAttributes.masterKeyEncryptedWithRecoveryKey,
        keyAttributes.masterKeyDecryptionNonce,
        keyAttributes.recoveryKeyEncryptedWithMasterKey,
        keyAttributes.recoveryKeyDecryptionNonce,
      );
      await _dio.put(
        _config.getHttpEndpoint() + "/users/recovery-key",
        data: setRecoveryKeyRequest.toMap(),
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      await _config.setKeyAttributes(keyAttributes);
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  Future<void> verifyTwoFactor(
      BuildContext context, String sessionID, String code) async {
    final dialog = createProgressDialog(context, "authenticating...");
    await dialog.show();
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/two-factor/verify",
        data: {
          "sessionID": sessionID,
          "code": code,
        },
      );
      await dialog.hide();
      if (response != null && response.statusCode == 200) {
        showToast("authentication successful!");
        await _saveConfiguration(response);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return PasswordReentryPage();
            },
          ),
          (route) => route.isFirst,
        );
      }
    } on DioError catch (e) {
      await dialog.hide();
      _logger.severe(e);
      if (e.response != null && e.response.statusCode == 404) {
        showToast("session expired");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        showErrorDialog(context, "incorrect code",
            "authentication failed, please try again");
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showErrorDialog(
          context, AppLocalizations.of(context).oops,
          "authentication failed, please try again");
    }
  }

  Future<void> recoverTwoFactor(BuildContext context, String sessionID) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/two-factor/recover",
        queryParameters: {
          "sessionID": sessionID,
        },
      );
      if (response != null && response.statusCode == 200) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return TwoFactorRecoveryPage(
                  sessionID,
                  response.data["encryptedSecret"],
                  response.data["secretDecryptionNonce"]);
            },
          ),
          (route) => route.isFirst,
        );
      }
    } on DioError catch (e) {
      _logger.severe(e);
      if (e.response != null && e.response.statusCode == 404) {
        showToast("session expired");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        showErrorDialog(
            context, AppLocalizations.of(context).oops,
            "something went wrong, please try again");
      }
    } catch (e) {
      _logger.severe(e);
      showErrorDialog(
          context, AppLocalizations.of(context).oops,
          "something went wrong, please try again");
    } finally {
      await dialog.hide();
    }
  }

  Future<void> removeTwoFactor(
    BuildContext context,
    String sessionID,
    String recoveryKey,
    String encryptedSecret,
    String secretDecryptionNonce,
  ) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    String secret;
    try {
      secret = Sodium.bin2base64(await CryptoUtil.decrypt(
          Sodium.base642bin(encryptedSecret),
          Sodium.hex2bin(recoveryKey.trim()),
          Sodium.base642bin(secretDecryptionNonce)));
    } catch (e) {
      await dialog.hide();
      showErrorDialog(context, "incorrect recovery key",
          "the recovery key you entered is incorrect");
      return;
    }
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/two-factor/remove",
        data: {
          "sessionID": sessionID,
          "secret": secret,
        },
      );
      if (response != null && response.statusCode == 200) {
        showToast("two-factor authentication successfully reset");
        await _saveConfiguration(response);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return PasswordReentryPage();
            },
          ),
          (route) => route.isFirst,
        );
      }
    } on DioError catch (e) {
      _logger.severe(e);
      if (e.response != null && e.response.statusCode == 404) {
        showToast("session expired");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        showErrorDialog(
            context, AppLocalizations.of(context).oops,
            "something went wrong, please try again");
      }
    } catch (e) {
      _logger.severe(e);
      showErrorDialog(
          context, AppLocalizations.of(context).oops,
          "something went wrong, please try again");
    } finally {
      await dialog.hide();
    }
  }

  Future<void> setupTwoFactor(BuildContext context) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/two-factor/setup",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      await dialog.hide();
      routeToPage(
          context,
          TwoFactorSetupPage(
              response.data["secretCode"], response.data["qrCode"]));
    } catch (e, s) {
      await dialog.hide();
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<bool> enableTwoFactor(
      BuildContext context, String secret, String code) async {
    Uint8List recoveryKey;
    try {
      recoveryKey = await getOrCreateRecoveryKey(context);
    } catch (e) {
      showGenericErrorDialog(context);
      return false;
    }
    final dialog = createProgressDialog(context, "verifying...");
    await dialog.show();
    final encryptionResult =
        CryptoUtil.encryptSync(Sodium.base642bin(secret), recoveryKey);
    try {
      await _dio.post(
        _config.getHttpEndpoint() + "/users/two-factor/enable",
        data: {
          "code": code,
          "encryptedTwoFactorSecret":
              Sodium.bin2base64(encryptionResult.encryptedData),
          "twoFactorSecretDecryptionNonce":
              Sodium.bin2base64(encryptionResult.nonce),
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      await dialog.hide();
      Navigator.pop(context);
      Bus.instance.fire(TwoFactorStatusChangeEvent(true));
      return true;
    } catch (e, s) {
      await dialog.hide();
      _logger.severe(e, s);
      if (e is DioError) {
        if (e.response != null && e.response.statusCode == 401) {
          showErrorDialog(context, "incorrect code",
              "please verify the code you have entered");
          return false;
        }
      }
      showErrorDialog(context, "something went wrong",
          "please contact support if the problem persists");
    }
    return false;
  }

  Future<void> disableTwoFactor(BuildContext context) async {
    final dialog =
        createProgressDialog(context, "disabling two-factor authentication...");
    await dialog.show();
    try {
      await _dio.post(
        _config.getHttpEndpoint() + "/users/two-factor/disable",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      Bus.instance.fire(TwoFactorStatusChangeEvent(false));
      await dialog.hide();
      showToast("two-factor authentication has been disabled");
    } catch (e, s) {
      await dialog.hide();
      _logger.severe(e, s);
      showErrorDialog(context, "something went wrong",
          "please contact support if the problem persists");
    }
  }

  Future<bool> fetchTwoFactorStatus() async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/two-factor/status",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      return response.data["status"];
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Uint8List> getOrCreateRecoveryKey(BuildContext context) async {
    final encryptedRecoveryKey =
        _config.getKeyAttributes().recoveryKeyEncryptedWithMasterKey;
    if (encryptedRecoveryKey == null || encryptedRecoveryKey.isEmpty) {
      final dialog = createProgressDialog(context, "please wait...");
      await dialog.show();
      try {
        final keyAttributes = await _config.createNewRecoveryKey();
        await setRecoveryKey(keyAttributes);
        await dialog.hide();
      } catch (e, s) {
        await dialog.hide();
        _logger.severe(e, s);
        rethrow;
      }
    }
    final recoveryKey = _config.getRecoveryKey();
    return recoveryKey;
  }

  Future<String> getPaymentToken() async {
    try {
      var response = await _dio.get(
        _config.getHttpEndpoint() + "/users/payment-token",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      if (response != null && response.statusCode == 200) {
        return response.data["paymentToken"];
      } else {
        throw Exception("non 200 ok response");
      }
    } catch (e, s) {
      _logger.severe(e, s);
      return null;
    }
  }

  Future<void> _saveConfiguration(Response response) async {
    await Configuration.instance.setUserID(response.data["id"]);
    if (response.data["encryptedToken"] != null) {
      await Configuration.instance
          .setEncryptedToken(response.data["encryptedToken"]);
      await Configuration.instance.setKeyAttributes(
          KeyAttributes.fromMap(response.data["keyAttributes"]));
    } else {
      await Configuration.instance.setToken(response.data["token"]);
    }
  }
}
