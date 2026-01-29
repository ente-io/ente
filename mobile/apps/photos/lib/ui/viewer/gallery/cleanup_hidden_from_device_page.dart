import "dart:ui";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/hidden_service.dart";
import "package:photos/ui/common/bottom_shadow.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/empty_state.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart";
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
    final filesAreSelected = _selectedFiles.files.isNotEmpty;

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
      enableFileGrouping: false,
      emptyState: EmptyState(
        text: AppLocalizations.of(context).noHiddenFilesOnDevice,
      ),
    );

    return GalleryBoundariesProvider(
      child: GalleryFilesState(
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: GalleryAppBarWidget(
              GalleryType.cleanupHiddenFromDevice,
              AppLocalizations.of(context).deleteOnDeviceFiles,
              _selectedFiles,
            ),
          ),
          body: SelectionState(
            selectedFiles: _selectedFiles,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                gallery,
                const BottomShadowWidget(
                  offsetDy: 20,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: filesAreSelected ? 0 : 80,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: filesAreSelected ? 0.0 : 1.0,
                    curve: Curves.easeIn,
                    child: IgnorePointer(
                      ignoring: filesAreSelected,
                      child: SafeArea(
                        minimum: const EdgeInsets.only(bottom: 6),
                        child: _deleteAllButton(context),
                      ),
                    ),
                  ),
                ),
                FileSelectionOverlayBar(
                  GalleryType.cleanupHiddenFromDevice,
                  _selectedFiles,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteAllButton(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: _deleteAll,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 101, 101, 0.2),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16,
                    ),
                    child: Text(
                      AppLocalizations.of(context).deleteAll,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: const Color.fromRGBO(255, 101, 101, 1),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteAll() async {
    final allFiles = await CollectionsService.instance.getHiddenFilesOnDevice();
    if (allFiles.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: l10n.deleteAll,
          buttonType: ButtonType.critical,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          isInAlert: true,
          onTap: () async {
            try {
              await deleteFilesOnDeviceOnly(context, allFiles);
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
      body: l10n.deleteFromDeviceConfirmation(count: allFiles.length),
      actionSheetType: ActionSheetType.defaultActionSheet,
    );

    if (actionResult?.action == ButtonAction.first) {
      widget.onCleanupComplete?.call();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
