import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:flutter/material.dart';

Future<void> shareDialog(
  BuildContext context,
  String title, {
  required Function saveAction,
  required Function sendAction,
}) async {
  final l10n = context.l10n;
  await showDialogWidget(
    context: context,
    title: title,
    body: Platform.isLinux || Platform.isWindows
        ? l10n.saveOnlyDescription
        : l10n.saveOrSendDescription,
    buttons: [
      ButtonWidget(
        isInAlert: true,
        buttonType: ButtonType.neutral,
        labelText: l10n.save,
        buttonAction: ButtonAction.first,
        shouldSurfaceExecutionStates: false,
        onTap: () async {
          await saveAction();
        },
      ),
      if (!Platform.isWindows && !Platform.isLinux)
        ButtonWidget(
          isInAlert: true,
          buttonType: ButtonType.secondary,
          labelText: l10n.send,
          buttonAction: ButtonAction.second,
          onTap: () async {
            await sendAction();
          },
        ),
      ButtonWidget(
        isInAlert: true,
        buttonType: ButtonType.secondary,
        labelText: l10n.cancel,
        buttonAction: ButtonAction.cancel,
      ),
    ],
  );
}
