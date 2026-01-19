import "dart:async";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_indexing_isolate.dart";
import "package:photos/services/machine_learning/ml_service.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/settings/settings_grouped_card.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/dialog_util.dart";

class MLDebugSettingsPage extends StatefulWidget {
  const MLDebugSettingsPage({super.key});

  @override
  State<MLDebugSettingsPage> createState() => _MLDebugSettingsPageState();
}

class _MLDebugSettingsPageState extends State<MLDebugSettingsPage> {
  final Logger logger = Logger("MLDebugSettingsPage");
  late final mlDataDB = MLDataDB.instance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "ML Debug",
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMLControlsCard(context),
                      const SizedBox(height: 8),
                      _buildMLActionsCard(context),
                      const SizedBox(height: 8),
                      _buildResetActionsCard(context),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMLControlsCard(BuildContext context) {
    return SettingsGroupedCard(
      children: [
        MenuItemWidgetNew(
          title: "ML Consent",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedAiBrain01,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => flagService.hasGrantedMLConsent,
            onChanged: _onMLConsentChanged,
          ),
        ),
        MenuItemWidgetNew(
          title: "Remote fetch",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedCloud,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => localSettings.remoteFetchEnabled,
            onChanged: _onRemoteFetchChanged,
          ),
        ),
        MenuItemWidgetNew(
          title: "Local indexing",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedSmartPhone01,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => localSettings.isMLLocalIndexingEnabled,
            onChanged: _onLocalIndexingChanged,
          ),
        ),
        MenuItemWidgetNew(
          title: "Auto indexing",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedRefresh,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => !MLService.instance.debugIndexingDisabled,
            onChanged: _onAutoIndexingChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMLActionsCard(BuildContext context) {
    return SettingsGroupedCard(
      children: [
        MenuItemWidgetNew(
          title: "Trigger run ML",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedPlay,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onTriggerRunML(context),
        ),
        MenuItemWidgetNew(
          title: "Trigger run indexing",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedSearch01,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onTriggerRunIndexing(context),
        ),
        MenuItemWidgetNew(
          title: "Trigger clustering",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedUserMultiple,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onTriggerClustering(context),
        ),
        MenuItemWidgetNew(
          title: "Update discover",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedCompass01,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onUpdateDiscover(context),
        ),
        MenuItemWidgetNew(
          title: "Update memories",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedSparkles,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onUpdateMemories(context),
        ),
        MenuItemWidgetNew(
          title: "Sync person mappings",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedUserSettings01,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onSyncPersonMappings(context),
        ),
      ],
    );
  }

  Widget _buildResetActionsCard(BuildContext context) {
    return SettingsGroupedCard(
      children: [
        if (wrappedService.isEnabled)
          MenuItemWidgetNew(
            title: "Recompute Ente Rewind",
            leadingIconWidget: _buildIconWidget(
              context,
              HugeIcons.strokeRoundedReload,
            ),
            trailingIcon: Icons.chevron_right_outlined,
            trailingIconIsMuted: true,
            onTap: () async => _onRecomputeWrapped(context),
          ),
        MenuItemWidgetNew(
          title: "Clear memories cache",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedDelete02,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onClearMemoriesCache(context),
        ),
        MenuItemWidgetNew(
          title: "Reset faces feedback",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedUserRemove01,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onResetFacesFeedback(context),
        ),
        MenuItemWidgetNew(
          title: "Reset faces feedback and clustering",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedUserRemove02,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onResetFacesAndClustering(context),
        ),
        MenuItemWidgetNew(
          title: "Reset all local faces",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedFaceId,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onResetAllLocalFaces(context),
        ),
        MenuItemWidgetNew(
          title: "Reset all local clip",
          leadingIconWidget: _buildIconWidget(
            context,
            HugeIcons.strokeRoundedAiSearch,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async => _onResetAllLocalClip(context),
        ),
      ],
    );
  }

  Widget _buildIconWidget(BuildContext context, List<List<dynamic>> icon) {
    final colorScheme = getEnteColorScheme(context);
    return HugeIcon(
      icon: icon,
      color: colorScheme.strokeBase,
      size: 20,
    );
  }

  Future<void> _onMLConsentChanged() async {
    try {
      final oldMlConsent = flagService.hasGrantedMLConsent;
      final mlConsent = !oldMlConsent;
      await flagService.setMLConsent(mlConsent);
      logger.info('ML consent turned ${mlConsent ? 'on' : 'off'}');
      if (!mlConsent) {
        MLService.instance.pauseIndexingAndClustering();
        unawaited(MLIndexingIsolate.instance.cleanupLocalIndexingModels());
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
      if (mounted) {
        await showGenericErrorDialog(context: context, error: e);
      }
    }
  }

  Future<void> _onRemoteFetchChanged() async {
    try {
      await localSettings.toggleRemoteFetch();
      logger.info(
        'Remote fetch is turned ${localSettings.remoteFetchEnabled ? 'on' : 'off'}',
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e, s) {
      logger.warning('Remote fetch toggle failed ', e, s);
      if (mounted) {
        await showGenericErrorDialog(context: context, error: e);
      }
    }
  }

  Future<void> _onLocalIndexingChanged() async {
    final localIndexing = await localSettings.toggleLocalMLIndexing();
    if (localIndexing) {
      unawaited(MLService.instance.runAllML(force: true));
    } else {
      MLService.instance.pauseIndexingAndClustering();
      unawaited(MLIndexingIsolate.instance.cleanupLocalIndexingModels());
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onAutoIndexingChanged() async {
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
      if (mounted) {
        await showGenericErrorDialog(context: context, error: e);
      }
    }
  }

  Future<void> _onTriggerRunML(BuildContext context) async {
    try {
      MLService.instance.debugIndexingDisabled = false;
      unawaited(MLService.instance.runAllML());
      showShortToast(context, "ML started");
    } catch (e, s) {
      logger.warning('indexAndClusterAll failed ', e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onTriggerRunIndexing(BuildContext context) async {
    try {
      MLService.instance.debugIndexingDisabled = false;
      unawaited(MLService.instance.fetchAndIndexAllImages());
      showShortToast(context, "Indexing started");
    } catch (e, s) {
      logger.warning('indexing failed ', e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onTriggerClustering(BuildContext context) async {
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
  }

  Future<void> _onUpdateDiscover(BuildContext context) async {
    try {
      await magicCacheService.updateCache(forced: true);
      showShortToast(context, "Done");
    } catch (e, s) {
      logger.warning('Update discover failed', e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onUpdateMemories(BuildContext context) async {
    try {
      final now = DateTime.now();
      await memoriesCacheService.updateCache(forced: true);
      final duration = DateTime.now().difference(now);
      showShortToast(context, "Done in ${duration.inSeconds} seconds");
    } catch (e, s) {
      logger.warning('Update memories failed', e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onSyncPersonMappings(BuildContext context) async {
    try {
      await faceRecognitionService.syncPersonFeedback();
      showShortToast(context, "Done");
    } catch (e, s) {
      logger.warning('sync person mappings failed ', e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onRecomputeWrapped(BuildContext context) async {
    try {
      await wrappedService.forceRecompute();
      await localSettings.resetWrapped2025Complete();
      showShortToast(context, "Ente Rewind recomputed");
    } catch (e, s) {
      logger.severe('Wrapped recompute failed ', e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onClearMemoriesCache(BuildContext context) async {
    try {
      final now = DateTime.now();
      await memoriesCacheService.clearMemoriesCache();
      final duration = DateTime.now().difference(now);
      showShortToast(context, "Done in ${duration.inSeconds} seconds");
    } catch (e, s) {
      logger.warning('Clear memories cache failed', e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onResetFacesFeedback(BuildContext context) async {
    await showChoiceDialog(
      context,
      title: "Are you sure?",
      body:
          "This will drop all people and their related feedback stored locally.",
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
  }

  Future<void> _onResetFacesAndClustering(BuildContext context) async {
    await showChoiceDialog(
      context,
      title: "Are you sure?",
      body:
          "This will delete all people (also from remote), their related feedback and clustering labels.",
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
  }

  Future<void> _onResetAllLocalFaces(BuildContext context) async {
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
  }

  Future<void> _onResetAllLocalClip(BuildContext context) async {
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
  }
}
