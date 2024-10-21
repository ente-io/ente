import "dart:async";

import "package:flutter/cupertino.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/viewer/file/file_details_widget.dart';
import "package:photos/utils/delete_file_util.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/panorama_util.dart";
import "package:photos/utils/toast_util.dart";

Future<void> showSingleFileDeleteSheet(
  BuildContext context,
  EnteFile file, {
  Function(EnteFile)? onFileRemoved,
}) async {
  final List<ButtonWidget> buttons = [];
  final String fileType = file.fileType == FileType.video
      ? S.of(context).videoSmallCase
      : S.of(context).photoSmallCase;
  final bool isBothLocalAndRemote =
      file.uploadedFileID != null && file.localID != null;
  final bool isLocalOnly = file.uploadedFileID == null && file.localID != null;
  final bool isRemoteOnly = file.uploadedFileID != null && file.localID == null;
  final String bodyHighlight = S.of(context).singleFileDeleteHighlight;
  String body = "";
  if (isBothLocalAndRemote) {
    body = S.of(context).singleFileInBothLocalAndRemote(fileType);
  } else if (isRemoteOnly) {
    body = S.of(context).singleFileInRemoteOnly(fileType);
  } else if (isLocalOnly) {
    body = S.of(context).singleFileDeleteFromDevice(fileType);
  } else {
    throw AssertionError("Unexpected state");
  }
  // Add option to delete from ente
  if (isBothLocalAndRemote || isRemoteOnly) {
    buttons.add(
      ButtonWidget(
        labelText: isBothLocalAndRemote
            ? S.of(context).deleteFromEnte
            : S.of(context).yesDelete,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.first,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromRemoteOnly(context, [file]);
          showShortToast(context, S.of(context).movedToTrash);
          if (isRemoteOnly) {
            if (onFileRemoved != null) {
              onFileRemoved(file);
            }
          }
        },
      ),
    );
  }
  // Add option to delete from local
  if (isBothLocalAndRemote || isLocalOnly) {
    buttons.add(
      ButtonWidget(
        labelText: isBothLocalAndRemote
            ? S.of(context).deleteFromDevice
            : S.of(context).yesDelete,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.second,
        shouldSurfaceExecutionStates: false,
        isInAlert: true,
        onTap: () async {
          await deleteFilesOnDeviceOnly(context, [file]);
          if (isLocalOnly) {
            if (onFileRemoved != null) {
              onFileRemoved(file);
            }
          }
        },
      ),
    );
  }
  if (isBothLocalAndRemote) {
    buttons.add(
      ButtonWidget(
        labelText: S.of(context).deleteFromBoth,
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.third,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromEverywhere(context, [file]);
          Navigator.of(context).pop();
          if (onFileRemoved != null) {
            onFileRemoved(file);
          }
        },
      ),
    );
  }
  buttons.add(
    ButtonWidget(
      labelText: S.of(context).cancel,
      buttonType: ButtonType.secondary,
      buttonSize: ButtonSize.large,
      shouldStickToDarkTheme: true,
      buttonAction: ButtonAction.fourth,
      isInAlert: true,
    ),
  );
  final actionResult = await showActionSheet(
    context: context,
    buttons: buttons,
    actionSheetType: ActionSheetType.defaultActionSheet,
    body: body,
    bodyHighlight: bodyHighlight,
  );
  if (actionResult?.action != null &&
      actionResult!.action == ButtonAction.error) {
    await showGenericErrorDialog(
      context: context,
      error: actionResult.exception,
    );
  }
}

Future<void> showDetailsSheet(BuildContext context, EnteFile file) async {
  guardedCheckPanorama(file).ignore();
  final colorScheme = getEnteColorScheme(context);
  return showBarModalBottomSheet(
    topControl: const SizedBox.shrink(),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    backgroundColor: colorScheme.backgroundElevated,
    barrierColor: backdropFaintDark,
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FileDetailsWidget(file),
      );
    },
  );
}
