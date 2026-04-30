import "dart:async";

import "package:collection/collection.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/hidden_service.dart";
import "package:photos/services/local_authentication_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/base_bottom_sheet.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/tabs/shared/all_links_page.dart";
import "package:photos/ui/viewer/gallery/archive_page.dart";
import "package:photos/ui/viewer/gallery/hidden_page.dart";
import "package:photos/ui/viewer/gallery/trash_page.dart";
import "package:photos/ui/viewer/gallery/uncategorized_page.dart";

Future<void> showAlbumsManageSheet(BuildContext context) {
  final strings = AppLocalizations.of(context);
  final colorScheme = getEnteColorScheme(context);
  return showBaseBottomSheet<void>(
    backgroundColor: colorScheme.backgroundColour,
    context,
    title: strings.manage,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _manageItem(
          label: strings.trash,
          icon: HugeIcons.strokeRoundedDelete02,
          iconColor: const Color(0xFFE3505A),
          onTap: () async {
            final ok = await LocalAuthenticationService.instance
                .requestLocalAuthentication(
              context,
              strings.authToViewTrashedFiles,
            );
            if (!ok || !context.mounted) return;
            Navigator.of(context).pop();
            unawaited(routeToPage(context, TrashPage()));
          },
        ),
        const SizedBox(height: 8),
        _manageItem(
          label: strings.archive,
          icon: HugeIcons.strokeRoundedArchive,
          iconColor: const Color(0xFF08C225),
          onTap: () async {
            Navigator.of(context).pop();
            unawaited(routeToPage(context, ArchivePage()));
          },
        ),
        const SizedBox(height: 8),
        _manageItem(
          label: strings.hidden,
          icon: HugeIcons.strokeRoundedViewOffSlash,
          iconColor: const Color(0xFFE19714),
          onTap: () async {
            final ok = await LocalAuthenticationService.instance
                .requestLocalAuthentication(
              context,
              strings.authToViewYourHiddenFiles,
            );
            if (!ok || !context.mounted) return;
            Navigator.of(context).pop();
            unawaited(routeToPage(context, const HiddenPage()));
          },
        ),
        const SizedBox(height: 8),
        _manageItem(
          label: strings.uncategorized,
          icon: HugeIcons.strokeRoundedHelpCircle,
          iconColor: colorScheme.textMuted,
          onTap: () async {
            Collection? collection = CollectionsService.instance
                .getActiveCollections()
                .firstWhereOrNull(
                  (c) => c.type == CollectionType.uncategorized,
                );
            collection ??=
                await CollectionsService.instance.getUncategorizedCollection();
            if (!context.mounted) return;
            Navigator.of(context).pop();
            unawaited(routeToPage(context, UnCategorizedPage(collection)));
          },
        ),
        const SizedBox(height: 8),
        _manageItem(
          label: strings.links,
          icon: HugeIcons.strokeRoundedLink02,
          iconColor: const Color(0xFF4080DA),
          onTap: () async {
            final data = await CollectionsService.instance
                .getSharedCollectionsAndMemoryLinks();
            if (!context.mounted) return;
            Navigator.of(context).pop();
            unawaited(
              routeToPage(
                context,
                AllLinksPage(
                  quickLinks: data.collections.quickLinks,
                  memoryShares: data.memoryLinks,
                  titleHeroTag: "manage_links",
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

Widget _manageItem({
  required String label,
  required List<List<dynamic>> icon,
  required Color iconColor,
  required Future<void> Function() onTap,
}) {
  return MenuItemWidgetNew(
    title: label,
    padding: const EdgeInsets.all(12),
    leadingIconSize: 34,
    leadingIconWidget: SizedBox(
      width: 34,
      height: 34,
      child: Center(
        child: HugeIcon(icon: icon, size: 18, color: iconColor),
      ),
    ),
    trailingIcon: Icons.chevron_right_rounded,
    onTap: onTap,
  );
}
