// @dart=2.9

import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/core/network.dart';
import 'package:ente_auth/events/user_details_changed_event.dart';
import 'package:ente_auth/models/delete_account.dart';
import 'package:ente_auth/models/key_attributes.dart';
import 'package:ente_auth/models/key_gen_result.dart';
import 'package:ente_auth/models/sessions.dart';
import 'package:ente_auth/models/set_keys_request.dart';
import 'package:ente_auth/models/set_recovery_key_request.dart';
import 'package:ente_auth/models/user_details.dart';
import 'package:ente_auth/ui/account/login_page.dart';
import 'package:ente_auth/ui/account/ott_verification_page.dart';
import 'package:ente_auth/ui/account/password_entry_page.dart';
import 'package:ente_auth/ui/account/password_reentry_page.dart';
import 'package:ente_auth/ui/two_factor_authentication_page.dart';
import 'package:ente_auth/ui/two_factor_recovery_page.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class UserService {
  final _dio = Network.instance.getDio();
  final _logger = Logger("UserSerivce");
  final _config = Configuration.instance;
  ValueNotifier<String> emailValueNotifier;

  UserService._privateConstructor();
  static final UserService instance = UserService._privateConstructor();

  Future<void> init() async {
    emailValueNotifier =
        ValueNotifier<String>(Configuration.instance.getEmail());
  }

  Future<void> sendOtt(
    BuildContext context,
    String email, {
    bool isChangeEmail = false,
    bool isCreateAccountScreen = false,
  }) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/ott",
        data: {
          "email": email,
          "purpose": isChangeEmail ? "change" : "",
          "client": "totp"
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
                isCreateAccountScreen: isCreateAccountScreen,
              );
            },
          ),
        );
        return;
      }
      showGenericErrorDialog(context);
    } on DioError catch (e) {
      await dialog.hide();
      _logger.info(e);
      if (e.response != null && e.response.statusCode == 403) {
        showErrorDialog(context, "Oops", "This email is already in use");
      } else {
        showGenericErrorDialog(context);
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showGenericErrorDialog(context);
    }
  }

  Future<UserDetails> getUserDetailsV2({bool memoryCount = true}) async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() +
            "/users/details/v2?memoryCount=$memoryCount",
        queryParameters: {
          "memoryCount": memoryCount,
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      return UserDetails.fromMap(response.data);
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<Sessions> getActiveSessions() async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/sessions",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      return Sessions.fromMap(response.data);
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<void> terminateSession(String token) async {
    try {
      await _dio.delete(
        _config.getHttpEndpoint() + "/users/session",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
        queryParameters: {
          "token": token,
        },
      );
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<void> leaveFamilyPlan() async {
    try {
      await _dio.delete(
        _config.getHttpEndpoint() + "/family/leave",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
    } on DioError catch (e) {
      _logger.warning('failed to leave family plan', e);
      rethrow;
    }
  }

  Future<void> logout(BuildContext context) async {
    final dialog = createProgressDialog(context, "Logging out...");
    await dialog.show();
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/logout",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      if (response != null && response.statusCode == 200) {
        await Configuration.instance.logout();
        await dialog.hide();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception("Log out action failed");
      }
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  Future<DeleteChallengeResponse> getDeleteChallenge(
    BuildContext context,
  ) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/delete-challenge",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      if (response != null && response.statusCode == 200) {
        // clear data
        await dialog.hide();
        return DeleteChallengeResponse(
          allowDelete: response.data["allowDelete"] as bool,
          encryptedChallenge: response.data["encryptedChallenge"],
        );
      } else {
        throw Exception("delete action failed");
      }
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      await showGenericErrorDialog(context);
      return null;
    }
  }

  Future<void> deleteAccount(
    BuildContext context,
    String challengeResponse,
  ) async {
    final dialog = createProgressDialog(context, "Deleting account...");
    await dialog.show();
    try {
      final response = await _dio.delete(
        _config.getHttpEndpoint() + "/users/delete",
        data: {
          "challenge": challengeResponse,
        },
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      if (response != null && response.statusCode == 200) {
        // clear data
        await Configuration.instance.logout();
        await dialog.hide();
        showToast(
          context,
          "We have deleted your account and scheduled your uploaded data "
          "for deletion.",
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception("delete action failed");
      }
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  Future<void> verifyEmail(BuildContext context, String ott) async {
    final dialog = createProgressDialog(context, "Please wait...");
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
        Widget page;
        final String twoFASessionID = response.data["twoFactorSessionID"];
        if (twoFASessionID != null && twoFASessionID.isNotEmpty) {
          page = TwoFactorAuthenticationPage(twoFASessionID);
        } else {
          await _saveConfiguration(response);
          if (Configuration.instance.getEncryptedToken() != null) {
            page = const PasswordReentryPage();
          } else {
            page = const PasswordEntryPage();
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
        // should never reach here
        throw Exception("unexpected response during email verification");
      }
    } on DioError catch (e) {
      _logger.info(e);
      await dialog.hide();
      if (e.response != null && e.response.statusCode == 410) {
        await showErrorDialog(
          context,
          "Oops",
          "Your verification code has expired",
        );
        Navigator.of(context).pop();
      } else {
        showErrorDialog(
          context,
          "Incorrect code",
          "Sorry, the code you've entered is incorrect",
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showErrorDialog(context, "Oops", "Verification failed, please try again");
    }
  }

  Future<void> setEmail(String email) async {
    await _config.setEmail(email);
    emailValueNotifier.value = email ?? "";
  }

  Future<void> changeEmail(
    BuildContext context,
    String email,
    String ott,
  ) async {
    final dialog = createProgressDialog(context, "Please wait...");
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
        showToast(context, "Email changed to " + email);
        await setEmail(email);
        Navigator.of(context).popUntil((route) => route.isFirst);
        Bus.instance.fire(UserDetailsChangedEvent());
        return;
      }
      showErrorDialog(context, "Oops", "Verification failed, please try again");
    } on DioError catch (e) {
      await dialog.hide();
      if (e.response != null && e.response.statusCode == 403) {
        showErrorDialog(context, "Oops", "This email is already in use");
      } else {
        showErrorDialog(
          context,
          "Incorrect code",
          "Authentication failed, please try again",
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showErrorDialog(context, "Oops", "Verification failed, please try again");
    }
  }

  Future<void> setAttributes(KeyGenResult result) async {
    try {
      await _dio.put(
        _config.getHttpEndpoint() + "/users/attributes",
        data: {
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

  Future<String> getPaymentToken() async {
    try {
      final response = await _dio.get(
        "${_config.getHttpEndpoint()}/users/payment-token",
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
    } catch (e) {
      _logger.severe("Failed to get payment token", e);
      return null;
    }
  }

  Future<String> getFamiliesToken() async {
    try {
      final response = await _dio.get(
        "${_config.getHttpEndpoint()}/users/families-token",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      if (response != null && response.statusCode == 200) {
        return response.data["familiesToken"];
      } else {
        throw Exception("non 200 ok response");
      }
    } catch (e, s) {
      _logger.severe("failed to fetch families token", e, s);
      rethrow;
    }
  }

  Future<void> _saveConfiguration(Response response) async {
    await Configuration.instance.setUserID(response.data["id"]);
    if (response.data["encryptedToken"] != null) {
      await Configuration.instance
          .setEncryptedToken(response.data["encryptedToken"]);
      await Configuration.instance.setKeyAttributes(
        KeyAttributes.fromMap(response.data["keyAttributes"]),
      );
    } else {
      await Configuration.instance.setToken(response.data["token"]);
    }
  }

  Future<void> recoverTwoFactor(BuildContext context, String sessionID) async {
    final dialog = createProgressDialog(context, "Please wait...");
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
                response.data["secretDecryptionNonce"],
              );
            },
          ),
          (route) => route.isFirst,
        );
      }
    } on DioError catch (e) {
      _logger.severe(e);
      if (e.response != null && e.response.statusCode == 404) {
        showToast(context, "Session expired");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        showErrorDialog(
          context,
          "Oops",
          "Something went wrong, please try again",
        );
      }
    } catch (e) {
      _logger.severe(e);
      showErrorDialog(
        context,
        "Oops",
        "Something went wrong, please try again",
      );
    } finally {
      await dialog.hide();
    }
  }

  Future<void> verifyTwoFactor(
    BuildContext context,
    String sessionID,
    String code,
  ) async {
    final dialog = createProgressDialog(context, "Authenticating...");
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
        showToast(context, "Authentication successful!");
        await _saveConfiguration(response);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const PasswordReentryPage();
            },
          ),
          (route) => route.isFirst,
        );
      }
    } on DioError catch (e) {
      await dialog.hide();
      _logger.severe(e);
      if (e.response != null && e.response.statusCode == 404) {
        showToast(context, "Session expired");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        showErrorDialog(
          context,
          "Incorrect code",
          "Authentication failed, please try again",
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      showErrorDialog(
        context,
        "Oops",
        "Authentication failed, please try again",
      );
    }
  }

  Future<void> removeTwoFactor(
    BuildContext context,
    String sessionID,
    String recoveryKey,
    String encryptedSecret,
    String secretDecryptionNonce,
  ) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    String secret;
    try {
      if (recoveryKey.contains(' ')) {
        if (recoveryKey.split(' ').length != mnemonicKeyWordCount) {
          throw AssertionError(
            'recovery code should have $mnemonicKeyWordCount words',
          );
        }
        recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
      }
      secret = base64Encode(
        await CryptoUtil.decrypt(
          base64.decode(encryptedSecret),
          hex.decode(recoveryKey.trim()),
          base64.decode(secretDecryptionNonce),
        ),
      );
    } catch (e) {
      await dialog.hide();
      showErrorDialog(
        context,
        "Incorrect recovery key",
        "The recovery key you entered is incorrect",
      );
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
        showShortToast(context, "Two-factor authentication successfully reset");
        await _saveConfiguration(response);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const PasswordReentryPage();
            },
          ),
          (route) => route.isFirst,
        );
      }
    } on DioError catch (e) {
      _logger.severe(e);
      if (e.response != null && e.response.statusCode == 404) {
        showToast(context, "Session expired");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        showErrorDialog(
          context,
          "Oops",
          "Something went wrong, please try again",
        );
      }
    } catch (e) {
      _logger.severe(e);
      showErrorDialog(
        context,
        "Oops",
        "Something went wrong, please try again",
      );
    } finally {
      await dialog.hide();
    }
  }
}
