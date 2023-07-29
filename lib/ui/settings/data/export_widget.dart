import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> handleExportClick(BuildContext context) async {
  final result = await showDialogWidget(
    context: context,
    title: "Select export format",
    body: "Encrypted exports will be protected by a password of your choice.",
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: "Encrypted",
        isInAlert: true,
        buttonSize: ButtonSize.large,
        buttonAction: ButtonAction.first,
        onTap: () async {
          showShortToast(context, "Encrypted export");
        },
        // shouldShowSuccessConfirmation: true,
      ),
      const ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: "Plain text",
        buttonSize: ButtonSize.large,
        isInAlert: true,
        buttonAction: ButtonAction.second,
      ),

    ],
  );
  if (result?.action != null && result!.action != ButtonAction.cancel) {
    await _showExportWarningDialog(context);
  }
}

Future<void> _showExportWarningDialog(BuildContext context) async {
  await showChoiceActionSheet(
    context,
    title: context.l10n.warning,
    body: context.l10n.exportWarningDesc,
    isCritical: true,
    firstButtonOnTap: () async {
      _exportCodes(context);
    },
    secondButtonLabel: context.l10n.cancel,
    firstButtonLabel: context.l10n.iUnderStand,
  );
}

Future<void> _exportCodes(BuildContext context) async {
  final _codeFile = File(
    Configuration.instance.getTempDirectory() + "ente-authenticator-codes.txt",
  );
  final hasAuthenticated = await LocalAuthenticationService.instance
      .requestLocalAuthentication(context, context.l10n.authToExportCodes);
  if (!hasAuthenticated) {
    return;
  }
  if (_codeFile.existsSync()) {
    await _codeFile.delete();
  }
  final codes = await CodeStore.instance.getAllCodes();
  String data = "";
  for (final code in codes) {
    data += code.rawData + "\n";
  }
  _codeFile.writeAsStringSync(data);
  await Share.shareFiles([_codeFile.path]);
  Future.delayed(const Duration(seconds: 15), () async {
    if (_codeFile.existsSync()) {
      _codeFile.deleteSync();
    }
  });
}
