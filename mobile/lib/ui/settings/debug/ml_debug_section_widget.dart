import "dart:async";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/face_ml/face_recognition_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import 'package:photos/services/machine_learning/ml_service.dart';
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/ml_util.dart";
import 'package:photos/utils/toast_util.dart';

class MLDebugSectionWidget extends StatefulWidget {
  const MLDebugSectionWidget({super.key});

  @override
  State<MLDebugSectionWidget> createState() => _MLDebugSectionWidgetState();
}

class _MLDebugSectionWidgetState extends State<MLDebugSectionWidget> {
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
      title: "ML Debug",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.bug_report_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final Logger logger = Logger("MLDebugSectionWidget");
    return Column(
      children: [
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<IndexStatus>(
            future: getIndexStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final IndexStatus status = snapshot.data!;
                return CaptionedTextWidget(
                  title: localSettings.isMLIndexingEnabled
                      ? "Disable ML (${status.indexedItems} files indexed)"
                      : "Enable ML (${status.indexedItems} files indexed)",
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
              final isEnabled = await localSettings.toggleMLIndexing();
              if (isEnabled) {
                await MLService.instance.init();
                await SemanticSearchService.instance.init();
                unawaited(MLService.instance.runAllML(force: true));
              } else {
                MLService.instance.pauseIndexingAndClustering();
              }
              if (mounted) {
                setState(() {});
              }
            } catch (e, s) {
              logger.warning('indexing failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: localSettings.remoteFetchEnabled
                ? "Disable remote fetch"
                : "Enable remote fetch",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              await localSettings.toggleRemoteFetch();
              if (mounted) {
                setState(() {});
              }
            } catch (e, s) {
              logger.warning('Remote fetch toggle failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: MLService.instance.debugIndexingDisabled
                ? "Enable auto indexing (debug)"
                : "Disable auto indexing (debug)",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              MLService.instance.debugIndexingDisabled =
                  !MLService.instance.debugIndexingDisabled;
              if (MLService.instance.debugIndexingDisabled) {
                MLService.instance.pauseIndexingAndClustering();
              } else {
                unawaited(MLService.instance.runAllML());
              }
              if (mounted) {
                setState(() {});
              }
            } catch (e, s) {
              logger.warning('debugIndexingDisabled toggle failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Trigger run ML",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              MLService.instance.debugIndexingDisabled = false;
              unawaited(MLService.instance.runAllML());
            } catch (e, s) {
              logger.warning('indexAndClusterAll failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Trigger run indexing",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              MLService.instance.debugIndexingDisabled = false;
              unawaited(MLService.instance.indexAllImages());
            } catch (e, s) {
              logger.warning('indexing failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<double>(
            future: MLDataDB.instance.getClusteredToIndexableFilesRatio(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CaptionedTextWidget(
                  title:
                      "Trigger clustering (${(100 * snapshot.data!).toStringAsFixed(0)}% done)",
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
              MLService.instance.debugIndexingDisabled = false;
              await MLService.instance.clusterAllImages();
              Bus.instance.fire(PeopleChangedEvent());
              showShortToast(context, "Done");
            } catch (e, s) {
              logger.warning('clustering failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        // sectionOptionSpacing,
        // MenuItemWidget(
        //   captionedTextWidget: const CaptionedTextWidget(
        //     title: "Check for mixed clusters",
        //   ),
        //   pressedColor: getEnteColorScheme(context).fillFaint,
        //   trailingIcon: Icons.chevron_right_outlined,
        //   trailingIconIsMuted: true,
        //   onTap: () async {
        //     try {
        //       final susClusters =
        //           await ClusterFeedbackService.instance.checkForMixedClusters();
        //       for (final clusterinfo in susClusters) {
        //         Future.delayed(const Duration(seconds: 4), () {
        //           showToast(
        //             context,
        //             'Cluster with ${clusterinfo.$2} photos is sus',
        //           );
        //         });
        //       }
        //     } catch (e, s) {
        //       logger.warning('Checking for mixed clusters failed', e, s);
        //       await showGenericErrorDialog(context: context, error: e);
        //     }
        //   },
        // ),
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
              await FaceRecognitionService.instance.sync();
              showShortToast(context, "Done");
            } catch (e, s) {
              logger.warning('sync person mappings failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Show empty indexes",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final emptyFaces = await MLDataDB.instance.getErroredFaceCount();
            showShortToast(context, '$emptyFaces empty faces');
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset faces feedback",
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
                  "This will drop all people and their related feedback stored locally. It will keep clustering labels and embeddings untouched, as well as persons stored on remote.",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  await MLDataDB.instance.dropFacesFeedbackTables();
                  Bus.instance.fire(PeopleChangedEvent());
                  showShortToast(context, "Done");
                } catch (e, s) {
                  logger.warning('reset feedback failed ', e, s);
                  await showGenericErrorDialog(context: context, error: e);
                }
              },
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset faces feedback and clustering",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await showChoiceDialog(
              context,
              title: "Are you sure?",
              body:
                  "This will delete all people (also from remote), their related feedback and clustering labels. It will keep embeddings untouched.",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  final List<PersonEntity> persons =
                      await PersonService.instance.getPersons();
                  for (final PersonEntity p in persons) {
                    await PersonService.instance.deletePerson(p.remoteID);
                  }
                  await MLDataDB.instance.dropClustersAndPersonTable();
                  Bus.instance.fire(PeopleChangedEvent());
                  showShortToast(context, "Done");
                } catch (e, s) {
                  logger.warning('peopleToPersonMapping remove failed ', e, s);
                  await showGenericErrorDialog(context: context, error: e);
                }
              },
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset all local faces",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await showChoiceDialog(
              context,
              title: "Are you sure?",
              body:
                  "This will drop all local faces data. You will need to again re-index faces.",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  await MLDataDB.instance
                      .dropClustersAndPersonTable(faces: true);
                  Bus.instance.fire(PeopleChangedEvent());
                  showShortToast(context, "Done");
                } catch (e, s) {
                  logger.warning('drop feedback failed ', e, s);
                  await showGenericErrorDialog(context: context, error: e);
                }
              },
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset all local clip",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await showChoiceDialog(
              context,
              title: "Are you sure?",
              body:
                  "You will need to again re-index or fetch all clip image embeddings.",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  await SemanticSearchService.instance.clearIndexes();
                  showShortToast(context, "Done");
                } catch (e, s) {
                  logger.warning('drop clip embeddings failed ', e, s);
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
