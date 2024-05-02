import "dart:async";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/face/db.dart";
import "package:photos/face/model/person.dart";
import 'package:photos/services/machine_learning/face_ml/face_ml_service.dart';
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
          captionedTextWidget: FutureBuilder<int>(
            future: FaceMLDataDB.instance.getIndexedFileCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CaptionedTextWidget(
                  title: LocalSettings.instance.isFaceIndexingEnabled
                      ? "Disable indexing (${snapshot.data!})"
                      : "Enable indexing (${snapshot.data!})",
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
          captionedTextWidget: FutureBuilder<int>(
            future: FaceMLDataDB.instance.getIndexedFileCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return CaptionedTextWidget(
                  title: LocalSettings.instance.remoteFetchEnabled
                      ? "Remote fetch Enabled"
                      : "Remote fetch Disabled",
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
              await LocalSettings.instance.toggleRemoteFetch();
              if (mounted) {
                setState(() {});
              }
            } catch (e, s) {
              _logger.warning('indexing failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        // MenuItemWidget(
        //   captionedTextWidget: FutureBuilder<int>(
        //     future: FaceMLDataDB.instance.getTotalFaceCount(),
        //     builder: (context, snapshot) {
        //       if (snapshot.hasData) {
        //         return CaptionedTextWidget(
        //           title: "${snapshot.data!} high quality faces",
        //         );
        //       }
        //       return const SizedBox.shrink();
        //     },
        //   ),
        //   pressedColor: getEnteColorScheme(context).fillFaint,
        //   trailingIcon: Icons.chevron_right_outlined,
        //   trailingIconIsMuted: true,
        //   onTap: () async {
        //     final faces75 = await FaceMLDataDB.instance
        //         .getTotalFaceCount(minFaceScore: 0.75);
        //     final faces78 = await FaceMLDataDB.instance
        //         .getTotalFaceCount(minFaceScore: kMinHighQualityFaceScore);
        //     final blurryFaceCount =
        //         await FaceMLDataDB.instance.getBlurryFaceCount(15);
        //     showShortToast(context, "$blurryFaceCount blurry faces");
        //   },
        // ),
        // MenuItemWidget(
        //   captionedTextWidget: const CaptionedTextWidget(
        //     title: "Analyze file ID 25728869",
        //   ),
        //   pressedColor: getEnteColorScheme(context).fillFaint,
        //   trailingIcon: Icons.chevron_right_outlined,
        //   trailingIconIsMuted: true,
        //   onTap: () async {
        //     try {
        //       final enteFile = await SearchService.instance.getAllFiles().then(
        //             (value) => value.firstWhere(
        //               (element) => element.uploadedFileID == 25728869,
        //             ),
        //           );
        //       _logger.info(
        //         'File with ID ${enteFile.uploadedFileID} has name ${enteFile.displayName}',
        //       );
        //       FaceMlService.instance.isImageIndexRunning = true;
        //       final result = await FaceMlService.instance
        //           .analyzeImageInSingleIsolate(enteFile);
        //       if (result != null) {
        //         final resultJson = result.toJsonString();
        //         _logger.info('result: $resultJson');
        //       }
        //       FaceMlService.instance.isImageIndexRunning = false;
        //     } catch (e, s) {
        //       _logger.severe('indexing failed ', e, s);
        //       await showGenericErrorDialog(context: context, error: e);
        //     } finally {
        //       FaceMlService.instance.isImageIndexRunning = false;
        //     }
        //   },
        // ),
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<double>(
            future: FaceMLDataDB.instance.getClusteredToTotalFacesRatio(),
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
              await PersonService.instance.storeRemoteFeedback();
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
            title: "Reset feedback",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              await FaceMLDataDB.instance.dropFeedbackTables();
              Bus.instance.fire(PeopleChangedEvent());
              showShortToast(context, "Done");
            } catch (e, s) {
              _logger.warning('reset feedback failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Reset feedback & clusters",
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
                  "You will need to again cluster all the faces. You can drop feedback if you want to return to original cluster labels",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  await FaceMLDataDB.instance.resetClusterIDs();
                  await FaceMLDataDB.instance.dropClustersAndPersonTable();
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
            title: "Drop People to clusterMapping",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await showChoiceDialog(
              context,
              title: "Are you sure?",
              body:
                  "This won't delete the people, but will remove the mapping of people to clusters",
              firstButtonLabel: "Yes, confirm",
              firstButtonOnTap: () async {
                try {
                  final List<PersonEntity> persons =
                      await PersonService.instance.getPersons();
                  for (final PersonEntity p in persons) {
                    await PersonService.instance.deletePerson(p.remoteID);
                  }
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
        // sectionOptionSpacing,
        // MenuItemWidget(
        //   captionedTextWidget: const CaptionedTextWidget(
        //     title: "Rank blurs",
        //   ),
        //   pressedColor: getEnteColorScheme(context).fillFaint,
        //   trailingIcon: Icons.chevron_right_outlined,
        //   trailingIconIsMuted: true,
        //   onTap: () async {
        //     await showChoiceDialog(
        //       context,
        //       title: "Are you sure?",
        //       body:
        //           "This will delete all clusters and put blurry faces in separate clusters per ten points.",
        //       firstButtonLabel: "Yes, confirm",
        //       firstButtonOnTap: () async {
        //         try {
        //           await ClusterFeedbackService.instance
        //               .createFakeClustersByBlurValue();
        //           showShortToast(context, "Done");
        //         } catch (e, s) {
        //           _logger.warning('Failed to rank faces on blur values ', e, s);
        //           await showGenericErrorDialog(context: context, error: e);
        //         }
        //       },
        //     );
        //   },
        // ),
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
        if (kDebugMode) sectionOptionSpacing,
        if (kDebugMode)
          MenuItemWidget(
            captionedTextWidget: FutureBuilder<int>(
              future: FaceMLDataDB.instance.getIndexedFileCount(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CaptionedTextWidget(
                    title: "Read embeddings for ${snapshot.data!} files",
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
              final int totalFaces =
                  await FaceMLDataDB.instance.getTotalFaceCount();
              _logger.info('start reading embeddings for $totalFaces faces');
              final time = DateTime.now();
              try {
                final result = await FaceMLDataDB.instance
                    .getFaceEmbeddingMap(maxFaces: totalFaces);
                final endTime = DateTime.now();
                _logger.info(
                  'Read embeddings of ${result.length} faces in ${time.difference(endTime).inSeconds} secs',
                );
                showShortToast(
                  context,
                  "Read embeddings of ${result.length} faces in ${time.difference(endTime).inSeconds} secs",
                );
              } catch (e, s) {
                _logger.warning('read embeddings failed ', e, s);
                await showGenericErrorDialog(context: context, error: e);
              }
            },
          ),
      ],
    );
  }
}
