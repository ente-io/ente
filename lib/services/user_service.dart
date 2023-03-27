import 'dart:async';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/public_keys_db.dart';
import 'package:photos/events/two_factor_status_change_event.dart';
import 'package:photos/events/user_details_changed_event.dart';
import 'package:photos/models/delete_account.dart';
import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/key_gen_result.dart';
import 'package:photos/models/public_key.dart';
import 'package:photos/models/sessions.dart';
import 'package:photos/models/set_keys_request.dart';
import 'package:photos/models/set_recovery_key_request.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/ui/account/login_page.dart';
import 'package:photos/ui/account/ott_verification_page.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/account/password_reentry_page.dart';
import 'package:photos/ui/account/two_factor_authentication_page.dart';
import 'package:photos/ui/account/two_factor_recovery_page.dart';
import 'package:photos/ui/account/two_factor_setup_page.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const keyHasEnabledTwoFactor = "has_enabled_two_factor";
  static const keyUserDetails = "user_details";
  final _dio = NetworkClient.instance.getDio();
  final _enteDio = NetworkClient.instance.enteDio;
  final _logger = Logger((UserService).toString());
  final _config = Configuration.instance;
  late SharedPreferences _preferences;

  late ValueNotifier<String?> emailValueNotifier;

  UserService._privateConstructor();

  static final UserService instance = UserService._privateConstructor();

  Future<void> init() async {
    emailValueNotifier =
        ValueNotifier<String?>(Configuration.instance.getEmail());
    _preferences = await SharedPreferences.getInstance();
    if (Configuration.instance.isLoggedIn()) {
      // add artificial delay in refreshing 2FA status
      Future.delayed(
        const Duration(seconds: 5),
        () => {setTwoFactor(fetchTwoFactorStatus: true).ignore()},
      );
    }
    Bus.instance.on<TwoFactorStatusChangeEvent>().listen((event) {
      setTwoFactor(value: event.status);
    });
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
        data: {"email": email, "purpose": isChangeEmail ? "change" : ""},
      );
      await dialog.hide();
      if (response.statusCode == 200) {
        unawaited(
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
          ),
        );
        return;
      }
      unawaited(showGenericErrorDialog(context: context));
    } on DioError catch (e) {
      await dialog.hide();
      _logger.info(e);
      if (e.response != null && e.response!.statusCode == 403) {
        unawaited(
          showErrorDialog(
            context,
            "Oops",
            "This email is already in use",
          ),
        );
      } else {
        unawaited(showGenericErrorDialog(context: context));
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      unawaited(showGenericErrorDialog(context: context));
    }
  }

  Future<void> sendFeedback(
    BuildContext context,
    String feedback, {
    String type = "SubCancellation",
  }) async {
    await _dio.post(
      _config.getHttpEndpoint() + "/anonymous/feedback",
      data: {"feedback": feedback, "type": "type"},
    );
  }

  // getPublicKey returns null value if email id is not
  // associated with another ente account
  Future<String?> getPublicKey(String email) async {
    try {
      final response = await _enteDio.get(
        "/users/public-key",
        queryParameters: {"email": email},
      );
      final publicKey = response.data["publicKey"];
      await PublicKeysDB.instance.setKey(PublicKey(email, publicKey));
      return publicKey;
    } on DioError catch (e) {
      if (e.response != null && e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  UserDetails? getCachedUserDetails() {
    if (_preferences.containsKey(keyUserDetails)) {
      return UserDetails.fromJson(_preferences.getString(keyUserDetails)!);
    }
    return null;
  }

  Future<UserDetails> getUserDetailsV2({
    bool memoryCount = true,
    bool shouldCache = false,
  }) async {
    _logger.info("Fetching user details");
    try {
      final response = await _enteDio.get(
        "/users/details/v2",
        queryParameters: {
          "memoryCount": memoryCount,
        },
      );
      final userDetails = UserDetails.fromMap(response.data);
      if (shouldCache) {
        await _preferences.setString(keyUserDetails, userDetails.toJson());
        // handle email change from different client
        if (userDetails.email != _config.getEmail()) {
          setEmail(userDetails.email);
        }
      }
      return userDetails;
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<Sessions> getActiveSessions() async {
    try {
      final response = await _enteDio.get("/users/sessions");
      return Sessions.fromMap(response.data);
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<void> terminateSession(String token) async {
    try {
      await _enteDio.delete(
        "/users/session",
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
      await _enteDio.delete("/family/leave");
    } on DioError catch (e) {
      _logger.warning('failed to leave family plan', e);
      rethrow;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final response = await _enteDio.post("/users/logout");
      if (response.statusCode == 200) {
        await Configuration.instance.logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception("Log out action failed");
      }
    } catch (e) {
      _logger.severe(e);
      //This future is for waiting for the dialog from which logout() is called
      //to close and only then to show the error dialog.
      Future.delayed(
        const Duration(milliseconds: 150),
        () => showGenericErrorDialog(context: context),
      );
      rethrow;
    }
  }

  Future<DeleteChallengeResponse?> getDeleteChallenge(
    BuildContext context,
  ) async {
    try {
      final response = await _enteDio.get("/users/delete-challenge");
      if (response.statusCode == 200) {
        return DeleteChallengeResponse(
          allowDelete: response.data["allowDelete"] as bool,
          encryptedChallenge: response.data["encryptedChallenge"],
        );
      } else {
        throw Exception("delete action failed");
      }
    } catch (e) {
      _logger.severe(e);
      await showGenericErrorDialog(context: context);
      return null;
    }
  }

  Future<void> deleteAccount(
    BuildContext context,
    String challengeResponse, {
    required String reasonCategory,
    required String feedback,
  }) async {
    try {
      final response = await _enteDio.delete(
        "/users/delete",
        data: {
          "challenge": challengeResponse,
          "reasonCategory": reasonCategory,
          "feedback": feedback,
        },
      );
      if (response.statusCode == 200) {
        // clear data
        await Configuration.instance.logout();
      } else {
        throw Exception("delete action failed");
      }
    } catch (e) {
      _logger.severe(e);
      rethrow;
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
      if (response.statusCode == 200) {
        Widget page;
        final String twoFASessionID = response.data["twoFactorSessionID"];
        if (twoFASessionID.isNotEmpty) {
          setTwoFactor(value: true);
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
      if (e.response != null && e.response!.statusCode == 410) {
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
    emailValueNotifier.value = email;
  }

  Future<void> changeEmail(
    BuildContext context,
    String email,
    String ott,
  ) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      final response = await _enteDio.post(
        "/users/change-email",
        data: {
          "email": email,
          "ott": ott,
        },
      );
      await dialog.hide();
      if (response.statusCode == 200) {
        showShortToast(context, "Email changed to " + email);
        await setEmail(email);
        Navigator.of(context).popUntil((route) => route.isFirst);
        Bus.instance.fire(UserDetailsChangedEvent());
        return;
      }
      showErrorDialog(context, "Oops", "Verification failed, please try again");
    } on DioError catch (e) {
      await dialog.hide();
      if (e.response != null && e.response!.statusCode == 403) {
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
      final name = _config.getName();
      await _enteDio.put(
        "/users/attributes",
        data: {
          "name": name,
          "keyAttributes": result.keyAttributes.toMap(),
        },
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
        memLimit: keyAttributes.memLimit!,
        opsLimit: keyAttributes.opsLimit!,
      );
      await _enteDio.put(
        "/users/keys",
        data: setKeyRequest.toMap(),
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
        keyAttributes.masterKeyEncryptedWithRecoveryKey!,
        keyAttributes.masterKeyDecryptionNonce!,
        keyAttributes.recoveryKeyEncryptedWithMasterKey!,
        keyAttributes.recoveryKeyDecryptionNonce!,
      );
      await _enteDio.put(
        "/users/recovery-key",
        data: setRecoveryKeyRequest.toMap(),
      );
      await _config.setKeyAttributes(keyAttributes);
    } catch (e) {
      _logger.severe(e);
      rethrow;
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
      if (response.statusCode == 200) {
        showShortToast(context, "Authentication successful!");
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
      if (e.response != null && e.response!.statusCode == 404) {
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
      if (response.statusCode == 200) {
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
      if (e.response != null && e.response!.statusCode == 404) {
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
      secret = CryptoUtil.bin2base64(
        await CryptoUtil.decrypt(
          CryptoUtil.base642bin(encryptedSecret),
          CryptoUtil.hex2bin(recoveryKey.trim()),
          CryptoUtil.base642bin(secretDecryptionNonce),
        ),
      );
    } catch (e) {
      await dialog.hide();
      await showErrorDialog(
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
      if (response.statusCode == 200) {
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
      if (e.response != null && e.response!.statusCode == 404) {
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

  Future<void> setupTwoFactor(BuildContext context, Completer completer) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      final response = await _enteDio.post("/users/two-factor/setup");
      await dialog.hide();
      unawaited(
        routeToPage(
          context,
          TwoFactorSetupPage(
            response.data["secretCode"],
            response.data["qrCode"],
            completer,
          ),
        ),
      );
    } catch (e) {
      await dialog.hide();
      _logger.severe("Failed to setup tfa", e);
      completer.complete();
      rethrow;
    }
  }

  Future<bool> enableTwoFactor(
    BuildContext context,
    String secret,
    String code,
  ) async {
    Uint8List recoveryKey;
    try {
      recoveryKey = await getOrCreateRecoveryKey(context);
    } catch (e) {
      showGenericErrorDialog(context: context);
      return false;
    }
    final dialog = createProgressDialog(context, "Verifying...");
    await dialog.show();
    final encryptionResult =
        CryptoUtil.encryptSync(CryptoUtil.base642bin(secret), recoveryKey);
    try {
      await _enteDio.post(
        "/users/two-factor/enable",
        data: {
          "code": code,
          "encryptedTwoFactorSecret":
              CryptoUtil.bin2base64(encryptionResult.encryptedData!),
          "twoFactorSecretDecryptionNonce":
              CryptoUtil.bin2base64(encryptionResult.nonce!),
        },
      );
      await dialog.hide();
      Navigator.pop(context);
      Bus.instance.fire(TwoFactorStatusChangeEvent(true));
      return true;
    } catch (e, s) {
      await dialog.hide();
      _logger.severe(e, s);
      if (e is DioError) {
        if (e.response != null && e.response!.statusCode == 401) {
          showErrorDialog(
            context,
            "Incorrect code",
            "Please verify the code you have entered",
          );
          return false;
        }
      }
      showErrorDialog(
        context,
        "Something went wrong",
        "Please contact support if the problem persists",
      );
    }
    return false;
  }

  Future<void> disableTwoFactor(BuildContext context) async {
    final dialog =
        createProgressDialog(context, "Disabling two-factor authentication...");
    await dialog.show();
    try {
      await _enteDio.post(
        "/users/two-factor/disable",
      );
      await dialog.hide();
      Bus.instance.fire(TwoFactorStatusChangeEvent(false));
      unawaited(
        showShortToast(
          context,
          "Two-factor authentication has been disabled",
        ),
      );
    } catch (e) {
      await dialog.hide();
      _logger.severe("Failed to disabled 2FA", e);
      await showErrorDialog(
        context,
        "Something went wrong",
        "Please contact support if the problem persists",
      );
    }
  }

  Future<bool> fetchTwoFactorStatus() async {
    try {
      final response = await _enteDio.get("/users/two-factor/status");
      setTwoFactor(value: response.data["status"]);
      return response.data["status"];
    } catch (e) {
      _logger.severe("Failed to fetch 2FA status", e);
      rethrow;
    }
  }

  Future<Uint8List> getOrCreateRecoveryKey(BuildContext context) async {
    final String? encryptedRecoveryKey =
        _config.getKeyAttributes()!.recoveryKeyEncryptedWithMasterKey;
    if (encryptedRecoveryKey == null || encryptedRecoveryKey.isEmpty) {
      final dialog = createProgressDialog(context, "Please wait...");
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

  Future<String?> getPaymentToken() async {
    try {
      final response = await _enteDio.get("/users/payment-token");
      if (response.statusCode == 200) {
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
      final response = await _enteDio.get("/users/families-token");
      if (response.statusCode == 200) {
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

  Future<void> setTwoFactor({
    bool value = false,
    bool fetchTwoFactorStatus = false,
  }) async {
    if (fetchTwoFactorStatus) {
      value = await UserService.instance.fetchTwoFactorStatus();
    }
    _preferences.setBool(keyHasEnabledTwoFactor, value);
  }

  bool hasEnabledTwoFactor() {
    return _preferences.getBool(keyHasEnabledTwoFactor) ?? false;
  }
}
