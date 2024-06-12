import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/common/edit_tag.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:flutter/material.dart';

class CodeDisplayStore {
  static final CodeDisplayStore instance =
      CodeDisplayStore._privateConstructor();

  CodeDisplayStore._privateConstructor();

  late CodeStore _codeStore;

  Future<void> init() async {
    _codeStore = CodeStore.instance;
  }

  Future<List<String>> getAllTags({
    AccountMode? accountMode,
    List<Code>? allCodes,
  }) async {
    final codes = allCodes ??
        await _codeStore.getAllCodes(
          accountMode: accountMode,
          sortCodes: false,
        );
    final tags = <String>{};
    for (final code in codes) {
      if (code.hasError) continue;
      tags.addAll(code.display.tags);
    }
    return tags.toList()..sort();
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
        final relevantCodes = await _getCodesByTag(tag);

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

  Future<List<Code>> _getCodesByTag(String tag) async {
    final codes = await _codeStore.getAllCodes(sortCodes: false);
    return codes
        .where(
          (element) => !element.hasError && element.display.tags.contains(tag),
        )
        .toList();
  }

  Future<void> editTag(String previousTag, String updatedTag) async {
    // traverse through all the codes and edit this tag's value
    final relevantCodes = await _getCodesByTag(previousTag);

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
