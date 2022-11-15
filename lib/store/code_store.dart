import 'dart:convert';

import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/models/authenticator/entity_result.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:logging/logging.dart';

class CodeStore {
  static final CodeStore instance = CodeStore._privateConstructor();

  CodeStore._privateConstructor();

  late AuthenticatorService _authenticatorService;
  final _logger = Logger("CodeStore");

  Future<void> init() async {
    _authenticatorService = AuthenticatorService.instance;
  }

  Future<List<Code>> getAllCodes() async {
    final List<EntityResult> entities =
        await _authenticatorService.getEntities();
    final List<Code> codes = [];
    for (final entity in entities) {
      final decodeJson = jsonDecode(entity.rawData);
      final code = Code.fromRawData(decodeJson);
      code.id = entity.generatedID;
      code.hasSynced = entity.hasSynced;
      codes.add(code);
    }
    codes.sort((c1, c2) {
      return c1.issuer.toLowerCase().compareTo(c2.issuer.toLowerCase());
    });
    return codes;
  }

  Future<void> addCode(
    Code code, {
    bool shouldSync = true,
  }) async {
    final codes = await getAllCodes();
    for (final existingCode in codes) {
      if (existingCode == code) {
        _logger.info("Found duplicate code, skipping add");
        return;
      }
    }
    code.id = await _authenticatorService.addEntry(
      jsonEncode(code.rawData),
      shouldSync,
    );
    Bus.instance.fire(CodesUpdatedEvent());
  }

  Future<void> removeCode(Code code) async {
    await _authenticatorService.deleteEntry(code.id!);
    Bus.instance.fire(CodesUpdatedEvent());
  }
}
