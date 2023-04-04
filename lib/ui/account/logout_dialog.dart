import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:flutter/material.dart';

Future<void> autoLogoutAlert(BuildContext context) async {
  final l10n = context.l10n;
  final AlertDialog alert = AlertDialog(
    title: Text(l10n.sessionExpired),
    content: Text(l10n.pleaseLoginAgain),
    actions: [
      TextButton(
        child: Text(
          "Ok",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onPressed: () async {
          Navigator.of(context, rootNavigator: true).pop('dialog');
          Navigator.of(context).popUntil((route) => route.isFirst);
          final dialog = createProgressDialog(context, l10n.loggingOut);
          await dialog.show();
          await Configuration.instance.logout();
          await dialog.hide();
        },
      ),
    ],
  );
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
