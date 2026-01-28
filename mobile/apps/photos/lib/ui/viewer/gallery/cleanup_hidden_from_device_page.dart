import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/hidden_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/gallery/empty_state.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/utils/delete_file_util.dart";
import "package:photos/utils/dialog_util.dart";

class CleanupHiddenFromDevicePage extends StatefulWidget {
  final VoidCallback? onCleanupComplete;

  const CleanupHiddenFromDevicePage({
    this.onCleanupComplete,
    super.key,
  });

  @override
  State<CleanupHiddenFromDevicePage> createState() =>
      _CleanupHiddenFromDevicePageState();
}

class _CleanupHiddenFromDevicePageState
    extends State<CleanupHiddenFromDevicePage> {
  final _selectedFiles = SelectedFiles();

  @override
  void initState() {
    super.initState();
    _selectedFiles.addListener(_onSelectionChange);
  }

  @override
  void dispose() {
    _selectedFiles.removeListener(_onSelectionChange);
    super.dispose();
  }

  void _onSelectionChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final files =
            await CollectionsService.instance.getHiddenFilesOnDevice();
        return FileLoadResult(files, false);
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {EventType.deletedFromDevice},
      tagPrefix: "cleanup_hidden_from_device",
      selectedFiles: _selectedFiles,
      inSelectionMode: true,
      enableFileGrouping: false,
      emptyState: EmptyState(
        text: AppLocalizations.of(context).noHiddenFilesOnDevice,
      ),
    );

    return GalleryBoundariesProvider(
      child: GalleryFilesState(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              AppLocalizations.of(context).deleteHiddenFilesFromDevice,
              style: textTheme.h3Bold,
            ),
            actions: [
              if (_selectedFiles.files.isNotEmpty)
                TextButton(
                  onPressed: _deleteSelected,
                  child: Text(
                    "${AppLocalizations.of(context).delete} (${_selectedFiles.files.length})",
                    style: textTheme.bodyBold.copyWith(
                      color: colorScheme.primary500,
                    ),
                  ),
                ),
            ],
          ),
          body: SelectionState(
            selectedFiles: _selectedFiles,
            child: gallery,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final count = _selectedFiles.files.length;
    final l10n = AppLocalizations.of(context);

    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: l10n.deleteSelectedFromDevice,
          buttonType: ButtonType.critical,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          isInAlert: true,
          onTap: () async {
            try {
              final filesToDelete = _selectedFiles.files.toList();
              await deleteFilesOnDeviceOnly(context, filesToDelete);
              _selectedFiles.clearAll();
            } catch (e) {
              if (context.mounted) {
                await showGenericErrorDialog(context: context, error: e);
              }
              rethrow;
            }
          },
        ),
        ButtonWidget(
          labelText: l10n.cancel,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
        ),
      ],
      title: l10n.deleteFromDevice,
      body: l10n.deleteFromDeviceConfirmation(count: count),
      actionSheetType: ActionSheetType.defaultActionSheet,
    );

    if (actionResult?.action == ButtonAction.first) {
      widget.onCleanupComplete?.call();
    }
  }
}
