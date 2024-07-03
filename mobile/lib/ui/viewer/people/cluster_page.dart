import "dart:async";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/model/person.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/cluster_app_bar.dart";
import "package:photos/ui/viewer/people/people_banner.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";

class ClusterPage extends StatefulWidget {
  final List<EnteFile> searchResult;
  final bool enableGrouping;
  final String tagPrefix;
  final int clusterID;
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
    Key? key,
  }) : super(key: key);

  @override
  State<ClusterPage> createState() => _ClusterPageState();
}

class _ClusterPageState extends State<ClusterPage> {
  final _selectedFiles = SelectedFiles();
  late final List<EnteFile> files;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  late final StreamSubscription<PeopleChangedEvent> _peopleChangedEvent;

  bool get showNamingBanner =>
      (!userDismissedNamingBanner && widget.showNamingBanner);

  bool userDismissedNamingBanner = false;

  @override
  void initState() {
    super.initState();
    ClusterFeedbackService.setLastViewedClusterID(widget.clusterID);
    files = widget.searchResult;
    _filesUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromDevice ||
          event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (var updatedFile in event.updatedFiles) {
          files.remove(updatedFile);
        }
        setState(() {});
      }
    });
    _peopleChangedEvent = Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.removedFilesFromCluster &&
          (event.source == widget.clusterID.toString())) {
        for (var updatedFile in event.relevantFiles!) {
          files.remove(updatedFile);
        }
        setState(() {});
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
      initialFiles: [widget.searchResult.first],
    );
    return Scaffold(
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
      body: Column(
        children: [
          Expanded(
            child: SelectionState(
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
          showNamingBanner
              ? SafeArea(
                  child: Dismissible(
                    key: const Key("namingBanner"),
                    direction: DismissDirection.horizontal,
                    onDismissed: (direction) {
                      setState(() {
                        userDismissedNamingBanner = true;
                      });
                    },
                    child: PeopleBanner(
                      type: PeopleBannerType.addName,
                      faceWidget: PersonFaceWidget(
                        files.first,
                        clusterID: widget.clusterID,
                      ),
                      actionIcon: Icons.add_outlined,
                      text: S.of(context).addAName,
                      subText: S.of(context).findPeopleByName,
                      onTap: () async {
                        if (widget.personID == null) {
                          final result = await showAssignPersonAction(
                            context,
                            clusterID: widget.clusterID,
                          );
                          if (result != null &&
                              result is (PersonEntity, EnteFile)) {
                            Navigator.pop(context);
                            // ignore: unawaited_futures
                            routeToPage(context, PeoplePage(person: result.$1));
                          } else if (result != null && result is PersonEntity) {
                            Navigator.pop(context);
                            // ignore: unawaited_futures
                            routeToPage(context, PeoplePage(person: result));
                          }
                        } else {
                          showShortToast(context, "No personID or clusterID");
                        }
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
