import "package:flutter/cupertino.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/button_result.dart';
import "package:photos/service_locator.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";

Future<bool> requestForMapEnable(BuildContext context) async {
  if (flagService.mapEnabled) {
    return true;
  }

  final ButtonResult? result = await showDialogWidget(
    context: context,
    title: AppLocalizations.of(context).enableMaps,
    body: AppLocalizations.of(context).enableMapsDesc,
    isDismissible: true,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        buttonAction: ButtonAction.first,
        labelText: AppLocalizations.of(context).enableMaps,
        isInAlert: true,
        onTap: () async {
          await flagService.setMapEnabled(true);
        },
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        buttonAction: ButtonAction.second,
        labelText: AppLocalizations.of(context).cancel,
        isInAlert: true,
      ),
    ],
  );
  if (result?.action == ButtonAction.first) {
    return true;
  }
  if (result?.action == ButtonAction.error) {
    showShortToast(context, AppLocalizations.of(context).somethingWentWrong);
    return false;
  }
  return false;
}

//For debugging.
void disableMap() {
  flagService.setMapEnabled(false);
}
