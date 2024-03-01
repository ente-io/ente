import "dart:async";

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:photos/core/event_bus.dart";
import 'package:photos/events/embedding_updated_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/services/feature_flag_service.dart";
import 'package:photos/services/machine_learning/semantic_search/frameworks/ml_framework.dart';
import 'package:photos/services/machine_learning/semantic_search/semantic_search_service.dart';
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
import "package:photos/utils/local_settings.dart";

class MachineLearningSettingsPage extends StatefulWidget {
  const MachineLearningSettingsPage({super.key});

  @override
  State<MachineLearningSettingsPage> createState() =>
      _MachineLearningSettingsPageState();
}

class _MachineLearningSettingsPageState
    extends State<MachineLearningSettingsPage> {
  late InitializationState _state;

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
  }

  void _fetchState() {
    _state = SemanticSearchService.instance.getFrameworkInitializationState();
  }

  @override
  void dispose() {
    super.dispose();
    _eventSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
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
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
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
          height: 4,
        ),
        MenuSectionDescriptionWidget(
          content: S.of(context).magicSearchDescription,
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
                  FeatureFlagService.instance.isInternalUserOrDebugBuild()
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
}

class ModelLoadingState extends StatelessWidget {
  final InitializationState state;

  const ModelLoadingState(
    this.state, {
    Key? key,
  }) : super(key: key);

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
      ],
    );
  }

  String _getTitle(BuildContext context) {
    switch (state) {
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
  late StreamSubscription<EmbeddingUpdatedEvent> _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription =
        Bus.instance.on<EmbeddingUpdatedEvent>().listen((event) {
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
