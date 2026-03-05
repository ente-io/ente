import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/notification_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart";
import "package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart";
import "package:photos/services/machine_learning/ml_indexing_isolate.dart";
import "package:photos/services/machine_learning/ml_service.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
import "package:photos/services/remote_assets_service.dart";
import "package:photos/services/wake_lock_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/menu_section_description_widget.dart";
import "package:photos/ui/components/menu_section_title.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/settings/ml/ml_user_dev_screen.dart";
import "package:photos/utils/ml_util.dart";
import "package:photos/utils/network_util.dart";

class MachineLearningSettingsPage extends StatefulWidget {
  const MachineLearningSettingsPage({super.key});

  @override
  State<MachineLearningSettingsPage> createState() =>
      _MachineLearningSettingsPageState();
}

class _MachineLearningSettingsPageState
    extends State<MachineLearningSettingsPage> {
  Timer? _timer;
  int _titleTapCount = 0;
  Timer? _advancedOptionsTimer;
  bool _hasAcknowledgedMLConsent = false;
  bool _hasHandledDisabledExit = false;

  @override
  void initState() {
    super.initState();
    EnteWakeLockService.instance.updateWakeLock(
      enable: true,
      wakeLockFor: WakeLockFor.machineLearningSettingsScreen,
    );
    computeController.forceOverrideML(turnOn: true);
    if (!MLIndexingIsolate.instance.areModelsDownloaded) {
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    _advancedOptionsTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _titleTapCount = 0;
    });
  }

  @override
  void dispose() {
    super.dispose();
    EnteWakeLockService.instance.updateWakeLock(
      enable: false,
      wakeLockFor: WakeLockFor.machineLearningSettingsScreen,
    );
    computeController.forceOverrideML(turnOn: false);
    _timer?.cancel();
    _advancedOptionsTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final hasEnabled = hasGrantedMLConsent;

    if (!hasEnabled) {
      return _buildDisabledMLScreen(context);
    }

    return _buildEnabledMLScreen(context);
  }

  Widget _buildEnabledMLScreen(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.strokeBase),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: colorScheme.backgroundColour,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _titleTapCount++;
                    if (_titleTapCount >= 7) {
                      _titleTapCount = 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return const MLUserDeveloperOptions(
                              mlIsEnabled: true,
                            );
                          },
                        ),
                      ).ignore();
                    }
                  });
                },
                child: Text(
                  AppLocalizations.of(context).machineLearning,
                  style: textTheme.h3Bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).mlIndexingDescription,
                textAlign: TextAlign.left,
                style: textTheme.small.copyWith(
                  color: colorScheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _getMlSettings(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledMLScreen(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundColour,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.strokeBase),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).mlConsent,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 12),
              _buildDisabledMLDescription(context),
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  "assets/ducky_ml.png",
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 18),
              _buildDisabledConsentAckRow(context),
              const SizedBox(height: 20),
              ButtonWidgetV2(
                buttonType: ButtonTypeV2.primary,
                labelText: AppLocalizations.of(context).mlConsent,
                isDisabled: !_hasAcknowledgedMLConsent,
                onTap: () async {
                  if (!_hasAcknowledgedMLConsent) return;
                  await toggleMlConsent();
                },
              ),
              const SizedBox(height: 12),
              ButtonWidgetV2(
                buttonType: ButtonTypeV2.secondary,
                labelText: AppLocalizations.of(context).cancel,
                onTap: () async {
                  await _handleDisabledScreenExit();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDisabledScreenExit() async {
    if (_hasHandledDisabledExit || hasGrantedMLConsent) {
      return;
    }
    _hasHandledDisabledExit = true;
    await localSettings.setHasSeenMLEnablingBanner();
    Bus.instance.fire(NotificationEvent());
  }

  Future<void> toggleMlConsent() async {
    final oldMlConsent = hasGrantedMLConsent;
    final mlConsent = !oldMlConsent;
    await setMLConsent(mlConsent);
    Bus.instance.fire(NotificationEvent());
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
  }

  Widget _buildDisabledMLDescription(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).mlConsentDescription,
          textAlign: TextAlign.left,
          style: textTheme.small.copyWith(color: colorScheme.textMuted),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async => _openMLPrivacyPolicy(context),
          child: Text(
            AppLocalizations.of(context).mlConsentPrivacy,
            textAlign: TextAlign.left,
            style: textTheme.small.copyWith(
              color: colorScheme.textMuted,
              decoration: TextDecoration.underline,
              decorationColor: colorScheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledConsentAckRow(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final accentColor = colorScheme.greenBase;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _hasAcknowledgedMLConsent = !_hasAcknowledgedMLConsent;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accentColor),
              color:
                  _hasAcknowledgedMLConsent ? accentColor : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: _hasAcknowledgedMLConsent
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: colorScheme.contentReverse,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).mlConsentConfirmation,
              style: getEnteTextTheme(context).small.copyWith(
                    color: colorScheme.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMLPrivacyPolicy(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return WebPage(
            AppLocalizations.of(context).privacyPolicyTitle,
            "https://ente.io/privacy",
          );
        },
      ),
    );
  }

  Widget _getMlSettings(BuildContext context) {
    final hasEnabled = hasGrantedMLConsent;
    if (!hasEnabled) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).enabled,
          trailingWidget: ToggleSwitchWidget(
            value: () => hasEnabled,
            onChanged: () async {
              await toggleMlConsent();
            },
          ),
        ),
        const SizedBox(height: 8),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).localIndexing,
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
        ),
        const SizedBox(
          height: 12,
        ),
        MLIndexingIsolate.instance.areModelsDownloaded ||
                !localSettings.isMLLocalIndexingEnabled
            ? const MLStatusWidget()
            : const ModelLoadingState(),
      ],
    );
  }
}

class ModelLoadingState extends StatefulWidget {
  const ModelLoadingState({
    super.key,
  });

  @override
  State<ModelLoadingState> createState() => _ModelLoadingStateState();
}

class _ModelLoadingStateState extends State<ModelLoadingState> {
  StreamSubscription<(String, int, int)>? _progressStream;
  final Map<String, (int, int)> _progressMap = {};
  Timer? _timer;

  @override
  void initState() {
    _progressStream =
        RemoteAssetsService.instance.progressStream.listen((event) {
      final String url = event.$1;
      String title = "";
      if (url.contains(ClipImageEncoder.kRemoteBucketModelPath)) {
        title = "Image Model";
      } else if (url.contains(ClipTextEncoder.kRemoteBucketModelPath)) {
        title = "Text Model";
      } else if (url.contains(FaceDetectionService.kRemoteBucketModelPath)) {
        title = "Face Detection Model";
      } else if (url.contains(FaceEmbeddingService.kRemoteBucketModelPath)) {
        title = "Face Embedding Model";
      }
      if (title.isNotEmpty) {
        _progressMap[title] = (event.$2, event.$3);
        setState(() {});
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _progressStream?.cancel();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Column(
      children: [
        MenuSectionTitle(title: AppLocalizations.of(context).status),
        const SizedBox(height: 8),
        FutureBuilder(
          future: canUseHighBandwidth().then((v) => isOfflineMode || v),
          builder: (context, snapshot) {
            String title = "";
            if (snapshot.hasData) {
              if (snapshot.data!) {
                MLIndexingIsolate.instance.triggerModelsDownload();
                title = AppLocalizations.of(context).checkingModels;
              } else {
                title = AppLocalizations.of(context).waitingForWifi;
              }
            }
            return MenuItemWidgetNew(
              title: title,
              trailingWidget: EnteLoadingWidget(
                size: 12,
                color: colorScheme.fillMuted,
              ),
              isGestureDetectorDisabled: true,
            );
          },
        ),
        // show the progress map if in debug mode
        ..._progressMap.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: MenuItemWidgetNew(
              key: ValueKey(entry.value),
              title: entry.key,
              trailingWidget: Text(
                '${(entry.value.$1 * 100) ~/ entry.value.$2}%',
                style: textTheme.small.copyWith(color: colorScheme.textMuted),
              ),
              isGestureDetectorDisabled: true,
            ),
          );
        }),
      ],
    );
  }
}

class MLStatusWidget extends StatefulWidget {
  const MLStatusWidget({
    super.key,
  });

  @override
  State<MLStatusWidget> createState() => MLStatusWidgetState();
}

class MLStatusWidgetState extends State<MLStatusWidget> {
  Timer? _timer;
  bool _isDeviceHealthy = computeController.isDeviceHealthy;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      MLService.instance.triggerML();
      _isDeviceHealthy = computeController.isDeviceHealthy;
      setState(() {});
    });
  }

  Future<IndexStatus> _getIndexStatus() async {
    final status = await getIndexStatus();
    return status;
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
        MenuSectionTitle(title: AppLocalizations.of(context).status),
        const SizedBox(height: 8),
        FutureBuilder(
          future: _getIndexStatus(),
          builder: (context, snapshot) {
            final colorScheme = getEnteColorScheme(context);
            final textTheme = getEnteTextTheme(context);
            if (snapshot.hasData) {
              final int indexedFiles = snapshot.data!.indexedItems;
              final int pendingFiles = snapshot.data!.pendingItems;
              final int total = indexedFiles + pendingFiles;
              final bool hasWifi = snapshot.data!.hasWifiEnabled!;

              if (!_isDeviceHealthy && pendingFiles > 0) {
                return MenuSectionDescriptionWidget(
                  content: AppLocalizations.of(context)
                      .indexingPausedStatusDescription,
                );
              }

              return Column(
                children: [
                  MenuItemWidgetNew(
                    key: ValueKey("pending_items_$pendingFiles"),
                    title: AppLocalizations.of(context).processed,
                    trailingWidget: Text(
                      total < 1
                          ? 'NA'
                          : pendingFiles == 0
                              ? '100%'
                              : '${(indexedFiles * 100.0 / total * 1.0).toStringAsFixed(2)}%',
                      style: textTheme.small.copyWith(
                        color: colorScheme.textMuted,
                      ),
                    ),
                    isGestureDetectorDisabled: true,
                  ),
                  if (MLService.instance.showClusteringIsHappening)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: MenuItemWidgetNew(
                        title: AppLocalizations.of(context).clusteringProgress,
                        trailingWidget: Text(
                          AppLocalizations.of(context).currentlyRunning,
                          style: textTheme.small.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        ),
                        isGestureDetectorDisabled: true,
                      ),
                    )
                  else if (!hasWifi && pendingFiles > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: MenuItemWidgetNew(
                        title: AppLocalizations.of(context).waitingForWifi,
                        isGestureDetectorDisabled: true,
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
