import "package:flutter/cupertino.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_type.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/file/file_info_widget.dart";
import "package:photos/utils/delete_file_util.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/toast_util.dart";

Future<void> showSingleFileDeleteSheet(
  BuildContext context,
  File file, {
  Function(File)? onFileRemoved,
}) async {
  final List<ButtonWidget> buttons = [];
  final String fileType = file.fileType == FileType.video ? "video" : "photo";
  final bool isBothLocalAndRemote =
      file.uploadedFileID != null && file.localID != null;
  final bool isLocalOnly = file.uploadedFileID == null && file.localID != null;
  final bool isRemoteOnly = file.uploadedFileID != null && file.localID == null;
  const String bodyHighlight = "It will be deleted from all albums.";
  String body = "";
  if (isBothLocalAndRemote) {
    body = "This $fileType is in both ente and your device.";
  } else if (isRemoteOnly) {
    body = "This $fileType will be deleted from ente.";
  } else if (isLocalOnly) {
    body = "This $fileType will be deleted from your device.";
  } else {
    throw AssertionError("Unexpected state");
  }
  // Add option to delete from ente
  if (isBothLocalAndRemote || isRemoteOnly) {
    buttons.add(
      ButtonWidget(
        labelText: isBothLocalAndRemote ? "Delete from ente" : "Yes, delete",
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.first,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromRemoteOnly(context, [file]);
          showShortToast(context, "Moved to trash");
          if (isRemoteOnly) {
            Navigator.of(context, rootNavigator: true).pop();
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
        labelText: isBothLocalAndRemote ? "Delete from device" : "Yes, delete",
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.second,
        shouldSurfaceExecutionStates: false,
        isInAlert: true,
        onTap: () async {
          await deleteFilesOnDeviceOnly(context, [file]);
          if (isLocalOnly) {
            Navigator.of(context, rootNavigator: true).pop();
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
        labelText: "Delete from both",
        buttonType: ButtonType.neutral,
        buttonSize: ButtonSize.large,
        shouldStickToDarkTheme: true,
        buttonAction: ButtonAction.third,
        shouldSurfaceExecutionStates: true,
        isInAlert: true,
        onTap: () async {
          await deleteFilesFromEverywhere(context, [file]);
          Navigator.of(context, rootNavigator: true).pop();
          if (onFileRemoved != null) {
            onFileRemoved(file);
          }
        },
      ),
    );
  }
  buttons.add(
    const ButtonWidget(
      labelText: "Cancel",
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
    showGenericErrorDialog(context: context);
  }
}

Future<void> showInfoSheet(BuildContext context, File file) async {
  final colorScheme = getEnteColorScheme(context);
  return showBarModalBottomSheet(
    topControl: const SizedBox.shrink(),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    backgroundColor: colorScheme.backgroundElevated,
    barrierColor: backdropFaintDark,
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FileInfoWidget(file),
      );
    },
  );
}
