import "package:flutter/cupertino.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/button_result.dart';
import "package:photos/services/user_remote_flag_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/toast_util.dart";

Future<bool> requestForMapEnable(BuildContext context) async {
  const String flagName = UserRemoteFlagService.mapEnabled;
  if (UserRemoteFlagService.instance.getCachedBoolValue(flagName)) {
    return true;
  }

  final ButtonResult? result = await showDialogWidget(
    context: context,
    title: S.of(context).enableMaps,
    body: S.of(context).enableMapsDesc,
    isDismissible: true,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        buttonAction: ButtonAction.first,
        labelText: S.of(context).enableMaps,
        isInAlert: true,
        onTap: () async {
          await UserRemoteFlagService.instance.setBoolValue(
            flagName,
            true,
          );
        },
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        buttonAction: ButtonAction.second,
        labelText: S.of(context).cancel,
        isInAlert: true,
      ),
    ],
  );
  if (result?.action == ButtonAction.first) {
    return true;
  }
  if (result?.action == ButtonAction.error) {
    showShortToast(context, S.of(context).somethingWentWrong);
    return false;
  }
  return false;
}
