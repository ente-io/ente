import "dart:async";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/offline_files_db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/popup_item.dart";
import "package:photos/ui/components/buttons/button_widget.dart"
    show ButtonAction;
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/merge_pet_sheet.dart";
import "package:photos/ui/viewer/people/pet_clusters_page.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";
import "package:photos/ui/viewer/people/save_or_edit_pet.dart";
import "package:photos/ui/viewer/people/save_person_banner.dart";
import "package:photos/utils/dialog_util.dart";

/// Detail page for a pet cluster with gallery, name editing, and reassignment.
class PetClusterPage extends StatefulWidget {
  final String clusterId;
  final String clusterLabel;
  final List<EnteFile> files;
  final int species;

  const PetClusterPage({
    required this.clusterId,
    required this.clusterLabel,
    required this.files,
    required this.species,
    super.key,
  });

  @override
  State<PetClusterPage> createState() => _PetClusterPageState();
}

class _PetClusterPageState extends State<PetClusterPage> {
  final _selectedFiles = SelectedFiles();
  late List<EnteFile> _files;
  late String _label;
  bool _isBannerDismissed = false;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdated;
  late final StreamSubscription<PetsChangedEvent> _petsChanged;

  @override
  void initState() {
    super.initState();
    _files = List<EnteFile>.from(widget.files)
      ..sort((a, b) => (b.creationTime ?? 0).compareTo(a.creationTime ?? 0));
    _label = widget.clusterLabel;
    _filesUpdated = Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (final f in event.updatedFiles) {
          _files.remove(f);
        }
        setState(() {});
      }
    });
    _petsChanged = Bus.instance.on<PetsChangedEvent>().listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadClusterFiles();
      });
    });
  }

  Future<void> _reloadClusterFiles() async {
    if (!mounted) return;
    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;

    // Load files from all clusters sharing the same pet (after merge).
    final clusterToPetId = await mlDataDB.getClusterToPetId();
    final petId = clusterToPetId[widget.clusterId];
    final allFileIds = <int>[];
    if (petId != null) {
      final siblingClusters = clusterToPetId.entries
          .where((e) => e.value == petId)
          .map((e) => e.key);
      for (final cid in siblingClusters) {
        allFileIds.addAll(await mlDataDB.getPetFileIdsForCluster(cid));
      }
    } else {
      allFileIds
          .addAll(await mlDataDB.getPetFileIdsForCluster(widget.clusterId));
    }
    final fileIds = allFileIds.toSet().toList();
    if (fileIds.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final List<EnteFile> files;
    if (isOfflineMode) {
      final localIdMap =
          await OfflineFilesDB.instance.getLocalIdsForIntIds(fileIds.toSet());
      final localIds = localIdMap.values.toList();
      files = localIds.isEmpty
          ? []
          : await FilesDB.instance.getLocalFiles(localIds);
    } else {
      files = await FilesDB.instance
          .getFilesFromIDs(fileIds, dedupeByUploadId: true);
    }

    if (!mounted) return;
    // Deduplicate by generatedID to avoid duplicate-key errors in Gallery.
    final seen = <int>{};
    final dedupedFiles = <EnteFile>[];
    for (final f in files) {
      if (seen.add(f.generatedID ?? 0)) {
        dedupedFiles.add(f);
      }
    }
    setState(() {
      _files = dedupedFiles
        ..sort(
          (a, b) => (b.creationTime ?? 0).compareTo(a.creationTime ?? 0),
        );
    });
  }

  @override
  void dispose() {
    _filesUpdated.cancel();
    _petsChanged.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    final bool showBanner = !_isBannerDismissed &&
        !isOfflineMode &&
        _files.isNotEmpty &&
        (widget.clusterLabel.isEmpty ||
            widget.clusterLabel.startsWith("Dog") ||
            widget.clusterLabel.startsWith("Cat") ||
            widget.clusterLabel.startsWith("Pet"));

    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final result = _files
            .where(
              (file) =>
                  (file.creationTime ?? 0) >= creationStartTime &&
                  (file.creationTime ?? 0) <= creationEndTime,
            )
            .toList();
        return Future.value(
          FileLoadResult(result, result.length < _files.length),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      forceReloadEvents: [Bus.instance.on<PetsChangedEvent>()],
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      selectedFiles: _selectedFiles,
      tagPrefix: "pet_cluster_${widget.clusterId}",
      enableFileGrouping: true,
      initialFiles: _files,
      header: showBanner
          ? SavePersonBanner(
              faceWidget: PetFaceWidget(petClusterId: widget.clusterId),
              text: l10n.savePet,
              subText: l10n.findThemQuickly,
              primaryActionLabel: l10n.save,
              secondaryActionLabel: l10n.merge,
              onPrimaryTap: () => _editName(),
              onSecondaryTap: () => _handleMergePet(),
              onDismissed: () => setState(() => _isBannerDismissed = true),
              dismissibleKey: ValueKey("pet_banner_${widget.clusterId}"),
            )
          : null,
    );

    return GalleryBoundariesProvider(
      child: GalleryFilesState(
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: isOfflineMode ? null : _editName,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: FaceThumbnailSquircleClip(
                      child: PetFaceWidget(petClusterId: widget.clusterId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isOfflineMode) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: colorScheme.strokeMuted,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!isOfflineMode)
                PopupMenuButton<_PetClusterAction>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (action) {
                    switch (action) {
                      case _PetClusterAction.viewClusters:
                        _viewClusters();
                      case _PetClusterAction.ignore:
                        _ignorePet();
                    }
                  },
                  itemBuilder: (_) => [
                    EntePopupMenuItem(
                      l10n.viewClusters,
                      value: _PetClusterAction.viewClusters,
                      icon: Icons.account_tree_outlined,
                    ),
                    EntePopupMenuItem(
                      l10n.ignorePet,
                      value: _PetClusterAction.ignore,
                      icon: Icons.hide_image_outlined,
                    ),
                  ],
                ),
              Text(
                "${_files.length}",
                style: textTheme.body.copyWith(color: colorScheme.textMuted),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SelectionState(
            selectedFiles: _selectedFiles,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                gallery,
                FileSelectionOverlayBar(
                  GalleryType.petCluster,
                  _selectedFiles,
                  clusterID: widget.clusterId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editName() async {
    if (isOfflineMode) return;
    final result = await routeToPage(
      context,
      SaveOrEditPet(
        clusterId: widget.clusterId,
        species: widget.species,
        currentName: _label,
      ),
    );
    if (result is String && result.isNotEmpty && mounted) {
      setState(() {
        _label = result;
        _isBannerDismissed = true;
      });
    }
  }

  Future<void> _handleMergePet() async {
    if (isOfflineMode) return;
    final selection = await showMergePetPage(
      context,
      currentClusterId: widget.clusterId,
    );
    if (selection == null || !mounted) return;
    await PetService.instance.addClusterToExistingPet(
      petId: selection.petId,
      clusterID: widget.clusterId,
    );
    Navigator.of(context).pop();
  }

  Future<void> _ignorePet() async {
    if (isOfflineMode) return;
    final l10n = AppLocalizations.of(context);
    final result = await showChoiceDialog(
      context,
      title: l10n.areYouSureYouWantToIgnoreThisPet,
      body: l10n.thePetGroupsWillNotBeDisplayed,
      firstButtonLabel: l10n.confirm,
      firstButtonOnTap: () async {
        await PetService.instance
            .ignorePetCluster(widget.clusterId, widget.species);
      },
    );
    if (!mounted || result?.action != ButtonAction.first) return;
    Navigator.of(context).pop();
  }

  Future<void> _viewClusters() async {
    if (isOfflineMode) return;
    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final clusterToPetId = await mlDataDB.getClusterToPetId();
    final petId = clusterToPetId[widget.clusterId];
    if (petId == null || !mounted) return;
    await routeToPage(
      context,
      PetClustersPage(petId: petId, petName: _label),
    );
    await _reloadClusterFiles();
  }
}

enum _PetClusterAction { viewClusters, ignore }
