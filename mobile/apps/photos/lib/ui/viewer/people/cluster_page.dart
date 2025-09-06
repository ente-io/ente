import "dart:async";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/ui/notification/toast.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/cluster_app_bar.dart";
import "package:photos/ui/viewer/people/people_banner.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/utils/navigation_util.dart";

class ClusterPage extends StatefulWidget {
  final List<EnteFile> searchResult;
  final bool enableGrouping;
  final String tagPrefix;
  final String clusterID;
  final PersonEntity? personID;
  final String appendTitle;
  final bool showNamingBanner;

  static const GalleryType appBarType = GalleryType.cluster;
  static const GalleryType overlayType = GalleryType.cluster;

  const ClusterPage(
    this.searchResult, {
    this.enableGrouping = true,
    this.tagPrefix = "",
    required this.clusterID,
    this.personID,
    this.appendTitle = "",
    this.showNamingBanner = true,
    super.key,
  });

  @override
  State<ClusterPage> createState() => _ClusterPageState();
}

class _ClusterPageState extends State<ClusterPage> {
  final _selectedFiles = SelectedFiles();
  late final List<EnteFile> files;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  late final StreamSubscription<PeopleChangedEvent> _peopleChangedEvent;

  @override
  void initState() {
    super.initState();
    ClusterFeedbackService.setLastViewedClusterID(widget.clusterID);
    files = widget.searchResult;
    _filesUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (var updatedFile in event.updatedFiles) {
          files.remove(updatedFile);
        }
        setState(() {});
      }
    });
    _peopleChangedEvent = Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.source == widget.clusterID.toString()) {
        if (event.type == PeopleEventType.removedFilesFromCluster) {
          for (var updatedFile in event.relevantFiles!) {
            files.remove(updatedFile);
          }
          setState(() {});
        }
        if (event.type == PeopleEventType.removedFaceFromCluster) {
          for (final String removedFaceID in event.relevantFaceIDs!) {
            final int fileID = getFileIdFromFaceId<int>(removedFaceID);
            files.removeWhere((file) => file.uploadedFileID == fileID);
          }
          setState(() {});
        }
      }
    });
    kDebugMode
        ? ClusterFeedbackService.instance.debugLogClusterBlurValues(
            widget.clusterID,
            clusterSize: files.length,
          )
        : null;
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
    _peopleChangedEvent.cancel();
    if (ClusterFeedbackService.lastViewedClusterID == widget.clusterID) {
      ClusterFeedbackService.resetLastViewedClusterID();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final result = files
            .where(
              (file) =>
                  file.creationTime! >= creationStartTime &&
                  file.creationTime! <= creationEndTime,
            )
            .toList();
        return Future.value(
          FileLoadResult(
            result,
            result.length < files.length,
          ),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      forceReloadEvents: [Bus.instance.on<PeopleChangedEvent>()],
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
        EventType.peopleClusterChanged,
      },
      tagPrefix: widget.tagPrefix + widget.tagPrefix,
      selectedFiles: _selectedFiles,
      enableFileGrouping: widget.enableGrouping,
      initialFiles: widget.searchResult,
      header: widget.showNamingBanner && files.isNotEmpty
          ? PeopleBanner(
              type: PeopleBannerType.addName,
              faceWidget: PersonFaceWidget(
                clusterID: widget.clusterID,
              ),
              actionIcon: Icons.add_outlined,
              text: AppLocalizations.of(context).savePerson,
              subText: AppLocalizations.of(context).findThemQuickly,
              onTap: () async {
                if (widget.personID == null) {
                  final result = await showAssignPersonAction(
                    context,
                    clusterID: widget.clusterID,
                    file: files.isEmpty ? null : files.first,
                  );
                  if (result != null) {
                    Navigator.pop(context);
                    final person =
                        result is (PersonEntity, EnteFile) ? result.$1 : result;
                    routeToPage(
                      context,
                      PeoplePage(
                        person: person,
                        searchResult: null,
                      ),
                    ).ignore();
                  }
                } else {
                  showShortToast(context, "No personID or clusterID");
                }
              },
            )
          : null,
    );
    return GalleryFilesState(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: ClusterAppBar(
            SearchResultPage.appBarType,
            "${files.length} memories${widget.appendTitle}",
            _selectedFiles,
            widget.clusterID,
            key: ValueKey(files.length),
          ),
        ),
        body: SelectionState(
          selectedFiles: _selectedFiles,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              gallery,
              FileSelectionOverlayBar(
                ClusterPage.overlayType,
                _selectedFiles,
                clusterID: widget.clusterID,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
