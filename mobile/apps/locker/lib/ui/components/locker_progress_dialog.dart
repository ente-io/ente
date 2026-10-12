import 'package:ente_components/ente_components.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/services/feature_flag_service.dart';

Future<LockerProgressDialog> showLockerProgressDialog(
  BuildContext context,
  String message, {
  bool useNewUi = false,
  bool isDismissible = false,
}) async {
  if (useNewUi || FeatureFlagService.instance.internalUser) {
    final dialog = showLoadingComponent(
      context,
      message,
      isDismissible: isDismissible,
    );
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    return LockerProgressDialog._(
      true,
      dialog.isShowing,
      dialog.update,
      dialog.hide,
    );
  }

  final dialog = createProgressDialog(
    context,
    message,
    isDismissible: isDismissible,
  );
  return LockerProgressDialog._(
    await dialog.show(),
    dialog.isShowing,
    dialog.update,
    dialog.hide,
  );
}

class LockerProgressDialog {
  const LockerProgressDialog._(
    this.didShow,
    this.isShowing,
    this.update,
    this.hide,
  );

  final bool didShow;
  final bool Function() isShowing;
  final void Function({String? message}) update;
  final Future<void> Function() hide;
}
