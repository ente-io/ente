import "dart:async";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_cluster_feedback_service.dart";
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/pet_face_widget.dart";
import "package:photos/ui/viewer/people/save_or_edit_pet.dart";

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
      if (mounted) setState(() {});
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
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final result = _files
            .where(
              (file) =>
                  file.creationTime! >= creationStartTime &&
                  file.creationTime! <= creationEndTime,
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
      tagPrefix: "pet_cluster_${widget.clusterId}",
      selectedFiles: _selectedFiles,
      enableFileGrouping: true,
      initialFiles: _files,
    );

    return GalleryBoundariesProvider(
      child: GalleryFilesState(
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: _editName,
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
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 16, color: colorScheme.strokeMuted),
                ],
              ),
            ),
            actions: [
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
                _PetSelectionBar(
                  selectedFiles: _selectedFiles,
                  clusterId: widget.clusterId,
                  species: widget.species,
                  allFiles: _files,
                  onFilesRemoved: (removed) {
                    for (final f in removed) {
                      _files.remove(f);
                    }
                    if (_files.isEmpty) {
                      Navigator.pop(context);
                    } else {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editName() async {
    final result = await routeToPage(
      context,
      SaveOrEditPet(
        clusterId: widget.clusterId,
        species: widget.species,
        currentName: _label,
      ),
    );
    if (result is String && result.isNotEmpty && mounted) {
      setState(() => _label = result);
    }
  }
}

/// Selection action bar for pet cluster: "Not this pet" and "Move to".
class _PetSelectionBar extends StatefulWidget {
  final SelectedFiles selectedFiles;
  final String clusterId;
  final int species;
  final List<EnteFile> allFiles;
  final void Function(List<EnteFile> removed) onFilesRemoved;

  const _PetSelectionBar({
    required this.selectedFiles,
    required this.clusterId,
    required this.species,
    required this.allFiles,
    required this.onFilesRemoved,
  });

  @override
  State<_PetSelectionBar> createState() => _PetSelectionBarState();
}

class _PetSelectionBarState extends State<_PetSelectionBar> {
  final ValueNotifier<bool> _hasSelection = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.selectedFiles.addListener(_listener);
  }

  @override
  void dispose() {
    widget.selectedFiles.removeListener(_listener);
    _hasSelection.dispose();
    super.dispose();
  }

  void _listener() {
    _hasSelection.value = widget.selectedFiles.files.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _hasSelection,
      builder: (context, hasSelection, _) {
        if (!hasSelection) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.backgroundElevated2,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _removeFromCluster,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: Text(l10n.notThisPet, style: textTheme.small),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _moveToCluster,
                    icon: const Icon(Icons.drive_file_move_outline, size: 18),
                    label: Text(l10n.moveTo, style: textTheme.small),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeFromCluster() async {
    final selected = widget.selectedFiles.files.toList();
    if (selected.isEmpty) return;

    final fileIds =
        selected.map((f) => f.uploadedFileID).whereType<int>().toList();

    await PetClusterFeedbackService.instance.removePetFacesFromCluster(
      fileIds,
      widget.clusterId,
    );
    widget.selectedFiles.clearAll();
    widget.onFilesRemoved(selected);
  }

  Future<void> _moveToCluster() async {
    final selected = widget.selectedFiles.files.toList();
    if (selected.isEmpty) return;

    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final clusters = await mlDataDB.getAllPetClustersWithInfo();
    // Filter out current cluster
    final otherClusters =
        clusters.where((c) => c.$1 != widget.clusterId).toList();

    if (!mounted) return;

    final targetClusterId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PetClusterPicker(
        clusters: otherClusters,
        currentClusterId: widget.clusterId,
      ),
    );

    if (targetClusterId == null || !mounted) return;

    final fileIds =
        selected.map((f) => f.uploadedFileID).whereType<int>().toList();

    await PetClusterFeedbackService.instance.movePetFacesToCluster(
      fileIds,
      widget.clusterId,
      targetClusterId,
    );
    widget.selectedFiles.clearAll();
    widget.onFilesRemoved(selected);
  }
}

/// Bottom sheet picker for selecting a target pet cluster.
class _PetClusterPicker extends StatelessWidget {
  final List<(String, int, int, String?)> clusters;
  final String currentClusterId;

  const _PetClusterPicker({
    required this.clusters,
    required this.currentClusterId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = getEnteTextTheme(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.moveTo, style: textTheme.largeBold),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: clusters.length,
              itemBuilder: (context, index) {
                final (clusterId, species, count, name) = clusters[index];
                final speciesLabel = species == 0
                    ? l10n.dog
                    : species == 1
                        ? l10n.cat
                        : "Pet";
                final label =
                    (name != null && name.isNotEmpty) ? name : speciesLabel;
                return ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: FaceThumbnailSquircleClip(
                      child: PetFaceWidget(petClusterId: clusterId),
                    ),
                  ),
                  title: Text(label),
                  subtitle: Text("$count photos"),
                  onTap: () => Navigator.pop(context, clusterId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
