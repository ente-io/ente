import "dart:async";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import "package:photos/services/face_ml/face_ml_service.dart";
import "package:photos/services/face_ml/feedback/cluster_feedback.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/local_settings.dart";
import 'package:photos/utils/toast_util.dart';

class FaceDebugSectionWidget extends StatefulWidget {
  const FaceDebugSectionWidget({Key? key}) : super(key: key);

  @override
  State<FaceDebugSectionWidget> createState() => _FaceDebugSectionWidgetState();
}

class _FaceDebugSectionWidgetState extends State<FaceDebugSectionWidget> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        // Your state update logic here
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Face Beta",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.bug_report_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final Logger _logger = Logger("FaceDebugSectionWidget");
    return Column(
      children: [
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<Set<int>>(
            future: FaceMLDataDB.instance.getIndexedFileIds(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CaptionedTextWidget(
                  title: LocalSettings.instance.isFaceIndexingEnabled
                      ? "Disable Indexing (${snapshot.data!.length})"
                      : "Enable indexing (${snapshot.data!.length})",
                );
              }
              return const SizedBox.shrink();
            },
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final isEnabled =
                  await LocalSettings.instance.toggleFaceIndexing();
              if (isEnabled) {
                FaceMlService.instance.indexAllImages().ignore();
              } else {
                FaceMlService.instance.pauseIndexing();
              }
              if (mounted) {
                setState(() {});
              }
            } catch (e, s) {
              _logger.warning('indexing failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Run Clustering",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await FaceMlService.instance.clusterAllImages(minFaceScore: 0.75);
            Bus.instance.fire(PeopleChangedEvent());
            showShortToast(context, "Done");
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset feedback & labels",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await FaceMLDataDB.instance.resetClusterIDs();
            await FaceMLDataDB.instance.dropClustersAndPeople();
            Bus.instance.fire(PeopleChangedEvent());
            showShortToast(context, "Done");
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Drop embeddings & feedback",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await showChoiceDialog(
              context,
              title: "Are you sure?",
              body:
                  "You will need to again re-index all the faces. You can drop feedback if you want to label again",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                await FaceMLDataDB.instance.dropClustersAndPeople(faces: true);
                Bus.instance.fire(PeopleChangedEvent());
                showShortToast(context, "Done");
              },
            );
          },
        ),
        if (kDebugMode) sectionOptionSpacing,
        if (kDebugMode)
          MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Pull Embeddings From Local",
            ),
            pressedColor: getEnteColorScheme(context).fillFaint,
            trailingIcon: Icons.chevron_right_outlined,
            trailingIconIsMuted: true,
            onTap: () async {
              try {
                final List<Person> persons =
                    await FaceMLDataDB.instance.getPeople();
                final EnteWatch w = EnteWatch('feedback')..start();
                for (final Person p in persons) {
                  await ClusterFeedbackService.instance
                      .getSuggestionsUsingMean(p);
                  w.logAndReset('suggestion calculated for ${p.attr.name}');
                }
                w.log("done with feedback");
                showShortToast(context, "done avg");
                // await FaceMLDataDB.instance.bulkInsertFaces([]);
                // final EnteWatch watch = EnteWatch("face_time")..start();

                // final results = await downloadZip();
                // watch.logAndReset('downloaded and de-serialized');
                // await FaceMLDataDB.instance.bulkInsertFaces(results);
                // watch.logAndReset('inserted in to db');
                // showShortToast(context, "Got ${results.length} results");
              } catch (e, s) {
                _logger.warning('download failed ', e, s);
                await showGenericErrorDialog(context: context, error: e);
              }
              // _showKeyAttributesDialog(context);
            },
          ),
        if (kDebugMode) sectionOptionSpacing,
        if (kDebugMode)
          MenuItemWidget(
            captionedTextWidget: FutureBuilder<Set<int>>(
              future: FaceMLDataDB.instance.getIndexedFileIds(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CaptionedTextWidget(
                    title: "Read embeddings for ${snapshot.data!.length} files",
                  );
                }
                return const CaptionedTextWidget(
                  title: "Loading...",
                );
              },
            ),
            pressedColor: getEnteColorScheme(context).fillFaint,
            trailingIcon: Icons.chevron_right_outlined,
            trailingIconIsMuted: true,
            onTap: () async {
              final EnteWatch watch = EnteWatch("read_embeddings")..start();
              final result = await FaceMLDataDB.instance.getFaceEmbeddingMap();
              watch.logAndReset('read embeddings ${result.length} ');
              showShortToast(
                context,
                "Done in ${watch.elapsed.inSeconds} secs",
              );
            },
          ),
      ],
    );
  }
}
