import 'package:flutter/material.dart';
import 'package:photos/db/social_db.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/social_sync_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/notification/toast.dart';

class SocialDebugScreen extends StatelessWidget {
  const SocialDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "Social debug",
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Trigger social sync",
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.strokeBase,
                        ),
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        onTap: () async {
                          await SocialSyncService.instance
                              .syncAllSharedCollections();
                          showShortToast(context, "Social sync completed");
                        },
                      ),
                      const SizedBox(height: 24),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Trigger collection sync",
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.strokeBase,
                        ),
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        onTap: () async {
                          await CollectionsService.instance.sync();
                          showShortToast(context, "Collection sync completed");
                        },
                      ),
                      const SizedBox(height: 24),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Seed example data",
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.strokeBase,
                        ),
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        onTap: () async {
                          await SocialDB.instance.seedExampleData();
                          showShortToast(context, "Example data seeded");
                        },
                      ),
                      const SizedBox(height: 24),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Delete all comments",
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.strokeBase,
                        ),
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        onTap: () async {
                          final count =
                              await SocialDB.instance.deleteAllComments();
                          showShortToast(context, "Deleted $count comments");
                        },
                      ),
                      const SizedBox(height: 24),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Delete all reactions",
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.strokeBase,
                        ),
                        singleBorderRadius: 8,
                        alignCaptionedTextToLeft: true,
                        onTap: () async {
                          final count =
                              await SocialDB.instance.deleteAllReactions();
                          showShortToast(context, "Deleted $count reactions");
                        },
                      ),
                    ],
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
}
