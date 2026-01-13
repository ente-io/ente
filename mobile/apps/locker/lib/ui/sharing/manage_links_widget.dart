import "dart:convert";

import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/menu_section_description_widget.dart";
import "package:ente_ui/components/toggle_switch_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_api_client.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/public_url.dart";
import "package:locker/ui/sharing/pickers/device_limit_picker_page.dart";
import "package:locker/ui/sharing/pickers/link_expiry_picker_page.dart";
import "package:locker/utils/collection_actions.dart";
import "package:locker/utils/date_time_util.dart" as locker_date;


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
    final isCollectEnabled =
        widget.collection!.publicURLs.firstOrNull?.enableCollect ?? false;
    final isDownloadEnabled =
        widget.collection!.publicURLs.firstOrNull?.enableDownload ?? true;
    final isPasswordEnabled =
        widget.collection!.publicURLs.firstOrNull?.passwordEnabled ?? false;
    final enteColorScheme = getEnteColorScheme(context);
    final PublicURL url = widget.collection!.publicURLs.firstOrNull!;
    final String urlValue =
        CollectionService.instance.getPublicUrl(widget.collection!);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
                  MenuItemWidget(
                    key: ValueKey("Allow collect $isCollectEnabled"),
                    captionedTextWidget: CaptionedTextWidget(
                      title: context.l10n.allowAddingFiles,
                    ),
                    alignCaptionedTextToLeft: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: ToggleSwitchWidget(
                      value: () => isCollectEnabled,
                      onChanged: () async {
                        await _updateUrlSettings(
                          context,
                          {'enableCollect': !isCollectEnabled},
                        );
                      },
                    ),
                  ),
                  MenuSectionDescriptionWidget(
                    content: context.l10n.allowAddFilesDescription,
                  ),
                  const SizedBox(height: 24),
                  MenuItemWidget(
                    alignCaptionedTextToLeft: true,
                    captionedTextWidget: CaptionedTextWidget(
                      title: context.l10n.linkExpiry,
                      subTitle: (url.hasExpiry
                          ? (url.isExpired
                              ? context.l10n.linkExpired
                              : context.l10n.linkEnabled)
                          : context.l10n.linkNeverExpires),
                      subTitleColor: url.isExpired ? warning500 : null,
                    ),
                    trailingIcon: Icons.chevron_right,
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
                  url.hasExpiry
                      ? MenuSectionDescriptionWidget(
                          content: url.isExpired
                              ? context.l10n.expiredLinkInfo
                              : context.l10n.linkExpiresOn(
                                  locker_date.getFormattedTime(
                                    DateTime.fromMicrosecondsSinceEpoch(
                                      url.validTill,
                                    ),
                                  ),
                                ),
                        )
                      : const SizedBox.shrink(),
                  const Padding(padding: EdgeInsets.only(top: 24)),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: context.l10n.linkDeviceLimit,
                      subTitle: url.deviceLimit == 0
                          ? context.l10n.noDeviceLimit
                          : "${url.deviceLimit}",
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
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
                  DividerWidget(
                    dividerType: DividerType.menuNoIcon,
                    bgColor: getEnteColorScheme(context).fillFaint,
                  ),
                  MenuItemWidget(
                    key: ValueKey("Allow downloads $isDownloadEnabled"),
                    captionedTextWidget: CaptionedTextWidget(
                      title: context.l10n.allowDownloads,
                    ),
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: ToggleSwitchWidget(
                      value: () => isDownloadEnabled,
                      onChanged: () async {
                        await _updateUrlSettings(
                          context,
                          {'enableDownload': !isDownloadEnabled},
                        );
                        if (isDownloadEnabled) {
                          // ignore: unawaited_futures
                          showErrorDialog(
                            context,
                            context.l10n.disableDownloadWarningTitle,
                            context.l10n.disableDownloadWarningBody,
                          );
                        }
                      },
                    ),
                  ),
                  DividerWidget(
                    dividerType: DividerType.menuNoIcon,
                    bgColor: getEnteColorScheme(context).fillFaint,
                  ),
                  MenuItemWidget(
                    key: ValueKey("Password lock $isPasswordEnabled"),
                    captionedTextWidget: CaptionedTextWidget(
                      title: context.l10n.passwordLock,
                    ),
                    alignCaptionedTextToLeft: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: ToggleSwitchWidget(
                      value: () => isPasswordEnabled,
                      onChanged: () async {
                        if (!isPasswordEnabled) {
                          // ignore: unawaited_futures
                          showTextInputDialog(
                            context,
                            title: context.l10n.setPasswordTitle,
                            submitButtonLabel: context.l10n.lockButtonLabel,
                            hintText: context.l10n.enterPassword,
                            isPasswordInput: true,
                            alwaysShowSuccessState: true,
                            onSubmit: (String password) async {
                              if (password.trim().isNotEmpty) {
                                final propToUpdate =
                                    await _getEncryptedPassword(
                                  password,
                                );
                                await _updateUrlSettings(
                                  context,
                                  propToUpdate,
                                  showProgressDialog: false,
                                );
                              }
                            },
                          );
                        } else {
                          await _updateUrlSettings(
                            context,
                            {'disablePassword': true},
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  if (url.isExpired)
                    MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: context.l10n.linkExpired,
                        textColor: getEnteColorScheme(context).warning500,
                      ),
                      leadingIcon: Icons.error_outline,
                      leadingIconColor: getEnteColorScheme(context).warning500,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      isBottomBorderRadiusRemoved: true,
                    ),
                  if (!url.isExpired)
                    MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: context.l10n.copyLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.copy,
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
                    MenuItemWidget(
                      key: sendLinkButtonKey,
                      captionedTextWidget: CaptionedTextWidget(
                        title: context.l10n.sendLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.adaptive.share,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        // ignore: unawaited_futures
                        await shareText(
                          urlValue,
                          context: context,
                        );
                      },
                      isTopBorderRadiusRemoved: true,
                    ),
                  const SizedBox(height: 24),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: context.l10n.removeLink,
                      textColor: warning500,
                      makeTextBold: true,
                    ),
                    leadingIcon: Icons.remove_circle_outline,
                    leadingIconColor: warning500,
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

  Future<Map<String, dynamic>> _getEncryptedPassword(String pass) async {
    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final result = await CryptoUtil.deriveInteractiveKey(
      utf8.encode(pass),
      kekSalt,
    );
    return {
      'passHash': CryptoUtil.bin2base64(result.key),
      'nonce': CryptoUtil.bin2base64(kekSalt),
      'memLimit': result.memLimit,
      'opsLimit': result.opsLimit,
    };
  }

  Future<void> _updateUrlSettings(
    BuildContext context,
    Map<String, dynamic> prop, {
    bool showProgressDialog = true,
  }) async {
    final dialog = showProgressDialog
        ? createProgressDialog(context, context.l10n.pleaseWait)
        : null;
    await dialog?.show();
    try {
      await CollectionApiClient.instance
          .updateShareUrl(widget.collection!, prop);
      await dialog?.hide();
      showShortToast(context, "Collection updated");
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      await dialog?.hide();
      await showGenericErrorDialog(context: context, error: e);
      rethrow;
    }
  }
}
