import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:flutter/cupertino.dart';

Future<void> importSuccessDialog(BuildContext context, int count) async {
  final DialogWidget dialog = choiceDialog(
    title: context.l10n.importSuccessTitle,
    body: context.l10n.importSuccessDesc(count),
    firstButtonLabel: context.l10n.ok,
    firstButtonOnTap: () async {
      Navigator.of(context).pop();
      // if(Navigator.of(context).canPop()) {
      //   Navigator.of(context).pop();
      // }
    },
    firstButtonType: ButtonType.primary,
  );
  await showConfettiDialog(
    context: context,
    dialogBuilder: (BuildContext context) {
      return dialog;
    },
  );
}
