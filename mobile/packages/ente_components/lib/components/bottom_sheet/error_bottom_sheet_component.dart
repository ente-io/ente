import 'dart:async';

import 'package:ente_components/components/bottom_sheet/bottom_sheet_component.dart';
import 'package:flutter/material.dart';

/// Shows the standard error sheet while leaving app-specific
/// localization, parsing, logging, and support actions to the caller.
Future<T?> showErrorBottomSheetComponent<T>({
  required BuildContext context,
  required String message,
  String title = 'Error',
  Widget? illustration,
  List<Widget> actions = const [],

  /// Called when the close button is pressed, before the sheet is dismissed.
  ///
  /// Barrier taps, drag dismissals, and system back dismissals do not call this.
  FutureOr<void> Function()? onClose,
  bool showCloseButton = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  Color? barrierColor,
}) {
  return showBottomSheetComponent<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    barrierColor: barrierColor,
    builder: (_) => BottomSheetComponent(
      title: title,
      message: message,
      illustration: illustration,
      actions: actions,
      onClose: onClose,
      showCloseButton: showCloseButton,
    ),
  );
}
