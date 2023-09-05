import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/models/authenticator/entity_result.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/store/offline_authenticator_db.dart';
import 'package:logging/logging.dart';

class CodeStore {
  static final CodeStore instance = CodeStore._privateConstructor();

  CodeStore._privateConstructor();

  late AuthenticatorService _authenticatorService;
  final _logger = Logger("CodeStore");

  Future<void> init() async {
    _authenticatorService = AuthenticatorService.instance;
  }

  Future<List<Code>> getAllCodes({AccountMode? accountMode}) async {
    final mode = accountMode ?? _authenticatorService.getAccountMode();
    final List<EntityResult> entities =
        await _authenticatorService.getEntities(mode);
    final List<Code> codes = [];
    for (final entity in entities) {
      final decodeJson = jsonDecode(entity.rawData);
      final code = Code.fromRawData(decodeJson);
      code.generatedID = entity.generatedID;
      code.hasSynced = entity.hasSynced;
      codes.add(code);
    }

    // sort codes by issuer,account
    codes.sort((a, b) {
      final issuerComparison = compareAsciiLowerCaseNatural(a.issuer, b.issuer);
      if (issuerComparison != 0) {
        return issuerComparison;
      }
      return compareAsciiLowerCaseNatural(a.account, b.account);
    });
    return codes;
  }

  Future<AddResult> addCode(
    Code code, {
    bool shouldSync = true,
    AccountMode? accountMode,
  }) async {
    final mode = accountMode ?? _authenticatorService.getAccountMode();
    final codes = await getAllCodes(accountMode: mode);
    bool isExistingCode = false;
    for (final existingCode in codes) {
      if (existingCode == code) {
        _logger.info("Found duplicate code, skipping add");
        return AddResult.duplicate;
      } else if (existingCode.generatedID == code.generatedID) {
        isExistingCode = true;
        break;
      }
    }
    late AddResult result;
    if (isExistingCode) {
      result = AddResult.updateCode;
      await _authenticatorService.updateEntry(
        code.generatedID!,
        jsonEncode(code.rawData),
        shouldSync,
        mode,
      );
    } else {
      result = AddResult.newCode;
      code.generatedID = await _authenticatorService.addEntry(
        jsonEncode(code.rawData),
        shouldSync,
        mode,
      );
    }
    Bus.instance.fire(CodesUpdatedEvent());
    return result;
  }

  Future<void> removeCode(Code code, {AccountMode? accountMode}) async {
    final mode = accountMode ?? _authenticatorService.getAccountMode();
    await _authenticatorService.deleteEntry(code.generatedID!, mode);
    Bus.instance.fire(CodesUpdatedEvent());
  }

  Future<void> importOfflineCodes() async {
    Logger logger = Logger('importOfflineCodes');
    try {
      Configuration config = Configuration.instance;
      if (!config.hasConfiguredAccount() ||
          !config.hasOptedForOfflineMode() ||
          config.getOfflineSecretKey() == null) {
        return;
      }
      logger.info('start import');

      List<Code> offlineCodes = await CodeStore.instance
          .getAllCodes(accountMode: AccountMode.offline);
      if (offlineCodes.isEmpty) {
        return;
      }
      bool isOnlineSyncDone = await AuthenticatorService.instance.onlineSync();
      if (!isOnlineSyncDone) {
        logger.info("skip as online sync is not done");
        return;
      }
      final List<Code> onlineCodes =
          await CodeStore.instance.getAllCodes(accountMode: AccountMode.online);
      logger.info(
        'importing ${offlineCodes.length} offline codes with ${onlineCodes.length} online codes',
      );
      for (Code eachCode in offlineCodes) {
        bool alreadyPresent = onlineCodes.any(
          (oc) =>
              oc.issuer == eachCode.issuer &&
              oc.account == eachCode.account &&
              oc.secret == eachCode.secret,
        );
        int? generatedID = eachCode.generatedID!;
        logger.info(
          'importingCode: genID ${eachCode.generatedID} & isAlreadyPresent $alreadyPresent',
        );
        if (!alreadyPresent) {
          // Avoid conflict with generatedID of online codes
          eachCode.generatedID = null;
          final AddResult result = await CodeStore.instance.addCode(
            eachCode,
            accountMode: AccountMode.online,
            shouldSync: false,
          );
          logger.info(
            'importedCode: genID ${eachCode.generatedID} result: ${result.name}',
          );
        }
        await OfflineAuthenticatorDB.instance.deleteByIDs(
          generatedIDs: [generatedID],
        );
      }
      AuthenticatorService.instance.onlineSync().ignore();
    } catch (e, s) {
      _logger.severe("error while importing offline codes", e, s);
    }
  }
}

enum AddResult {
  newCode,
  duplicate,
  updateCode,
}
