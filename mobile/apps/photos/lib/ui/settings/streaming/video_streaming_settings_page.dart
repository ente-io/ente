import "dart:async";

import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/menu_section_title.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";

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
    final hasEnabled = flagService.hasGrantedMLConsent;
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).videoStreaming,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  Text(
                    S.of(context).videoStreamingDescription,
                    textAlign: TextAlign.left,
                    style: getEnteTextTheme(context).mini.copyWith(
                          color: getEnteColorScheme(context).textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (hasEnabled)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(top: 20),
                child: _getMlSettings(context),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.primary,
                      labelText: context.l10n.enable,
                      onTap: () async {
                        await toggleVideoStreaming();
                      },
                    ),
                    const SizedBox(height: 12),
                    ButtonWidget(
                      buttonType: ButtonType.secondary,
                      labelText: context.l10n.moreDetails,
                      onTap: () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return WebPage(
                                S.of(context).help,
                                "https://help.ente.io/photos/faq/video-streaming",
                              );
                            },
                          ),
                        ).ignore();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> toggleVideoStreaming() async {
    final isEnabled = VideoPreviewService.instance.isVideoStreamingEnabled;

    await VideoPreviewService.instance.setIsVideoStreamingEnabled(!isEnabled);
  }

  Widget _getMlSettings(BuildContext context) {
    final hasEnabled = flagService.hasGrantedMLConsent;
    if (!hasEnabled) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).enabled,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => hasEnabled,
            onChanged: () async {
              await toggleVideoStreaming();
            },
          ),
          singleBorderRadius: 8,
          isGestureDetectorDisabled: true,
        ),
        const SizedBox(height: 12),
        const VideoStreamingStatusWidget(),
      ],
    );
  }
}

class VideoStreamingStatusWidget extends StatefulWidget {
  const VideoStreamingStatusWidget({
    super.key,
  });

  @override
  State<VideoStreamingStatusWidget> createState() =>
      VideoStreamingStatusWidgetState();
}

class VideoStreamingStatusWidgetState
    extends State<VideoStreamingStatusWidget> {
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
    return Column(
      children: [
        Row(
          children: [
            MenuSectionTitle(title: S.of(context).status),
            Expanded(child: Container()),
          ],
        ),
        FutureBuilder(
          future: VideoPreviewService.instance.getStatus(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final double netProcessed = snapshot.data!.netProcessedItems;
              final int processed = snapshot.data!.processed;
              final int total = snapshot.data!.total;

              return Column(
                children: [
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).processed,
                    ),
                    trailingWidget: Text(
                      total < 1
                          ? 'NA'
                          : netProcessed == 0
                              ? '0%'
                              : '${(netProcessed * 100.0).toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    singleBorderRadius: 8,
                    alignCaptionedTextToLeft: true,
                    isGestureDetectorDisabled: true,
                    key: ValueKey("pending_items_" + netProcessed.toString()),
                  ),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).videosProcessed,
                    ),
                    trailingWidget: Text(
                      '$processed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    singleBorderRadius: 8,
                    alignCaptionedTextToLeft: true,
                    isGestureDetectorDisabled: true,
                    key: ValueKey(
                      "videos_processed_item_" + processed.toString(),
                    ),
                  ),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).totalVideos,
                    ),
                    trailingWidget: Text(
                      '$processed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    singleBorderRadius: 8,
                    alignCaptionedTextToLeft: true,
                    isGestureDetectorDisabled: true,
                    key: ValueKey("total_videos_item_" + total.toString()),
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
