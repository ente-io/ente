import "dart:async";
import "dart:typed_data" show Float32List;

import "package:flutter/foundation.dart" show kDebugMode;
import 'package:flutter/material.dart';
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";
import "package:logging/logging.dart";
import "package:ml_linalg/linalg.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_indexing_isolate.dart";
import 'package:photos/services/machine_learning/ml_service.dart';
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/memory_home_widget_service.dart";
import "package:photos/src/rust/api/simple.dart";
import "package:photos/src/rust/api/usearch_api.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import "package:photos/ui/components/toggle_switch_widget.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/settings/common_settings.dart';
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/ml_util.dart";

class MLDebugSectionWidget extends StatefulWidget {
  const MLDebugSectionWidget({super.key});

  @override
  State<MLDebugSectionWidget> createState() => _MLDebugSectionWidgetState();
}

class _MLDebugSectionWidgetState extends State<MLDebugSectionWidget> {
  Timer? _timer;
  bool isExpanded = false;
  final Logger logger = Logger("MLDebugSectionWidget");
  late final mlDataDB = MLDataDB.instance;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isExpanded) {
        setState(() {
          // Your state update logic here
        });
      }
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
      onExpand: (p0) => isExpanded = p0,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    logger.info("Building ML Debug section options");
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Do some usearch",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final allImageEmbeddings = await mlDataDB.getAllClipVectors();
              final tenVectors = allImageEmbeddings.sublist(0, 10);
              final tenEmbeddings = tenVectors
                  .map((e) => Float32List.fromList(e.vector.toList()))
                  .toList();
              final tenKeys =
                  Uint64List.fromList(tenVectors.map((e) => e.fileID).toList());
              final embedDimensions = BigInt.from(tenEmbeddings.first.length);
              final indexPath = (await getApplicationSupportDirectory()).path +
                  "/ml/test/vector_db_index.usearch";
              final rustVectorDB = VectorDb(
                filePath: indexPath,
                dimensions: embedDimensions,
              );
              await rustVectorDB.resetIndex();
              final stats = await rustVectorDB.getIndexStats();
              logger.info("vector_db stats: $stats");
              await rustVectorDB.bulkAddVectors(
                keys: tenKeys,
                vectors: tenEmbeddings,
              );
              final statsAgain = await rustVectorDB.getIndexStats();
              logger.info("vector_db stats again: $statsAgain");
              final size = statsAgain.$1;
              final capacity = statsAgain.$2;
              final dimensions = statsAgain.$3;
              showShortToast(
                context,
                "Size: $size, Capacity: $capacity, Dimensions: $dimensions",
              );
              await rustVectorDB.deleteIndex();
            } catch (e, s) {
              logger.warning('Rust bridge failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Benchmark Vector DB Face",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final w = (kDebugMode ? EnteWatch('MLDebugSectionWidget') : null)
                ?..start();
              final persons = await PersonService.instance.getPersons();
              w?.log('get all persons for ${persons.length} persons');
              String laurensID = '';
              for (final person in persons) {
                if (person.data.name.toLowerCase().contains('laurens')) {
                  laurensID = person.remoteID;
                }
              }
              if (laurensID.isEmpty) {
                throw Exception('Laurens not found');
              }
              final laurensFaceIDs =
                  await MLDataDB.instance.getFaceIDsForPerson(laurensID);
              w?.log(
                'getting all face ids for laurens (${laurensFaceIDs.length} faces)',
              );
              final laurensFaceIdToEmbeddingData = await MLDataDB.instance
                  .getFaceEmbeddingMapForFaces(laurensFaceIDs);

              // Fill the vector DB with all embeddings
              final laurensFaceIdToFloat32 = laurensFaceIdToEmbeddingData.map(
                (key, value) => MapEntry(
                  key,
                  Float32List.fromList(EVector.fromBuffer(value).values),
                ),
              );
              final keys = Uint64List.fromList(
                List.generate(
                  laurensFaceIdToFloat32.length,
                  (index) => BigInt.from(index + 1),
                ),
              );
              final vectorDB = VectorDb(
                filePath: (await getApplicationSupportDirectory()).path +
                    "/ml/test/vector_db_face_index.usearch",
                dimensions: BigInt.from(
                  laurensFaceIdToFloat32.values.first.length,
                ),
              );
              await vectorDB.resetIndex();
              await vectorDB.bulkAddVectors(
                keys: keys,
                vectors: laurensFaceIdToFloat32.values.toList(),
              );

              // Benchmarking the vector DB
              final queries = laurensFaceIdToFloat32.values.toList();
              final count = BigInt.from(10);
              w?.reset();
              final results = await vectorDB.bulkSearchVectors(
                queries: queries,
                count: count,
              );

              w?.log(
                'Done with ${queries.length * queries.length} (${queries.length} x ${queries.length}}) embeddings comparisons in vector DB',
              );
              logger.info(
                'vector db results: ${results.length} results, first: ${results.first}, hundredth: ${results[99]}',
              );

              // Benchmarking our own vector comparisons
              final laurensFaceIdToEmbeddingVectors =
                  laurensFaceIdToEmbeddingData.map(
                (key, value) => MapEntry(
                  key,
                  Vector.fromList(EVector.fromBuffer(value).values),
                ),
              );
              final faceVectors = laurensFaceIdToEmbeddingVectors.values;
              w?.reset();
              for (final faceVector in faceVectors) {
                for (final otherFaceVector in faceVectors) {
                  final _ = 1 - faceVector.dot(otherFaceVector);
                }
              }

              w?.log(
                'Done with ${faceVectors.length * faceVectors.length} (${faceVectors.length} x ${faceVectors.length}}) embeddings comparisons in own method',
              );
              await vectorDB.deleteIndex();
            } catch (e, s) {
              logger.warning('vector DB search failed ', e, s);

              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Benchmark Vector DB CLIP",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final w = (kDebugMode ? EnteWatch('MLDebugSectionWidget') : null)
                ?..start();
              final clipEmbeddings = await mlDataDB.getAllClipVectors();
              w?.log(
                'getting all clip embeddings (${clipEmbeddings.length} embeddings)',
              );

              // Fill the vector DB with all embeddings
              final clipFloat32 = clipEmbeddings
                  .map(
                    (value) => Float32List.fromList(value.vector.toList()),
                  )
                  .toList();
              final keys = Uint64List.fromList(
                List.generate(
                  clipFloat32.length,
                  (index) => BigInt.from(index + 1),
                ),
              );
              final vectorDB = VectorDb(
                filePath: (await getApplicationSupportDirectory()).path +
                    "/ml/test/vector_db_clip_index.usearch",
                dimensions: BigInt.from(
                  clipFloat32.first.length,
                ),
              );
              await vectorDB.resetIndex();
              await vectorDB.bulkAddVectors(
                keys: keys,
                vectors: clipFloat32,
              );

              // Benchmarking the vector DB
              final count = BigInt.from(10);
              w?.reset();
              final results = await vectorDB.bulkSearchVectors(
                queries: clipFloat32,
                count: count,
              );

              w?.log(
                'Done with ${clipFloat32.length * clipFloat32.length} (${clipFloat32.length} x ${clipFloat32.length}}) embeddings comparisons in vector DB',
              );
              logger.info(
                'vector db results: ${results.length} results, first: ${results.first}, hundredth: ${results[99]}',
              );

              // // Benchmarking our own vector comparisons
              // final clipVectors = clipEmbeddings
              //     .map(
              //       (value) => value.vector,
              //     )
              //     .toList();
              // w?.reset();
              // int compared = 0;
              // int ms = DateTime.now().millisecondsSinceEpoch;
              // for (final faceVector in clipVectors) {
              //   for (final otherFaceVector in clipVectors) {
              //     final _ = 1 - faceVector.dot(otherFaceVector);
              //   }
              //   compared++;
              //   if (compared % 100 == 0) {
              //     final now = DateTime.now().millisecondsSinceEpoch;
              //     logger.info(
              //       'Compared next 100 in ${now - ms} ms, progress: ($compared / ${clipVectors.length})',
              //     );
              //     ms = now;
              //   }
              // }
              // w?.log(
              //   'Done with ${clipVectors.length * clipVectors.length} (${clipVectors.length} x ${clipVectors.length}}) embeddings comparisons in own method',
              // );

              await vectorDB.deleteIndex();
            } catch (e, s) {
              logger.warning('vector DB search failed ', e, s);

              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Test rust bridge",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final String greetings = greet(name: "Tom");
              const String expected = "Hello, Tom!";
              assert(greetings == expected);
              debugPrint("String from rust: $greetings");
              showShortToast(context, greetings);
            } catch (e, s) {
              logger.warning('Rust bridge failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<IndexStatus>(
            future: getIndexStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final IndexStatus status = snapshot.data!;
                return CaptionedTextWidget(
                  title: "ML (${status.indexedItems} indexed)",
                );
              }
              return const SizedBox.shrink();
            },
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => flagService.hasGrantedMLConsent,
            onChanged: () async {
              try {
                final oldMlConsent = flagService.hasGrantedMLConsent;
                final mlConsent = !oldMlConsent;
                await flagService.setMLConsent(mlConsent);
                logger.info('ML consent turned ${mlConsent ? 'on' : 'off'}');
                if (!mlConsent) {
                  MLService.instance.pauseIndexingAndClustering();
                  unawaited(
                    MLIndexingIsolate.instance.cleanupLocalIndexingModels(),
                  );
                } else {
                  await MLService.instance.init();
                  await SemanticSearchService.instance.init();
                  unawaited(MLService.instance.runAllML(force: true));
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
          singleBorderRadius: 8,
          isGestureDetectorDisabled: true,
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Remote fetch",
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => localSettings.remoteFetchEnabled,
            onChanged: () async {
              try {
                await localSettings.toggleRemoteFetch();
                logger.info(
                  'Remote fetch is turned ${localSettings.remoteFetchEnabled ? 'on' : 'off'}',
                );
                if (mounted) {
                  setState(() {});
                }
              } catch (e, s) {
                logger.warning(
                  'Remote fetch toggle failed ',
                  e,
                  s,
                );
                await showGenericErrorDialog(
                  context: context,
                  error: e,
                );
              }
            },
          ),
          singleBorderRadius: 8,
          isGestureDetectorDisabled: true,
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Local indexing",
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => localSettings.isMLLocalIndexingEnabled,
            onChanged: () async {
              final localIndexing = await localSettings.toggleLocalMLIndexing();
              if (localIndexing) {
                unawaited(MLService.instance.runAllML(force: true));
              } else {
                MLService.instance.pauseIndexingAndClustering();
                unawaited(
                  MLIndexingIsolate.instance.cleanupLocalIndexingModels(),
                );
              }

              if (mounted) {
                setState(() {});
              }
            },
          ),
          singleBorderRadius: 8,
          isGestureDetectorDisabled: true,
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Auto indexing",
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => !MLService.instance.debugIndexingDisabled,
            onChanged: () async {
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
          singleBorderRadius: 8,
          isGestureDetectorDisabled: true,
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
              unawaited(MLService.instance.fetchAndIndexAllImages());
            } catch (e, s) {
              logger.warning('indexing failed ', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: FutureBuilder<double>(
            future: mlDataDB.getClusteredToIndexableFilesRatio(),
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
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Update discover",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              await magicCacheService.updateCache(forced: true);
            } catch (e, s) {
              logger.warning('Update discover failed', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Update memories",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final now = DateTime.now();
              await memoriesCacheService.updateCache(forced: true);
              final duration = DateTime.now().difference(now);
              showShortToast(context, "Done in ${duration.inSeconds} seconds");
            } catch (e, s) {
              logger.warning('Update memories failed', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Clear memories cache",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            try {
              final now = DateTime.now();
              await memoriesCacheService.clearMemoriesCache();
              final duration = DateTime.now().difference(now);
              showShortToast(context, "Done in ${duration.inSeconds} seconds");
            } catch (e, s) {
              logger.warning('Clear memories cache failed', e, s);
              await showGenericErrorDialog(context: context, error: e);
            }
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Force memory widget data refresh",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async =>
              await MemoryHomeWidgetService.instance.initMemoryHW(true),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Change memory widget picture",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async =>
              await MemoryHomeWidgetService.instance.initMemoryHW(false),
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
              await faceRecognitionService.syncPersonFeedback();
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
            final emptyFaces = await mlDataDB.getErroredFaceCount();
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
                  await mlDataDB.dropFacesFeedbackTables();
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
                  await mlDataDB.dropClustersAndPersonTable();
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
                  await mlDataDB.dropClustersAndPersonTable(faces: true);
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
