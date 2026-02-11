import "dart:convert";
import "dart:math";
import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";
import "package:flutter/cupertino.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/emergency/model.dart";
import "package:photos/gateways/emergency/emergency_gateway.dart";
import "package:photos/gateways/users/models/key_attributes.dart";
import "package:photos/gateways/users/models/set_keys_request.dart";
import "package:photos/gateways/users/models/srp.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/ui/common/user_dialogs.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/email_util.dart";
import "package:pointycastle/pointycastle.dart";
import "package:pointycastle/random/fortuna_random.dart";
import "package:pointycastle/srp/srp6_client.dart";
import "package:pointycastle/srp/srp6_standard_groups.dart";
import "package:pointycastle/srp/srp6_util.dart";
import "package:pointycastle/srp/srp6_verifier_generator.dart";
import "package:uuid/uuid.dart";

class EmergencyContactService {
  late UserService _userService;
  late Configuration _config;
  late final Logger _logger = Logger("EmergencyContactService");

  EmergencyGateway get _gateway => emergencyGateway;

  EmergencyContactService._privateConstructor() {
    _userService = UserService.instance;
    _config = Configuration.instance;
  }

  static final EmergencyContactService instance =
      EmergencyContactService._privateConstructor();

  Future<bool> addContact(BuildContext context, String email) async {
    if (!isValidEmail(email)) {
      await showErrorDialog(
        context,
        AppLocalizations.of(context).invalidEmailAddress,
        AppLocalizations.of(context).enterValidEmail,
      );
      return false;
    } else if (email.trim() == Configuration.instance.getEmail()) {
      await showErrorDialog(
        context,
        AppLocalizations.of(context).oops,
        AppLocalizations.of(context).youCannotShareWithYourself,
      );
      return false;
    }
    final String? publicKey = await _userService.getPublicKey(email);
    if (publicKey == null) {
      await showInviteDialog(context, email);
      return false;
    }
    final Uint8List recoveryKey = Configuration.instance.getRecoveryKey();
    final encryptedKey = CryptoUtil.sealSync(
      recoveryKey,
      CryptoUtil.base642bin(publicKey),
    );
    await _gateway.addContact(
      email: email.trim(),
      encryptedKey: CryptoUtil.bin2base64(encryptedKey),
    );
    return true;
  }

  Future<EmergencyInfo> getInfo() async {
    try {
      return await _gateway.getInfo();
    } catch (e, s) {
      Logger("EmergencyContact").severe('failed to get info', e, s);
      rethrow;
    }
  }

  Future<void> updateContact(
    EmergencyContact contact,
    ContactState state,
  ) async {
    try {
      await _gateway.updateState(
        userID: contact.user.id,
        emergencyContactID: contact.emergencyContact.id,
        state: state.stringValue,
      );
    } catch (e, s) {
      Logger("EmergencyContact").severe('failed to update contact', e, s);
      rethrow;
    }
  }

  Future<void> startRecovery(EmergencyContact contact) async {
    try {
      await _gateway.startRecovery(
        userID: contact.user.id,
        emergencyContactID: contact.emergencyContact.id,
      );
    } catch (e, s) {
      Logger("EmergencyContact").severe('failed to start recovery', e, s);
      rethrow;
    }
  }

  Future<void> stopRecovery(RecoverySessions session) async {
    try {
      await _gateway.stopRecovery(
        userID: session.user.id,
        emergencyContactID: session.emergencyContact.id,
        sessionID: session.id,
      );
    } catch (e, s) {
      Logger("EmergencyContact").severe('failed to stop recovery', e, s);
      rethrow;
    }
  }

  Future<void> rejectRecovery(RecoverySessions session) async {
    try {
      await _gateway.rejectRecovery(
        userID: session.user.id,
        emergencyContactID: session.emergencyContact.id,
        sessionID: session.id,
      );
    } catch (e, s) {
      Logger("EmergencyContact").severe('failed to stop recovery', e, s);
      rethrow;
    }
  }

  Future<void> approveRecovery(RecoverySessions session) async {
    try {
      await _gateway.approveRecovery(
        userID: session.user.id,
        emergencyContactID: session.emergencyContact.id,
        sessionID: session.id,
      );
    } catch (e, s) {
      Logger("EmergencyContact").severe('failed to approve recovery', e, s);
      rethrow;
    }
  }

  Future<(String, KeyAttributes)> getRecoveryInfo(
    RecoverySessions sessions,
  ) async {
    try {
      final (encryptedKey, keyAttributes) =
          await _gateway.getRecoveryInfo(sessions.id);
      final decryptedKey = CryptoUtil.openSealSync(
        CryptoUtil.base642bin(encryptedKey),
        CryptoUtil.base642bin(_config.getKeyAttributes()!.publicKey),
        _config.getSecretKey()!,
      );
      final String hexRecoveryKey = CryptoUtil.bin2hex(decryptedKey);
      return (hexRecoveryKey, keyAttributes);
    } catch (e, s) {
      Logger("EmergencyContact").severe('failed to stop recovery', e, s);
      rethrow;
    }
  }

  Future<void> changePasswordForOther(
    Uint8List loginKey,
    SetKeysRequest setKeysRequest,
    RecoverySessions recoverySessions,
  ) async {
    try {
      final SRP6GroupParameters kDefaultSrpGroup =
          SRP6StandardGroups.rfc5054_4096;
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
      final setupSRPResponse = await _gateway.initPasswordChange(
        recoveryID: recoverySessions.id,
        setupSRPRequest: request,
      );
      final serverB =
          SRP6Util.decodeBigInt(base64Decode(setupSRPResponse.srpB));

      // ignore: unused_local_variable
      final clientS = client.calculateSecret(serverB);
      final clientM = client.calculateClientEvidenceMessage();
      await _gateway.changePassword(
        recoveryID: recoverySessions.id,
        setupID: setupSRPResponse.setupID,
        srpM1: base64Encode(SRP6Util.encodeBigInt(clientM!)),
        updatedKeyAttr: setKeysRequest.toMap(),
      );
    } catch (e, s) {
      _logger.severe("failed to change password for other", e, s);
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
}
