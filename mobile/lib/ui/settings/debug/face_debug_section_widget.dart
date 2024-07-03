import "dart:async";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import 'package:photos/services/machine_learning/face_ml/face_ml_service.dart';
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
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
      title: "Faces Debug",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.bug_report_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final Logger _logger = Logger("FaceDebugSectionWidget");
    return Column(
      children: [
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<int>(
            future: FaceMLDataDB.instance.getIndexedFileCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CaptionedTextWidget(
                  title: LocalSettings.instance.isFaceIndexingEnabled
                      ? "Disable faces (${snapshot.data!} files done)"
                      : "Enable faces (${snapshot.data!} files done)",
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
              if (!isEnabled) {
                FaceMlService.instance.pauseIndexingAndClustering();
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
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: LocalSettings.instance.remoteFetchEnabled
                ? "Remote fetch enabled"
                : "Remote fetch disabled",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              await LocalSettings.instance.toggleRemoteFetch();
              if (mounted) {
                setState(() {});
              }
            } catch (e, s) {
              _logger.warning('Remote fetch toggle failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: FaceMlService.instance.debugIndexingDisabled
                ? "Debug enable indexing again"
                : "Debug disable indexing",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              FaceMlService.instance.debugIndexingDisabled =
                  !FaceMlService.instance.debugIndexingDisabled;
              if (FaceMlService.instance.debugIndexingDisabled) {
                FaceMlService.instance.pauseIndexingAndClustering();
              }
              if (mounted) {
                setState(() {});
              }
            } catch (e, s) {
              _logger.warning('debugIndexingDisabled toggle failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Run sync, indexing, clustering",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              FaceMlService.instance.debugIndexingDisabled = false;
              unawaited(FaceMlService.instance.runAllFaceML());
            } catch (e, s) {
              _logger.warning('indexAndClusterAll failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Run indexing",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              FaceMlService.instance.debugIndexingDisabled = false;
              unawaited(FaceMlService.instance.indexAllImages());
            } catch (e, s) {
              _logger.warning('indexing failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<double>(
            future: FaceMLDataDB.instance.getClusteredToIndexableFilesRatio(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CaptionedTextWidget(
                  title:
                      "Run clustering (${(100 * snapshot.data!).toStringAsFixed(0)}% done)",
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
              await PersonService.instance.fetchRemoteClusterFeedback();
              FaceMlService.instance.debugIndexingDisabled = false;
              await FaceMlService.instance
                  .clusterAllImages(clusterInBuckets: true);
              Bus.instance.fire(PeopleChangedEvent());
              showShortToast(context, "Done");
            } catch (e, s) {
              _logger.warning('clustering failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Check for mixed clusters",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final susClusters =
                  await ClusterFeedbackService.instance.checkForMixedClusters();
              for (final clusterinfo in susClusters) {
                Future.delayed(const Duration(seconds: 4), () {
                  showToast(
                    context,
                    'Cluster with ${clusterinfo.$2} photos is sus',
                  );
                });
              }
            } catch (e, s) {
              _logger.warning('Checking for mixed clusters failed', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Sync person mappings ",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              await PersonService.instance.reconcileClusters();
              Bus.instance.fire(PeopleChangedEvent());
              showShortToast(context, "Done");
            } catch (e, s) {
              _logger.warning('sync person mappings failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset feedback",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          alwaysShowSuccessState: true,
          onTap: () async {
            await showChoiceDialog(
              context,
              title: "Are you sure?",
              body:
                  "This will drop all people and their related feedback. It will keep clustering labels and embeddings untouched.",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  await FaceMLDataDB.instance.dropFeedbackTables();
                  Bus.instance.fire(PeopleChangedEvent());
                  showShortToast(context, "Done");
                } catch (e, s) {
                  _logger.warning('reset feedback failed ', e, s);
                  await showGenericErrorDialog(context: context, error: e);
                }
              },
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset feedback and clustering",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await showChoiceDialog(
              context,
              title: "Are you sure?",
              body:
                  "This will delete all people, their related feedback and clustering labels. It will keep embeddings untouched.",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  final List<PersonEntity> persons =
                      await PersonService.instance.getPersons();
                  for (final PersonEntity p in persons) {
                    await PersonService.instance.deletePerson(p.remoteID);
                  }
                  await FaceMLDataDB.instance.dropClustersAndPersonTable();
                  Bus.instance.fire(PeopleChangedEvent());
                  showShortToast(context, "Done");
                } catch (e, s) {
                  _logger.warning('peopleToPersonMapping remove failed ', e, s);
                  await showGenericErrorDialog(context: context, error: e);
                }
              },
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset everything (embeddings)",
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
                try {
                  await FaceMLDataDB.instance
                      .dropClustersAndPersonTable(faces: true);
                  Bus.instance.fire(PeopleChangedEvent());
                  showShortToast(context, "Done");
                } catch (e, s) {
                  _logger.warning('drop feedback failed ', e, s);
                  await showGenericErrorDialog(context: context, error: e);
                }
              },
            );
          },
        ),
      ],
    );
  }
}
