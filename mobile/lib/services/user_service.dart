import 'dart:async';
import "dart:convert";
import "dart:math";

import 'package:bip39/bip39.dart' as bip39;
import 'package:dio/dio.dart';
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import "package:photos/core/errors.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import "package:photos/events/account_configured_event.dart";
import 'package:photos/events/two_factor_status_change_event.dart';
import 'package:photos/events/user_details_changed_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/account/two_factor.dart";
import "package:photos/models/api/user/srp.dart";
import 'package:photos/models/delete_account.dart';
import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/key_gen_result.dart';
import 'package:photos/models/sessions.dart';
import 'package:photos/models/set_keys_request.dart';
import 'package:photos/models/set_recovery_key_request.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/ui/account/login_page.dart';
import 'package:photos/ui/account/ott_verification_page.dart';
import "package:photos/ui/account/passkey_page.dart";
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/account/password_reentry_page.dart';
import "package:photos/ui/account/recovery_page.dart";
import 'package:photos/ui/account/two_factor_authentication_page.dart';
import 'package:photos/ui/account/two_factor_recovery_page.dart';
import 'package:photos/ui/account/two_factor_setup_page.dart';
import "package:photos/ui/common/progress_dialog.dart";
import "package:photos/ui/tabs/home_widget.dart";
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import "package:pointycastle/export.dart";
import "package:pointycastle/srp/srp6_client.dart";
import "package:pointycastle/srp/srp6_standard_groups.dart";
import "package:pointycastle/srp/srp6_util.dart";
import "package:pointycastle/srp/srp6_verifier_generator.dart";
import 'package:shared_preferences/shared_preferences.dart';
import "package:uuid/uuid.dart";

class UserService {
  static const keyHasEnabledTwoFactor = "has_enabled_two_factor";
  static const keyUserDetails = "user_details";
  static const kReferralSource = "referral_source";

  final SRP6GroupParameters kDefaultSrpGroup = SRP6StandardGroups.rfc5054_4096;
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
    bool isResetPasswordScreen = false,
  }) async {
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
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
                  isResetPasswordScreen: isResetPasswordScreen,
                );
              },
            ),
          ),
        );
        return;
      } else {
        throw Exception("send-ott action failed, non-200");
      }
    } on DioError catch (e) {
      await dialog.hide();
      _logger.info(e);
      if (e.response != null && e.response!.statusCode == 403) {
        unawaited(
          showErrorDialog(
            context,
            S.of(context).oops,
            S.of(context).thisEmailIsAlreadyInUse,
          ),
        );
      } else {
        unawaited(showGenericErrorDialog(context: context, error: e));
      }
    } catch (e, s) {
      await dialog.hide();
      _logger.severe(e, s);
      unawaited(
        showGenericErrorDialog(context: context, error: e),
      );
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
          await setEmail(userDetails.email);
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
      // check if token is already invalid
      if (e is DioError && e.response?.statusCode == 401) {
        await Configuration.instance.logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      _logger.severe("Failed to logout", e);
      //This future is for waiting for the dialog from which logout() is called
      //to close and only then to show the error dialog.
      Future.delayed(
        const Duration(milliseconds: 150),
        () => showGenericErrorDialog(context: context, error: null),
      );
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
      _logger.warning(e);
      await showGenericErrorDialog(context: context, error: e);
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
      _logger.warning(e);
      rethrow;
    }
  }

  Future<dynamic> getTokenForPasskeySession(String sessionID) async {
    try {
      final response = await _dio.get(
        "${_config.getHttpEndpoint()}/users/two-factor/passkeys/get-token",
        queryParameters: {
          "sessionID": sessionID,
        },
      );
      return response.data;
    } on DioError catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 404 || e.response!.statusCode == 410) {
          throw PassKeySessionExpiredError();
        }
        if (e.response!.statusCode == 400) {
          throw PassKeySessionNotVerifiedError();
        }
      }
      rethrow;
    } catch (e, s) {
      _logger.warning("unexpected error", e, s);
      rethrow;
    }
  }

  Future<void> onPassKeyVerified(BuildContext context, Map response) async {
    final ProgressDialog dialog =
        createProgressDialog(context, context.l10n.pleaseWait);
    await dialog.show();
    try {
      final userPassword = Configuration.instance.getVolatilePassword();
      await _saveConfiguration(response);
      if (userPassword == null) {
        await dialog.hide();
        // ignore: unawaited_futures
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const PasswordReentryPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        if (Configuration.instance.getEncryptedToken() != null) {
          await Configuration.instance.decryptSecretsAndGetKeyEncKey(
            userPassword,
            Configuration.instance.getKeyAttributes()!,
          );
        } else {
          throw Exception("unexpected response during passkey verification");
        }
        await dialog.hide();
        Navigator.of(context).popUntil((route) => route.isFirst);
        Bus.instance.fire(AccountConfiguredEvent());
      }
    } catch (e) {
      _logger.warning(e);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> verifyEmail(
    BuildContext context,
    String ott, {
    bool isResettingPasswordScreen = false,
  }) async {
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
    await dialog.show();
    final verifyData = {
      "email": _config.getEmail(),
      "ott": ott,
    };
    if (!_config.isLoggedIn()) {
      verifyData["source"] = _getRefSource();
    }
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/verify-email",
        data: verifyData,
      );
      await dialog.hide();
      if (response.statusCode == 200) {
        Widget page;
        final String passkeySessionID = response.data["passkeySessionID"];
        final String twoFASessionID = response.data["twoFactorSessionID"];

        if (twoFASessionID.isNotEmpty) {
          await setTwoFactor(value: true);
          page = TwoFactorAuthenticationPage(twoFASessionID);
        } else if (passkeySessionID.isNotEmpty) {
          page = PasskeyPage(passkeySessionID);
        } else {
          await _saveConfiguration(response);
          if (Configuration.instance.getEncryptedToken() != null) {
            if (isResettingPasswordScreen) {
              page = const RecoveryPage();
            } else {
              page = const PasswordReentryPage();
            }
          } else {
            page = const PasswordEntryPage(
              mode: PasswordEntryMode.set,
            );
          }
        }
        await Navigator.of(context).pushAndRemoveUntil(
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
          S.of(context).oops,
          S.of(context).yourVerificationCodeHasExpired,
        );
        Navigator.of(context).pop();
      } else {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          S.of(context).incorrectCode,
          S.of(context).sorryTheCodeYouveEnteredIsIncorrect,
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.warning(e);
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        S.of(context).oops,
        S.of(context).verificationFailedPleaseTryAgain,
      );
    }
  }

  Future<void> setEmail(String email) async {
    await _config.setEmail(email);
    emailValueNotifier.value = email;
  }

  Future<void> setRefSource(String refSource) async {
    await _preferences.setString(kReferralSource, refSource);
  }

  String _getRefSource() {
    return _preferences.getString(kReferralSource) ?? "";
  }

  Future<void> changeEmail(
    BuildContext context,
    String email,
    String ott,
  ) async {
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
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
        showShortToast(context, S.of(context).emailChangedTo(email));
        await setEmail(email);
        Navigator.of(context).popUntil((route) => route.isFirst);
        Bus.instance.fire(UserDetailsChangedEvent());
        return;
      }
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        S.of(context).oops,
        S.of(context).verificationFailedPleaseTryAgain,
      );
    } on DioError catch (e) {
      await dialog.hide();
      if (e.response != null && e.response!.statusCode == 403) {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          S.of(context).oops,
          S.of(context).thisEmailIsAlreadyInUse,
        );
      } else {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          S.of(context).incorrectCode,
          S.of(context).authenticationFailedPleaseTryAgain,
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.warning(e);
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        S.of(context).oops,
        S.of(context).verificationFailedPleaseTryAgain,
      );
    }
  }

  Future<void> setAttributes(KeyGenResult result) async {
    try {
      await registerOrUpdateSrp(result.loginKey);
      await _enteDio.put(
        "/users/attributes",
        data: {
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

  Future<SrpAttributes> getSrpAttributes(String email) async {
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/srp/attributes",
        queryParameters: {
          "email": email,
        },
      );
      if (response.statusCode == 200) {
        return SrpAttributes.fromMap(response.data);
      } else {
        throw Exception("get-srp-attributes action failed");
      }
    } on DioError catch (e) {
      if (e.response != null && e.response!.statusCode == 404) {
        throw SrpSetupNotCompleteError();
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerOrUpdateSrp(
    Uint8List loginKey, {
    SetKeysRequest? setKeysRequest,
    bool logOutOtherDevices = false,
  }) async {
    try {
      final String username = const Uuid().v4().toString();
      final SecureRandom random = _getSecureRandom();
      final Uint8List identity = Uint8List.fromList(utf8.encode(username));
      final Uint8List password = loginKey;
      final Uint8List salt = random.nextBytes(16);
      final gen = SRP6VerifierGenerator(
        group: kDefaultSrpGroup,
        digest: Digest('SHA-256'),
      );
      final v = gen.generateVerifier(salt, identity, password);

      final client = SRP6Client(
        group: kDefaultSrpGroup,
        digest: Digest('SHA-256'),
        random: random,
      );

      final A = client.generateClientCredentials(salt, identity, password);
      final request = SetupSRPRequest(
        srpUserID: username,
        srpSalt: base64Encode(salt),
        srpVerifier: base64Encode(SRP6Util.encodeBigInt(v)),
        srpA: base64Encode(SRP6Util.encodeBigInt(A!)),
        isUpdate: false,
      );
      final response = await _enteDio.post(
        "/users/srp/setup",
        data: request.toMap(),
      );
      if (response.statusCode == 200) {
        final SetupSRPResponse setupSRPResponse =
            SetupSRPResponse.fromJson(response.data);
        final serverB =
            SRP6Util.decodeBigInt(base64Decode(setupSRPResponse.srpB));
        // ignore: need to calculate secret to get M1, unused_local_variable
        final clientS = client.calculateSecret(serverB);
        final clientM = client.calculateClientEvidenceMessage();
        // ignore: unused_local_variable
        late Response srpCompleteResponse;
        if (setKeysRequest == null) {
          srpCompleteResponse = await _enteDio.post(
            "/users/srp/complete",
            data: {
              'setupID': setupSRPResponse.setupID,
              'srpM1': base64Encode(SRP6Util.encodeBigInt(clientM!)),
            },
          );
        } else {
          srpCompleteResponse = await _enteDio.post(
            "/users/srp/update",
            data: {
              'setupID': setupSRPResponse.setupID,
              'srpM1': base64Encode(SRP6Util.encodeBigInt(clientM!)),
              'updatedKeyAttr': setKeysRequest.toMap(),
              'logOutOtherDevices': logOutOtherDevices,
            },
          );
        }
      } else {
        throw Exception("register-srp action failed");
      }
    } catch (e, s) {
      _logger.severe("failed to register srp", e, s);
      rethrow;
    }
  }

  SecureRandom _getSecureRandom() {
    final List<int> seeds = [];
    final random = Random.secure();
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(255));
    }
    final secureRandom = FortunaRandom();
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  Future<void> verifyEmailViaPassword(
    BuildContext context,
    SrpAttributes srpAttributes,
    String userPassword,
    ProgressDialog dialog,
  ) async {
    late Uint8List keyEncryptionKey;
    _logger.finest('Start deriving key');
    keyEncryptionKey = await CryptoUtil.deriveKey(
      utf8.encode(userPassword) as Uint8List,
      CryptoUtil.base642bin(srpAttributes.kekSalt),
      srpAttributes.memLimit,
      srpAttributes.opsLimit,
    );
    _logger.finest('keyDerivation done, derive LoginKey');
    final loginKey = await CryptoUtil.deriveLoginKey(keyEncryptionKey);
    final Uint8List identity = Uint8List.fromList(
      utf8.encode(srpAttributes.srpUserID),
    );
    _logger.finest('loginKey derivation done');
    final Uint8List salt = base64Decode(srpAttributes.srpSalt);
    final Uint8List password = loginKey;
    final SecureRandom random = _getSecureRandom();

    final client = SRP6Client(
      group: kDefaultSrpGroup,
      digest: Digest('SHA-256'),
      random: random,
    );

    final A = client.generateClientCredentials(salt, identity, password);
    final createSessionResponse = await _dio.post(
      _config.getHttpEndpoint() + "/users/srp/create-session",
      data: {
        "srpUserID": srpAttributes.srpUserID,
        "srpA": base64Encode(SRP6Util.encodeBigInt(A!)),
      },
    );
    final String sessionID = createSessionResponse.data["sessionID"];
    final String srpB = createSessionResponse.data["srpB"];

    final serverB = SRP6Util.decodeBigInt(base64Decode(srpB));
    // ignore: need to calculate secret to get M1, unused_local_variable
    final clientS = client.calculateSecret(serverB);
    final clientM = client.calculateClientEvidenceMessage();
    final response = await _dio.post(
      _config.getHttpEndpoint() + "/users/srp/verify-session",
      data: {
        "sessionID": sessionID,
        "srpUserID": srpAttributes.srpUserID,
        "srpM1": base64Encode(SRP6Util.encodeBigInt(clientM!)),
      },
    );
    if (response.statusCode == 200) {
      Widget page;
      final String twoFASessionID = response.data["twoFactorSessionID"];
      final String passkeySessionID = response.data["passkeySessionID"];

      Configuration.instance.setVolatilePassword(userPassword);
      if (twoFASessionID.isNotEmpty) {
        await setTwoFactor(value: true);
        page = TwoFactorAuthenticationPage(twoFASessionID);
      } else if (passkeySessionID.isNotEmpty) {
        page = PasskeyPage(passkeySessionID);
      } else {
        await _saveConfiguration(response);
        if (Configuration.instance.getEncryptedToken() != null) {
          await Configuration.instance.decryptSecretsAndGetKeyEncKey(
            userPassword,
            Configuration.instance.getKeyAttributes()!,
            keyEncryptionKey: keyEncryptionKey,
          );
          page = const HomeWidget();
        } else {
          throw Exception("unexpected response during email verification");
        }
      }
      await dialog.hide();
      if (page is HomeWidget) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Bus.instance.fire(AccountConfiguredEvent());
      } else {
        // ignore: unawaited_futures
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return page;
            },
          ),
          (route) => route.isFirst,
        );
      }
    } else {
      // should never reach here
      throw Exception("unexpected response during email verification");
    }
  }

  Future<void> updateKeyAttributes(
    KeyAttributes keyAttributes,
    Uint8List loginKey, {
    required bool logoutOtherDevices,
  }) async {
    try {
      final setKeyRequest = SetKeysRequest(
        kekSalt: keyAttributes.kekSalt,
        encryptedKey: keyAttributes.encryptedKey,
        keyDecryptionNonce: keyAttributes.keyDecryptionNonce,
        memLimit: keyAttributes.memLimit!,
        opsLimit: keyAttributes.opsLimit!,
      );
      await registerOrUpdateSrp(
        loginKey,
        setKeysRequest: setKeyRequest,
        logOutOtherDevices: logoutOtherDevices,
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
    final dialog = createProgressDialog(context, S.of(context).authenticating);
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
        showShortToast(context, S.of(context).authenticationSuccessful);
        await _saveConfiguration(response);
        await Navigator.of(context).pushAndRemoveUntil(
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
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          S.of(context).incorrectCode,
          S.of(context).authenticationFailedPleaseTryAgain,
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        S.of(context).oops,
        S.of(context).authenticationFailedPleaseTryAgain,
      );
    }
  }

  Future<void> recoverTwoFactor(
    BuildContext context,
    String sessionID,
    TwoFactorType type,
  ) async {
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
    await dialog.show();
    try {
      final response = await _dio.get(
        _config.getHttpEndpoint() + "/users/two-factor/recover",
        queryParameters: {
          "sessionID": sessionID,
          "twoFactorType": twoFactorTypeToString(type),
        },
      );
      if (response.statusCode == 200) {
        // ignore: unawaited_futures
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return TwoFactorRecoveryPage(
                type,
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
      await dialog.hide();
      _logger.severe(e);
      if (e.response != null && e.response!.statusCode == 404) {
        showToast(context, S.of(context).sessionExpired);
        // ignore: unawaited_futures
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          S.of(context).oops,
          S.of(context).somethingWentWrongPleaseTryAgain,
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe(e);
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        S.of(context).oops,
        S.of(context).somethingWentWrongPleaseTryAgain,
      );
    } finally {
      await dialog.hide();
    }
  }

  Future<void> removeTwoFactor(
    BuildContext context,
    TwoFactorType type,
    String sessionID,
    String recoveryKey,
    String encryptedSecret,
    String secretDecryptionNonce,
  ) async {
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
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
        S.of(context).incorrectRecoveryKey,
        S.of(context).theRecoveryKeyYouEnteredIsIncorrect,
      );
      return;
    }
    try {
      final response = await _dio.post(
        _config.getHttpEndpoint() + "/users/two-factor/remove",
        data: {
          "sessionID": sessionID,
          "secret": secret,
          "twoFactorType": twoFactorTypeToString(type),
        },
      );
      if (response.statusCode == 200) {
        showShortToast(
          context,
          S.of(context).twofactorAuthenticationSuccessfullyReset,
        );
        await _saveConfiguration(response);
        // ignore: unawaited_futures
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
      _logger.severe("error during recovery", e);
      if (e.response != null && e.response!.statusCode == 404) {
        showToast(context, "Session expired");
        // ignore: unawaited_futures
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginPage();
            },
          ),
          (route) => route.isFirst,
        );
      } else {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          S.of(context).oops,
          S.of(context).somethingWentWrongPleaseTryAgain,
        );
      }
    } catch (e) {
      await dialog.hide();
      _logger.severe('unexpcted error during recovery', e);

      // ignore: unawaited_futures
      showErrorDialog(
        context,
        S.of(context).oops,
        S.of(context).somethingWentWrongPleaseTryAgain,
      );
    } finally {
      await dialog.hide();
    }
  }

  Future<void> setupTwoFactor(BuildContext context, Completer completer) async {
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
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
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
    final dialog = createProgressDialog(context, S.of(context).verifying);
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
          // ignore: unawaited_futures
          showErrorDialog(
            context,
            S.of(context).incorrectCode,
            S.of(context).pleaseVerifyTheCodeYouHaveEntered,
          );
          return false;
        }
      }
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        S.of(context).somethingWentWrong,
        S.of(context).pleaseContactSupportIfTheProblemPersists,
      );
    }
    return false;
  }

  Future<void> disableTwoFactor(BuildContext context) async {
    final dialog = createProgressDialog(
      context,
      S.of(context).disablingTwofactorAuthentication,
    );
    await dialog.show();
    try {
      await _enteDio.post(
        "/users/two-factor/disable",
      );
      await dialog.hide();
      Bus.instance.fire(TwoFactorStatusChangeEvent(false));
      showShortToast(
        context,
        S.of(context).twofactorAuthenticationHasBeenDisabled,
      );
    } catch (e) {
      await dialog.hide();
      _logger.severe("Failed to disabled 2FA", e);
      await showErrorDialog(
        context,
        S.of(context).somethingWentWrong,
        S.of(context).pleaseContactSupportIfTheProblemPersists,
      );
    }
  }

  Future<bool> fetchTwoFactorStatus() async {
    try {
      final response = await _enteDio.get("/users/two-factor/status");
      await setTwoFactor(value: response.data["status"]);
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
      final dialog = createProgressDialog(context, S.of(context).pleaseWait);
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

  Future<void> _saveConfiguration(dynamic response) async {
    final responseData = response is Map ? response : response.data as Map?;
    if (responseData == null) return;

    await Configuration.instance.setUserID(responseData["id"]);
    if (responseData["encryptedToken"] != null) {
      await Configuration.instance
          .setEncryptedToken(responseData["encryptedToken"]);
      await Configuration.instance.setKeyAttributes(
        KeyAttributes.fromMap(responseData["keyAttributes"]),
      );
    } else {
      await Configuration.instance.setToken(responseData["token"]);
    }
  }

  Future<void> setTwoFactor({
    bool value = false,
    bool fetchTwoFactorStatus = false,
  }) async {
    if (fetchTwoFactorStatus) {
      value = await UserService.instance.fetchTwoFactorStatus();
    }
    await _preferences.setBool(keyHasEnabledTwoFactor, value);
  }

  bool hasEnabledTwoFactor() {
    return _preferences.getBool(keyHasEnabledTwoFactor) ?? false;
  }

  bool hasEmailMFAEnabled() {
    final UserDetails? profile = getCachedUserDetails();
    if (profile != null && profile.profileData != null) {
      return profile.profileData!.isEmailMFAEnabled;
    }
    return true;
  }

  Future<void> updateEmailMFA(bool isEnabled) async {
    try {
      await _enteDio.put(
        "/users/email-mfa",
        data: {
          "isEnabled": isEnabled,
        },
      );

      final UserDetails? profile = getCachedUserDetails();
      if (profile != null && profile.profileData != null) {
        profile.profileData!.isEmailMFAEnabled = isEnabled;
        await _preferences.setString(keyUserDetails, profile.toJson());
      }
    } catch (e) {
      _logger.severe("Failed to update email mfa", e);
      rethrow;
    }
  }
}
