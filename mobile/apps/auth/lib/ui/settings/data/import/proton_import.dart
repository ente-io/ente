import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/common/progress_dialog.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/settings/data/import/import_success.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

Future<void> showProtonImportInstruction(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialogWidget(
    context: context,
    title: l10n.importFromApp("Proton Authenticator"),
    body: l10n.importProtonAuthGuide,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: l10n.importSelectJsonFile,
        isInAlert: true,
        buttonSize: ButtonSize.large,
        buttonAction: ButtonAction.first,
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: context.l10n.cancel,
        buttonSize: ButtonSize.large,
        isInAlert: true,
        buttonAction: ButtonAction.second,
      ),
    ],
  );
  if (result?.action != null && result!.action != ButtonAction.cancel) {
    if (result.action == ButtonAction.first) {
      await _pickProtonJsonFile(context);
    }
  }
}

Future<void> _pickProtonJsonFile(BuildContext context) async {
  final l10n = context.l10n;
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(dialogTitle: l10n.importSelectJsonFile);
  if (result == null) {
    return;
  }
  final ProgressDialog progressDialog =
      createProgressDialog(context, l10n.pleaseWait);
  await progressDialog.show();
  try {
    String path = result.files.single.path!;
    int? count = await _processProtonExportFile(context, path, progressDialog);
    await progressDialog.hide();
    if (count != null) {
      await importSuccessDialog(context, count);
    }
  } catch (e, s) {
    Logger('ProtonImport')
        .severe('exception while processing proton import', e, s);
    await progressDialog.hide();
    await showErrorDialog(
      context,
      context.l10n.sorry,
      "${context.l10n.importFailureDescNew}\n Error: ${e.toString()}",
    );
  }
}

Future<int?> _processProtonExportFile(
  BuildContext context,
  String path,
  final ProgressDialog dialog,
) async {
  File file = File(path);

  final jsonString = await file.readAsString();
  final decodedJson = jsonDecode(jsonString);

  // Validate that this is a Proton export
  if (decodedJson['version'] == null || decodedJson['entries'] == null) {
    await dialog.hide();
    await showErrorDialog(
      context,
      'Invalid Proton export',
      'The selected file is not a valid Proton Authenticator export.',
    );
    return null;
  }

  final parsedCodes = <Code>[];
  final entries = decodedJson['entries'] as List;

  for (var entry in entries) {
    try {
      final content = entry['content'];
      if (content == null) {
        continue; // Skip entries without content
      }

      final entryType = content['entry_type'] as String?;
      if (entryType != 'Totp' && entryType != 'Steam') {
        // log warning
        Logger('ProtonImport').warning('Unsupported entry type: $entryType');
        continue; // Skip non-TOTP and non-Steam entries
      }

      Code code;

      if (entryType == 'Steam') {
        // Handle Steam entries with steam:// format
        final steamUri = content['uri'] as String?;
        if (steamUri == null || !steamUri.startsWith('steam://')) {
          continue; // Skip invalid Steam URIs
        }

        final secret = steamUri.split('steam://')[1];
        final name = content['name'] as String? ?? '';

        code = Code.fromAccountAndSecret(
          Type.steam,
          '', // Steam doesn't typically have separate account
          name, // Use name as issuer
          secret,
          null,
          Code.steamDigits,
        );
      } else {
        // Handle TOTP entries with otpauth:// format
        final otpUri = content['uri'] as String?;
        if (otpUri == null || !otpUri.startsWith('otpauth://')) {
          continue; // Skip invalid OTP URIs
        }
        // Create code from OTP auth URL
        code = Code.fromOTPAuthUrl(otpUri);
      }

      // Add note if present
      final note = entry['note'] as String?;
      if (note != null && note.isNotEmpty) {
        code = code.copyWith(
          display: code.display.copyWith(note: note),
        );
      }

      parsedCodes.add(code);
    } catch (e, s) {
      Logger('ProtonImport').warning('Failed to parse entry', e, s);
      // Continue processing other entries
    }
  }

  // Add all parsed codes to the store
  for (final code in parsedCodes) {
    await CodeStore.instance.addCode(code, shouldSync: false);
  }

  // Trigger sync
  unawaited(AuthenticatorService.instance.onlineSync());

  return parsedCodes.length;
}
