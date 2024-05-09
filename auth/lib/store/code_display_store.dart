import 'dart:convert';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/authenticator/entity_result.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/common/edit_tag.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class CodeDisplayStore {
  static final CodeDisplayStore instance =
      CodeDisplayStore._privateConstructor();

  CodeDisplayStore._privateConstructor();

  late CodeStore _codeStore;

  late AuthenticatorService _authenticatorService;
  final _logger = Logger("CodeDisplayStore");

  Future<void> init() async {
    _authenticatorService = AuthenticatorService.instance;
    _codeStore = CodeStore.instance;
  }

  Future<List<String>> getAllTags({AccountMode? accountMode}) async {
    final mode = accountMode ?? _authenticatorService.getAccountMode();
    final List<EntityResult> entities =
        await _authenticatorService.getEntities(mode);
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
        tags.addAll(code.display.tags);
      } catch (e) {
        _logger.severe("Could not parse code", e);
      }
    }
    tags = tags.toSet().toList();
    return tags;
  }

  Future<void> showDeleteTagDialog(BuildContext context, String tag) async {
    FocusScope.of(context).requestFocus();
    final l10n = context.l10n;

    await showChoiceActionSheet(
      context,
      title: l10n.deleteTagTitle,
      body: l10n.deleteTagMessage,
      firstButtonLabel: l10n.delete,
      isCritical: true,
      firstButtonOnTap: () async {
        // traverse through all the codes and edit this tag's value
        final relevantCodes = (await CodeStore.instance.getAllCodes()).where(
          (element) => !element.hasError && element.display.tags.contains(tag),
        );

        final tasks = <Future>[];

        for (final code in relevantCodes) {
          final tags = code.display.tags;
          tags.remove(tag);
          tasks.add(
            _codeStore.addCode(
              code.copyWith(
                display: code.display.copyWith(tags: tags),
              ),
            ),
          );
        }

        await Future.wait(tasks);
      },
    );
  }

  Future<void> showEditDialog(BuildContext context, String tag) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditTagDialog(tag: tag);
      },
      barrierColor: Colors.black.withOpacity(0.85),
      barrierDismissible: false,
    );
  }

  Future<void> editTag(String previousTag, String updatedTag) async {
    // traverse through all the codes and edit this tag's value
    final relevantCodes = (await CodeStore.instance.getAllCodes()).where(
      (element) =>
          !element.hasError && element.display.tags.contains(previousTag),
    );

    final tasks = <Future>[];

    for (final code in relevantCodes) {
      final tags = code.display.tags;
      tags.remove(previousTag);
      tags.add(updatedTag);
      tasks.add(
        CodeStore.instance.addCode(
          code.copyWith(
            display: code.display.copyWith(tags: tags),
          ),
        ),
      );
    }

    await Future.wait(tasks);
  }
}
