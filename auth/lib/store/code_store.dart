import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/models/authenticator/entity_result.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/models/codes.dart';
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

  Future<Codes> getAllCodes({AccountMode? accountMode}) async {
    final mode = accountMode ?? _authenticatorService.getAccountMode();
    final List<EntityResult> entities =
        await _authenticatorService.getEntities(mode);
    final List<CodeState> codes = [];
    List<String> tags = [];
    for (final entity in entities) {
      try {
        final decodeJson = jsonDecode(entity.rawData);

        late Code code;
        if (decodeJson is String && decodeJson.startsWith('otpauth://')) {
          code = Code.fromOTPAuthUrl(decodeJson);
        } else {
          code = Code.fromExportJson(decodeJson);
        }
        code.generatedID = entity.generatedID;
        code.hasSynced = entity.hasSynced;
        codes.add(CodeState(code: code, error: null));
        tags.addAll(code.display.tags);
      } catch (e) {
        codes.add(CodeState(code: null, error: e.toString()));
        _logger.severe("Could not parse code", e);
      }
    }

    // sort codes by issuer,account
    codes.sort((a, b) {
      if (a.code == null && b.code == null) return 0;
      if (a.code == null) return 1;
      if (b.code == null) return -1;

      final firstCode = a.code!;
      final secondCode = b.code!;

      if (secondCode.isPinned && !firstCode.isPinned) return 1;
      if (!secondCode.isPinned && firstCode.isPinned) return -1;

      final issuerComparison =
          compareAsciiLowerCaseNatural(firstCode.issuer, secondCode.issuer);
      if (issuerComparison != 0) {
        return issuerComparison;
      }
      return compareAsciiLowerCaseNatural(
        firstCode.account,
        secondCode.account,
      );
    });
    tags = tags.toSet().toList();
    return Codes(allCodes: codes, tags: tags);
  }

  Future<AddResult> addCode(
    Code code, {
    bool shouldSync = true,
    AccountMode? accountMode,
  }) async {
    final mode = accountMode ?? _authenticatorService.getAccountMode();
    final codes = await getAllCodes(accountMode: mode);
    bool isExistingCode = false;
    bool hasSameCode = false;
    for (final existingCode in codes.validCodes) {
      if (code.generatedID != null &&
          existingCode.generatedID == code.generatedID) {
        isExistingCode = true;
        break;
      }
      if (existingCode == code) {
        hasSameCode = true;
      }
    }
    if (!isExistingCode && hasSameCode) {
      return AddResult.duplicate;
    }
    late AddResult result;
    if (isExistingCode) {
      result = AddResult.updateCode;
      await _authenticatorService.updateEntry(
        code.generatedID!,
        code.toExportFormat(),
        shouldSync,
        mode,
      );
    } else {
      result = AddResult.newCode;
      code.generatedID = await _authenticatorService.addEntry(
        code.toExportFormat(),
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

  bool _isOfflineImportRunning = false;

  Future<void> importOfflineCodes() async {
    if (_isOfflineImportRunning) {
      return;
    }
    _isOfflineImportRunning = true;
    Logger logger = Logger('importOfflineCodes');
    try {
      Configuration config = Configuration.instance;
      if (!config.hasConfiguredAccount() ||
          !config.hasOptedForOfflineMode() ||
          config.getOfflineSecretKey() == null) {
        return;
      }
      logger.info('start import');

      List<Code> offlineCodes = (await CodeStore.instance
              .getAllCodes(accountMode: AccountMode.offline))
          .validCodes;
      if (offlineCodes.isEmpty) {
        return;
      }
      bool isOnlineSyncDone = await AuthenticatorService.instance.onlineSync();
      if (!isOnlineSyncDone) {
        logger.info("skip as online sync is not done");
        return;
      }
      final List<Code> onlineCodes = (await CodeStore.instance
              .getAllCodes(accountMode: AccountMode.online))
          .validCodes;
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
    } finally {
      _isOfflineImportRunning = false;
    }
  }
}

enum AddResult {
  newCode,
  duplicate,
  updateCode,
}
