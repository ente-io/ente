import "package:flutter/material.dart";
import "package:photos/db/social_db.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/social_sync_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/notification/toast.dart";

class SocialDebugScreen extends StatelessWidget {
  const SocialDebugScreen({super.key});

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
                "Social debug",
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MenuItemWidgetNew(
                        title: "Trigger social sync",
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await SocialSyncService.instance
                              .syncAllSharedCollections();
                          showShortToast(context, "Social sync completed");
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: "Trigger collection sync",
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await CollectionsService.instance.sync();
                          showShortToast(context, "Collection sync completed");
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: "Seed example data",
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await SocialDB.instance.seedExampleData();
                          showShortToast(context, "Example data seeded");
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: "Delete all comments",
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          final count =
                              await SocialDB.instance.deleteAllComments();
                          showShortToast(context, "Deleted $count comments");
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: "Delete all reactions",
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          final count =
                              await SocialDB.instance.deleteAllReactions();
                          showShortToast(context, "Deleted $count reactions");
                        },
                      ),
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
}
