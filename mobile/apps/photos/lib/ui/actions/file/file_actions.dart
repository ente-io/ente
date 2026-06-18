import "dart:async";
import "dart:io";

import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/details_sheet_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/button_result.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/button_widget.dart'
    show ButtonAction;
import "package:photos/ui/components/more_options_button.dart";
import "package:photos/ui/notification/toast.dart";
import 'package:photos/ui/viewer/file/file_details_widget.dart';
import "package:photos/utils/delete_file_util.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/panorama_util.dart";

Future<void> showSingleFileDeleteSheet(
  BuildContext context,
  EnteFile file, {
  Function(EnteFile)? onFileRemoved,
  bool isLocalOnlyContext = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final String fileType = file.fileType == FileType.video
      ? l10n.videoSmallCase
      : l10n.photoSmallCase;
  final bool isBothLocalAndRemote =
      file.uploadedFileID != null && file.localID != null;
  final bool isLocalOnly = file.uploadedFileID == null && file.localID != null;
  final bool isRemoteOnly = file.uploadedFileID != null && file.localID == null;
  if (isLocalGalleryMode) {
    if (file.localID == null) {
      showShortToast(context, l10n.noDeviceThatCanBeDeleted);
      return;
    }
    final deletedFiles = await deleteFilesOnDeviceOnly(context, [file]);
    if (deletedFiles.isNotEmpty &&
        onFileRemoved != null &&
        (isLocalOnly || isLocalOnlyContext)) {
      onFileRemoved(file);
    }
    return;
  }
  final String bodyHighlight = l10n.singleFileDeleteHighlight;
  late final String body;
  if (isBothLocalAndRemote) {
    body = l10n.singleFileInBothLocalAndRemote(fileType: fileType);
  } else if (isRemoteOnly) {
    body = l10n.singleFileInRemoteOnly(fileType: fileType);
  } else if (isLocalOnly) {
    body = l10n.singleFileDeleteFromDevice(fileType: fileType);
  } else {
    throw AssertionError("Unexpected state");
  }

  final deletePreference = isLocalOnly
      ? DeletePreference.DeleteFromLocalOnly
      : isRemoteOnly
      ? DeletePreference.DeleteFromRemoteOnly
      : localSettings.getDeletePreference() ?? DeletePreference.DeleteFromBoth;
  var isMoreOptionsShown = false;
  var isSetAsDefaultSelected = false;
  final actionResult = await showBottomSheetComponent<ButtonResult>(
    context: context,
    useRootNavigator: Platform.isIOS,
    builder: (sheetContext) => StatefulBuilder(
      builder: (builderContext, setState) => BottomSheetComponent(
        title: l10n.deleteFileQuestion(fileType: fileType),
        illustration: Image.asset("assets/warning-red.png"),
        closeTooltip: l10n.close,
        content: Text(
          isLocalOnly ? body : "$body\n$bodyHighlight",
          textAlign: TextAlign.center,
          style: TextStyles.body.copyWith(
            color: builderContext.componentColors.textLight,
          ),
        ),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        contentSpacing: Spacing.sm,
        actionsTopSpacing: Spacing.xxl,
        actions: [
          if (isMoreOptionsShown) ...[
            ButtonComponent(
              label: l10n.deleteFromDevice,
              variant: ButtonComponentVariant.secondary,
              onTap: () => _runSingleFileDeleteAction(
                builderContext,
                () async {
                  if (isSetAsDefaultSelected) {
                    await localSettings.setDeletePreference(
                      .DeleteFromLocalOnly,
                    );
                  }
                  final deleted = await deleteFilesOnDeviceOnly(context, [
                    file,
                  ]);
                  return deleted.isNotEmpty;
                },
                afterPop: (didDelete) {
                  if (didDelete && isLocalOnlyContext) {
                    onFileRemoved?.call(file);
                  }
                },
              ),
            ),
            ButtonComponent(
              label: l10n.deleteFromEnte,
              variant: ButtonComponentVariant.secondary,
              onTap: () => _runSingleFileDeleteAction(
                builderContext,
                () async {
                  if (isSetAsDefaultSelected) {
                    await localSettings.setDeletePreference(
                      .DeleteFromRemoteOnly,
                    );
                  }
                  await deleteFilesFromRemoteOnly(builderContext, [file]);
                  return true;
                },
                afterPop: (didDelete) {
                  if (didDelete) {
                    showShortToast(builderContext, l10n.movedToTrash);
                    if (!isLocalOnlyContext) {
                      onFileRemoved?.call(file);
                    }
                  }
                },
              ),
            ),
            ButtonComponent(
              label: l10n.deleteFromBoth,
              variant: ButtonComponentVariant.critical,
              onTap: () => _runSingleFileDeleteAction(
                builderContext,
                () async {
                  if (isSetAsDefaultSelected) {
                    await localSettings.setDeletePreference(.DeleteFromBoth);
                  }
                  await deleteFilesFromEverywhere(builderContext, [file]);
                  return true;
                },
                afterPop: (didDelete) {
                  if (didDelete) {
                    showShortToast(builderContext, l10n.movedToTrash);
                    onFileRemoved?.call(file);
                  }
                },
              ),
            ),
          ] else
            ButtonComponent(
              key: ValueKey(
                'singleFileDelete.default.${deletePreference.name}',
              ),
              label: deletePreference == .DeleteFromBoth
                  ? l10n.deleteFromBoth
                  : deletePreference == .DeleteFromLocalOnly
                  ? l10n.deleteFromDevice
                  : l10n.deleteFromEnte,
              variant: ButtonComponentVariant.critical,
              onTap: () => _runSingleFileDeleteAction(
                sheetContext,
                () async {
                  if (deletePreference == .DeleteFromRemoteOnly) {
                    await deleteFilesFromRemoteOnly(context, [file]);
                    return true;
                  } else if (deletePreference == .DeleteFromLocalOnly) {
                    final deleted = await deleteFilesOnDeviceOnly(context, [
                      file,
                    ]);
                    return deleted.isNotEmpty;
                  } else if (deletePreference == .DeleteFromBoth) {
                    await deleteFilesFromEverywhere(context, [file]);
                    return true;
                  }
                  return false;
                },
                afterPop: (didDelete) async {
                  if (deletePreference == .DeleteFromRemoteOnly) {
                    if (didDelete && !isLocalOnlyContext) {
                      onFileRemoved?.call(file);
                    }
                  } else if (deletePreference == .DeleteFromLocalOnly) {
                    if (didDelete && isLocalOnlyContext) {
                      onFileRemoved?.call(file);
                    }
                  } else if (deletePreference == .DeleteFromBoth) {
                    if (didDelete) {
                      onFileRemoved?.call(file);
                    }
                  }
                },
              ),
            ),
          if (isBothLocalAndRemote)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: isMoreOptionsShown
                  ? Center(
                      child: LabeledControlComponent(
                        foreground: context.componentColors.textLight,
                        onTap: () {
                          setState(() {
                            isSetAsDefaultSelected = !isSetAsDefaultSelected;
                          });
                        },
                        control: CheckboxComponent(
                          selected: isSetAsDefaultSelected,
                          onChanged: (value) {
                            setState(() {
                              isSetAsDefaultSelected = value;
                            });
                          },
                        ),
                        label: l10n.setAsDefault,
                      ),
                    )
                  : MoreOptionsButton(
                      label: l10n.moreOptions,
                      onTap: () {
                        setState(() {
                          isMoreOptionsShown = true;
                        });
                      },
                    ),
            ),
        ],
      ),
    ),
  );

  if (actionResult?.action != null &&
      actionResult!.action == ButtonAction.error) {
    await showGenericErrorDialog(
      context: context,
      error: actionResult.exception,
    );
  }
}

Future<void> _runSingleFileDeleteAction(
  BuildContext context,
  Future<bool> Function() onDelete, {
  FutureOr<void> Function(bool didDelete)? afterPop,
}) async {
  try {
    final didDelete = await onDelete();
    if (context.mounted) {
      Navigator.of(context).pop();
      await afterPop?.call(didDelete);
    }
  } catch (error) {
    if (context.mounted) {
      Navigator.of(
        context,
      ).pop(ButtonResult(ButtonAction.error, _toException(error)));
    }
    rethrow;
  }
}

Exception _toException(Object error) {
  return error is Exception ? error : Exception(error.toString());
}

Future<void> showDetailsSheet(BuildContext context, EnteFile file) async {
  if (file.canEditMetaInfo && file.isPanorama() == null) {
    guardedCheckPanorama(file).ignore();
  }
  Bus.instance.fire(
    DetailsSheetEvent(
      localID: file.localID,
      uploadedFileID: file.uploadedFileID,
      opened: true,
    ),
  );
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DraggableDetailsSheet(file: file),
  );
  Bus.instance.fire(
    DetailsSheetEvent(
      localID: file.localID,
      uploadedFileID: file.uploadedFileID,
      opened: false,
    ),
  );
}

class _DraggableDetailsSheet extends StatefulWidget {
  final EnteFile file;
  const _DraggableDetailsSheet({required this.file});

  @override
  State<_DraggableDetailsSheet> createState() => _DraggableDetailsSheetState();
}

class _DraggableDetailsSheetState extends State<_DraggableDetailsSheet> {
  final _sheetController = DraggableScrollableController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetSizeChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetSizeChanged() {
    final isNowExpanded = _sheetController.size >= 0.75;
    if (isNowExpanded != _isExpanded) {
      setState(() {
        _isExpanded = isNowExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 60;
    final disableSnap = isKeyboardOpen || _isExpanded;
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: disableSnap ? 0.95 : 0.75,
      minChildSize: disableSnap ? 0.75 : 0.5,
      maxChildSize: 0.95,
      snap: !disableSnap,
      snapSizes: disableSnap ? null : const [0.75],
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: getEnteColorScheme(context).backgroundElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: FileDetailsWidget(
          widget.file,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
