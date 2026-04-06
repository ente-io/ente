import "dart:async";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_ui/components/captioned_text_widget_v2.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget_v2.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/public_url.dart";
import "package:locker/ui/sharing/pickers/device_limit_picker_page.dart";
import "package:locker/ui/sharing/pickers/link_expiry_picker_page.dart";
import "package:locker/utils/collection_actions.dart";

class ManageSharedLinkWidget extends StatefulWidget {
  final Collection? collection;

  const ManageSharedLinkWidget({super.key, this.collection});

  @override
  State<ManageSharedLinkWidget> createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  final GlobalKey sendLinkButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    final PublicURL url = widget.collection!.publicURLs.firstOrNull!;
    final String urlValue =
        CollectionService.instance.getPublicUrl(widget.collection!);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(context.l10n.manageLink),
      ),
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MenuItemWidgetV2(
                    alignCaptionedTextToLeft: true,
                    captionedTextWidget: CaptionedTextWidgetV2(
                      title: context.l10n.linkExpiry,
                      subTitle: url.hasExpiry
                          ? (url.isExpired
                              ? context.l10n.linkExpired
                              : getFormattedTime(
                                  DateTime.fromMicrosecondsSinceEpoch(
                                    url.validTill,
                                  ),
                                ))
                          : context.l10n.never,
                      subTitleColor: url.isExpired ? warning500 : null,
                    ),
                    trailingWidget: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: enteColorScheme.textMuted,
                      size: 20,
                    ),
                    menuItemColor: enteColorScheme.fillFaint,
                    surfaceExecutionStates: false,
                    onTap: () async {
                      // ignore: unawaited_futures
                      routeToPage(
                        context,
                        LinkExpiryPickerPage(widget.collection!),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                  ),
                  const Padding(padding: EdgeInsets.only(top: 24)),
                  MenuItemWidgetV2(
                    captionedTextWidget: CaptionedTextWidgetV2(
                      title: context.l10n.linkDeviceLimit,
                      subTitle: url.deviceLimit == 0
                          ? context.l10n.noDeviceLimit
                          : "${url.deviceLimit}",
                    ),
                    trailingWidget: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: enteColorScheme.textMuted,
                      size: 20,
                    ),
                    menuItemColor: enteColorScheme.fillFaint,
                    alignCaptionedTextToLeft: true,
                    onTap: () async {
                      // ignore: unawaited_futures
                      routeToPage(
                        context,
                        DeviceLimitPickerPage(widget.collection!),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                    surfaceExecutionStates: false,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  if (url.isExpired)
                    MenuItemWidgetV2(
                      captionedTextWidget: CaptionedTextWidgetV2(
                        title: context.l10n.linkExpired,
                        textColor: getEnteColorScheme(context).warning500,
                      ),
                      leadingIcon: Icons.error_outline,
                      leadingIconColor: getEnteColorScheme(context).warning500,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      isBottomBorderRadiusRemoved: true,
                    ),
                  if (!url.isExpired)
                    MenuItemWidgetV2(
                      captionedTextWidget: CaptionedTextWidgetV2(
                        title: context.l10n.copyLink,
                        makeTextBold: true,
                      ),
                      leadingIconWidget: HugeIcon(
                        icon: HugeIcons.strokeRoundedCopy01,
                        color: enteColorScheme.textBase,
                        size: 20,
                      ),
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      showOnlyLoadingState: true,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: urlValue));
                        showShortToast(
                          context,
                          context.l10n.linkCopiedToClipboard,
                        );
                      },
                      isBottomBorderRadiusRemoved: true,
                    ),
                  if (!url.isExpired)
                    DividerWidget(
                      dividerType: DividerType.menu,
                      bgColor: getEnteColorScheme(context).fillFaint,
                    ),
                  if (!url.isExpired)
                    MenuItemWidgetV2(
                      key: sendLinkButtonKey,
                      captionedTextWidget: CaptionedTextWidgetV2(
                        title: context.l10n.sendLink,
                        makeTextBold: true,
                      ),
                      leadingIconWidget: HugeIcon(
                        icon: HugeIcons.strokeRoundedShare08,
                        color: enteColorScheme.textBase,
                        size: 20,
                      ),
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        unawaited(shareText(urlValue, context: context));
                      },
                      isTopBorderRadiusRemoved: true,
                    ),
                  const SizedBox(height: 24),
                  MenuItemWidgetV2(
                    captionedTextWidget: CaptionedTextWidgetV2(
                      title: context.l10n.removeLink,
                      textColor: warning500,
                      makeTextBold: true,
                    ),
                    leadingIconWidget: const HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: warning500,
                      size: 20,
                    ),
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    surfaceExecutionStates: false,
                    onTap: () async {
                      final bool result = await CollectionActions.disableUrl(
                        context,
                        widget.collection!,
                      );
                      if (result && mounted) {
                        Navigator.of(context).pop();
                        if (widget.collection!.isQuickLinkCollection()) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
