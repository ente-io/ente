import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/face/model/person.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/ui/components/notification_widget.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/people/add_person_action_sheet.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";

class ClusterPage extends StatefulWidget {
  final List<EnteFile> searchResult;
  final bool enableGrouping;
  final String tagPrefix;
  final int cluserID;
  final Person? personID;

  static const GalleryType appBarType = GalleryType.cluster;
  static const GalleryType overlayType = GalleryType.cluster;

  const ClusterPage(
    this.searchResult, {
    this.enableGrouping = true,
    this.tagPrefix = "",
    required this.cluserID,
    this.personID,
    Key? key,
  }) : super(key: key);

  @override
  State<ClusterPage> createState() => _ClusterPageState();
}

class _ClusterPageState extends State<ClusterPage> {
  final _selectedFiles = SelectedFiles();
  late final List<EnteFile> files;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
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
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.tagPrefix + widget.tagPrefix,
      selectedFiles: _selectedFiles,
      enableFileGrouping: widget.enableGrouping,
      initialFiles: [widget.searchResult.first],
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          SearchResultPage.appBarType,
          widget.personID != null
              ? widget.personID!.attr.name
              : "${widget.searchResult.length} memories",
          _selectedFiles,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          RepaintBoundary(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: NotificationWidget(
                startIcon: Icons.person_add_outlined,
                actionIcon: Icons.add_outlined,
                  text: S.of(context).addAName,
                subText:S.of(context).findPeopleByName,
                // text: S.of(context).addAName,
                // subText: S.of(context).findPersonsByName,
                type: NotificationType.greenBanner,
                onTap: () async {
                  if (widget.personID == null) {
                    final result = await showAssignPersonAction(
                      context,
                      clusterID: widget.cluserID,
                    );
                    if (result != null && result is Person) {
                      Navigator.pop(context);
                      // ignore: unawaited_futures
                      routeToPage(context, PeoplePage(person: result));
                    }
                  } else {
                    showShortToast(context, "No personID or clusterID");
                  }
                },
              ),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 1000.ms,
                  delay: 3200.ms,
                  size: 0.6,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                gallery,
                FileSelectionOverlayBar(
                  ClusterPage.overlayType,
                  _selectedFiles,
                  clusterID: widget.cluserID,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
