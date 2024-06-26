import "dart:async";
import "dart:math" show max, min;

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import 'package:photos/events/embedding_updated_event.dart';
import "package:photos/face/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/ml/ml_versions.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/face_ml/face_ml_service.dart";
import "package:photos/services/machine_learning/machine_learning_controller.dart";
import 'package:photos/services/machine_learning/semantic_search/frameworks/ml_framework.dart';
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
import "package:photos/services/remote_assets_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/menu_section_description_widget.dart";
import "package:photos/ui/components/menu_section_title.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/utils/data_util.dart";
import "package:photos/utils/local_settings.dart";
import "package:photos/utils/ml_util.dart";
import "package:photos/utils/wakelock_util.dart";

final _logger = Logger("MachineLearningSettingsPage");

class MachineLearningSettingsPage extends StatefulWidget {
  const MachineLearningSettingsPage({super.key});

  @override
  State<MachineLearningSettingsPage> createState() =>
      _MachineLearningSettingsPageState();
}

class _MachineLearningSettingsPageState
    extends State<MachineLearningSettingsPage> {
  late InitializationState _state;
  final EnteWakeLock _wakeLock = EnteWakeLock();

  late StreamSubscription<MLFrameworkInitializationUpdateEvent>
      _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription =
        Bus.instance.on<MLFrameworkInitializationUpdateEvent>().listen((event) {
      _fetchState();
      setState(() {});
    });
    _fetchState();
    _wakeLock.enable();
    MachineLearningController.instance.forceOverrideML(turnOn: true);
  }

  void _fetchState() {
    _state = SemanticSearchService.instance.getFrameworkInitializationState();
  }

  @override
  void dispose() {
    super.dispose();
    _eventSubscription.cancel();
    _wakeLock.disable();
    MachineLearningController.instance.forceOverrideML(turnOn: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool facesFlag = flagService.faceSearchEnabled;
    _logger.info("On page open, facesFlag: $facesFlag");
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).machineLearning,
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) => Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Text(
                  S.of(context).mlIndexingDescription,
                  textAlign: TextAlign.left,
                  style: getEnteTextTheme(context)
                      .mini
                      .copyWith(color: getEnteColorScheme(context).textMuted),
                ),
              ),
              childCount: 1,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _getMagicSearchSettings(context),
                        const SizedBox(height: 12),
                        facesFlag
                            ? _getFacesSearchSettings(context)
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getMagicSearchSettings(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final hasEnabled = LocalSettings.instance.hasEnabledMagicSearch();
    return Column(
      children: [
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).magicSearch,
          ),
          menuItemColor: colorScheme.fillFaint,
          trailingWidget: ToggleSwitchWidget(
            value: () => LocalSettings.instance.hasEnabledMagicSearch(),
            onChanged: () async {
              await LocalSettings.instance.setShouldEnableMagicSearch(
                !LocalSettings.instance.hasEnabledMagicSearch(),
              );
              if (LocalSettings.instance.hasEnabledMagicSearch()) {
                unawaited(
                  SemanticSearchService.instance
                      .init(shouldSyncImmediately: true),
                );
              } else {
                await SemanticSearchService.instance.clearQueue();
              }
              setState(() {});
            },
          ),
          singleBorderRadius: 8,
          alignCaptionedTextToLeft: true,
          isGestureDetectorDisabled: true,
        ),
        const SizedBox(
          height: 12,
        ),
        hasEnabled
            ? Column(
                children: [
                  _state == InitializationState.initialized
                      ? const MagicSearchIndexStatsWidget()
                      : ModelLoadingState(_state),
                  const SizedBox(
                    height: 12,
                  ),
                  flagService.internalUser
                      ? MenuItemWidget(
                          leadingIcon: Icons.delete_sweep_outlined,
                          captionedTextWidget: CaptionedTextWidget(
                            title: S.of(context).clearIndexes,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          singleBorderRadius: 8,
                          alwaysShowSuccessState: true,
                          onTap: () async {
                            await SemanticSearchService.instance.clearIndexes();
                            if (mounted) {
                              setState(() => {});
                            }
                          },
                        )
                      : const SizedBox.shrink(),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _getFacesSearchSettings(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final hasEnabled = LocalSettings.instance.isFaceIndexingEnabled;
    return Column(
      children: [
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).faceRecognition,
          ),
          menuItemColor: colorScheme.fillFaint,
          trailingWidget: ToggleSwitchWidget(
            value: () => LocalSettings.instance.isFaceIndexingEnabled,
            onChanged: () async {
              final isEnabled =
                  await LocalSettings.instance.toggleFaceIndexing();
              if (isEnabled) {
                await FaceMlService.instance.init();
                unawaited(FaceMlService.instance.runAllFaceML(force: true));
              } else {
                FaceMlService.instance.pauseIndexingAndClustering();
              }
              if (mounted) {
                setState(() {});
              }
            },
          ),
          singleBorderRadius: 8,
          alignCaptionedTextToLeft: true,
          isGestureDetectorDisabled: true,
        ),
        const SizedBox(
          height: 12,
        ),
        hasEnabled
            ? const FaceRecognitionStatusWidget()
            : const SizedBox.shrink(),
      ],
    );
  }
}

class ModelLoadingState extends StatefulWidget {
  final InitializationState state;

  const ModelLoadingState(
    this.state, {
    Key? key,
  }) : super(key: key);

  @override
  State<ModelLoadingState> createState() => _ModelLoadingStateState();
}

class _ModelLoadingStateState extends State<ModelLoadingState> {
  StreamSubscription<(String, int, int)>? _progressStream;
  final Map<String, (int, int)> _progressMap = {};
  @override
  void initState() {
    _progressStream =
        RemoteAssetsService.instance.progressStream.listen((event) {
      final String url = event.$1;
      String title = "";
      if (url.contains("clip-image")) {
        title = "Image Model";
      } else if (url.contains("clip-text")) {
        title = "Text Model";
      }
      if (title.isNotEmpty) {
        _progressMap[title] = (event.$2, event.$3);
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _progressStream?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuSectionTitle(title: S.of(context).status),
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: _getTitle(context),
          ),
          trailingWidget: EnteLoadingWidget(
            size: 12,
            color: getEnteColorScheme(context).fillMuted,
          ),
          singleBorderRadius: 8,
          alignCaptionedTextToLeft: true,
          isGestureDetectorDisabled: true,
        ),
        // show the progress map if in debug mode
        if (flagService.internalUser)
          ..._progressMap.entries.map((entry) {
            return MenuItemWidget(
              key: ValueKey(entry.value),
              captionedTextWidget: CaptionedTextWidget(
                title: entry.key,
              ),
              trailingWidget: Text(
                entry.value.$1 == entry.value.$2
                    ? "Done"
                    : "${formatBytes(entry.value.$1)} / ${formatBytes(entry.value.$2)}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              singleBorderRadius: 8,
              alignCaptionedTextToLeft: true,
              isGestureDetectorDisabled: true,
            );
          }).toList(),
      ],
    );
  }

  String _getTitle(BuildContext context) {
    switch (widget.state) {
      case InitializationState.waitingForNetwork:
        return S.of(context).waitingForWifi;
      default:
        return S.of(context).loadingModel;
    }
  }
}

class MagicSearchIndexStatsWidget extends StatefulWidget {
  const MagicSearchIndexStatsWidget({
    super.key,
  });

  @override
  State<MagicSearchIndexStatsWidget> createState() =>
      _MagicSearchIndexStatsWidgetState();
}

class _MagicSearchIndexStatsWidgetState
    extends State<MagicSearchIndexStatsWidget> {
  IndexStatus? _status;
  late StreamSubscription<EmbeddingCacheUpdatedEvent> _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription =
        Bus.instance.on<EmbeddingCacheUpdatedEvent>().listen((event) {
      _fetchIndexStatus();
    });
    _fetchIndexStatus();
  }

  void _fetchIndexStatus() {
    SemanticSearchService.instance.getIndexStatus().then((status) {
      _status = status;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _eventSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const EnteLoadingWidget();
    }
    return Column(
      children: [
        Row(
          children: [
            MenuSectionTitle(title: S.of(context).status),
            Expanded(child: Container()),
            _status!.pendingItems > 0
                ? EnteLoadingWidget(
                    color: getEnteColorScheme(context).fillMuted,
                  )
                : const SizedBox.shrink(),
          ],
        ),
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).indexedItems,
          ),
          trailingWidget: Text(
            NumberFormat().format(_status!.indexedItems),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          singleBorderRadius: 8,
          alignCaptionedTextToLeft: true,
          isGestureDetectorDisabled: true,
          // Setting a key here to ensure trailingWidget is refreshed
          key: ValueKey("indexed_items_" + _status!.indexedItems.toString()),
        ),
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).pendingItems,
          ),
          trailingWidget: Text(
            NumberFormat().format(_status!.pendingItems),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          singleBorderRadius: 8,
          alignCaptionedTextToLeft: true,
          isGestureDetectorDisabled: true,
          // Setting a key here to ensure trailingWidget is refreshed
          key: ValueKey("pending_items_" + _status!.pendingItems.toString()),
        ),
      ],
    );
  }
}

class FaceRecognitionStatusWidget extends StatefulWidget {
  const FaceRecognitionStatusWidget({
    super.key,
  });

  @override
  State<FaceRecognitionStatusWidget> createState() =>
      FaceRecognitionStatusWidgetState();
}

class FaceRecognitionStatusWidgetState
    extends State<FaceRecognitionStatusWidget> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        // Your state update logic here
      });
    });
  }

  Future<(int, int, double, bool)> getIndexStatus() async {
    try {
      final indexedFiles = await FaceMLDataDB.instance
          .getIndexedFileCount(minimumMlVersion: faceMlVersion);
      final indexableFiles = (await getIndexableFileIDs()).length;
      final showIndexedFiles = min(indexedFiles, indexableFiles);
      final pendingFiles = max(indexableFiles - indexedFiles, 0);
      final clusteringDoneRatio =
          await FaceMLDataDB.instance.getClusteredToIndexableFilesRatio();
      final bool deviceIsHealthy =
          MachineLearningController.instance.isDeviceHealthy;

      return (
        showIndexedFiles,
        pendingFiles,
        clusteringDoneRatio,
        deviceIsHealthy
      );
    } catch (e, s) {
      _logger.severe('Error getting face recognition status', e, s);
      rethrow;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            MenuSectionTitle(title: S.of(context).status),
            Expanded(child: Container()),
          ],
        ),
        FutureBuilder(
          future: getIndexStatus(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final int indexedFiles = snapshot.data!.$1;
              final int pendingFiles = snapshot.data!.$2;
              final double clusteringDoneRatio = snapshot.data!.$3;
              final double clusteringPercentage =
                  (clusteringDoneRatio * 100).clamp(0, 100);
              final bool isDeviceHealthy = snapshot.data!.$4;

              if (!isDeviceHealthy &&
                  (pendingFiles > 0 || clusteringPercentage < 99)) {
                return MenuSectionDescriptionWidget(
                  content: S.of(context).indexingIsPaused,
                );
              }

              return Column(
                children: [
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).indexedItems,
                    ),
                    trailingWidget: Text(
                      NumberFormat().format(indexedFiles),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    singleBorderRadius: 8,
                    alignCaptionedTextToLeft: true,
                    isGestureDetectorDisabled: true,
                    key: ValueKey("indexed_items_" + indexedFiles.toString()),
                  ),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).pendingItems,
                    ),
                    trailingWidget: Text(
                      NumberFormat().format(pendingFiles),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    singleBorderRadius: 8,
                    alignCaptionedTextToLeft: true,
                    isGestureDetectorDisabled: true,
                    key: ValueKey("pending_items_" + pendingFiles.toString()),
                  ),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).clusteringProgress,
                    ),
                    trailingWidget: Text(
                      FaceMlService.instance.showClusteringIsHappening
                          ? "currently running"
                          : "${clusteringPercentage.toStringAsFixed(0)}%",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    singleBorderRadius: 8,
                    alignCaptionedTextToLeft: true,
                    isGestureDetectorDisabled: true,
                    key: ValueKey(
                      FaceMlService.instance.showClusteringIsHappening
                          ? "currently running"
                          : "clustering_progress_" +
                              clusteringPercentage.toStringAsFixed(0),
                    ),
                  ),
                ],
              );
            }
            return const EnteLoadingWidget();
          },
        ),
      ],
    );
  }
}
