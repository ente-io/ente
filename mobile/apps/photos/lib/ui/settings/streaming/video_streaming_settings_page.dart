import "dart:async";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/video_preview_state_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/preview/preview_item_status.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";

const helpUrl =
    "https://ente.io/help/photos/features/utilities/video-streaming#related-faqs";

class VideoStreamingSettingsPage extends StatefulWidget {
  const VideoStreamingSettingsPage({super.key});

  @override
  State<VideoStreamingSettingsPage> createState() =>
      _VideoStreamingSettingsPageState();
}

class _VideoStreamingSettingsPageState
    extends State<VideoStreamingSettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    final hasEnabled = VideoPreviewService.instance.isVideoStreamingEnabled;

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      bottomNavigationBar: !hasEnabled
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    ButtonWidget(
                      buttonType: ButtonType.primary,
                      labelText: context.l10n.enable,
                      onTap: () async {
                        await toggleVideoStreaming();
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
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
                AppLocalizations.of(context).videoStreaming,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: hasEnabled
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: AppLocalizations.of(context)
                                        .videoStreamingDescriptionLine1,
                                  ),
                                  const TextSpan(text: " "),
                                  TextSpan(
                                    text: AppLocalizations.of(context)
                                        .videoStreamingDescriptionLine2,
                                  ),
                                  const TextSpan(text: " "),
                                  TextSpan(
                                    text: AppLocalizations.of(context)
                                        .moreDetails,
                                    style: TextStyle(
                                      color: colorScheme.primary500,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = openHelp,
                                  ),
                                ],
                              ),
                              style: textTheme.mini
                                  .copyWith(color: colorScheme.textMuted),
                            ),
                            const SizedBox(height: 24),
                            MenuItemWidgetNew(
                              title: AppLocalizations.of(context).enabled,
                              trailingWidget: ToggleSwitchWidget(
                                value: () => hasEnabled,
                                onChanged: () async {
                                  await toggleVideoStreaming();
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            const VideoStreamingStatusWidget(),
                          ],
                        ),
                      )
                    : Center(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Image.asset(
                                "assets/enable-streaming-static.png",
                                height: 160,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: AppLocalizations.of(context)
                                            .videoStreamingDescriptionLine1,
                                      ),
                                      const TextSpan(text: "\n"),
                                      TextSpan(
                                        text: AppLocalizations.of(context)
                                            .videoStreamingDescriptionLine2,
                                      ),
                                      const TextSpan(text: "\n"),
                                      TextSpan(
                                        text: AppLocalizations.of(context)
                                            .moreDetails,
                                        style: TextStyle(
                                          color: colorScheme.primary500,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = openHelp,
                                      ),
                                    ],
                                  ),
                                  style: textTheme.smallMuted,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openHelp() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return WebPage(AppLocalizations.of(context).help, helpUrl);
        },
      ),
    ).ignore();
  }

  Future<void> toggleVideoStreaming() async {
    final isEnabled = VideoPreviewService.instance.isVideoStreamingEnabled;

    await VideoPreviewService.instance.setIsVideoStreamingEnabled(!isEnabled);
    if (!mounted) return;
    setState(() {});
  }
}

class VideoStreamingStatusWidget extends StatefulWidget {
  const VideoStreamingStatusWidget({super.key});

  @override
  State<VideoStreamingStatusWidget> createState() =>
      VideoStreamingStatusWidgetState();
}

class VideoStreamingStatusWidgetState
    extends State<VideoStreamingStatusWidget> {
  double? _netProcessed;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    init();
    _subscription =
        Bus.instance.on<VideoPreviewStateChangedEvent>().listen((event) {
      final status = event.status;

      // Handle different states
      switch (status) {
        case PreviewItemStatus.uploaded:
          init();
          break;
        default:
      }
    });
  }

  Future<void> init() async {
    _netProcessed = await VideoPreviewService.instance.getStatus();
    setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Column(
      children: [
        if (_netProcessed != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuItemWidgetNew(
                title: AppLocalizations.of(context).processed,
                trailingWidget: Text(
                  _netProcessed == 0
                      ? '0%'
                      : '${(_netProcessed! * 100.0).toStringAsFixed(2)}%',
                  style: textTheme.small,
                ),
                key: ValueKey("processed_items_$_netProcessed"),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context).videoStreamingNote,
                  style: textTheme.mini.copyWith(color: colorScheme.textMuted),
                ),
              ),
            ],
          )
        else
          const EnteLoadingWidget(),
      ],
    );
  }
}
