import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/public_url.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import "package:photos/ui/components/toggle_switch_widget.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/sharing/pickers/device_limit_picker_page.dart';
import 'package:photos/ui/sharing/pickers/link_expiry_picker_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import "package:photos/utils/share_util.dart";
import 'package:photos/utils/standalone/date_time.dart';

class ManageSharedLinkWidget extends StatefulWidget {
  final Collection? collection;

  const ManageSharedLinkWidget({super.key, this.collection});

  @override
  State<ManageSharedLinkWidget> createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  final CollectionActions sharingActions =
      CollectionActions(CollectionsService.instance);
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
        CollectionsService.instance.getPublicUrl(widget.collection!);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).manageLink,
        ),
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
                      title: AppLocalizations.of(context).allowAddingPhotos,
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
                    content:
                        AppLocalizations.of(context).allowAddPhotosDescription,
                  ),
                  const SizedBox(height: 24),
                  MenuItemWidget(
                    alignCaptionedTextToLeft: true,
                    captionedTextWidget: CaptionedTextWidget(
                      title: AppLocalizations.of(context).linkExpiry,
                      subTitle: (url.hasExpiry
                          ? (url.isExpired
                              ? AppLocalizations.of(context).linkExpired
                              : AppLocalizations.of(context).linkEnabled)
                          : AppLocalizations.of(context).linkNeverExpires),
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
                              ? AppLocalizations.of(context).expiredLinkInfo
                              : AppLocalizations.of(context).linkExpiresOn(
                                  expiryTime: getFormattedTime(
                                    context,
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
                      title: AppLocalizations.of(context).linkDeviceLimit,
                      subTitle: url.deviceLimit == 0
                          ? AppLocalizations.of(context).noDeviceLimit
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
                      title: AppLocalizations.of(context).allowDownloads,
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
                            AppLocalizations.of(context)
                                .disableDownloadWarningTitle,
                            AppLocalizations.of(context)
                                .disableDownloadWarningBody,
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
                      title: AppLocalizations.of(context).passwordLock,
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
                            title: AppLocalizations.of(context).setAPassword,
                            submitButtonLabel:
                                AppLocalizations.of(context).lockButtonLabel,
                            hintText:
                                AppLocalizations.of(context).enterPassword,
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
                        title: AppLocalizations.of(context).linkHasExpired,
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
                        title: AppLocalizations.of(context).copyLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.copy,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      showOnlyLoadingState: true,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: urlValue));
                        showShortToast(
                          context,
                          AppLocalizations.of(context).linkCopiedToClipboard,
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
                        title: AppLocalizations.of(context).sendLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.adaptive.share,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        // ignore: unawaited_futures
                        await shareAlbumLinkWithPlaceholder(
                          context,
                          widget.collection!,
                          urlValue,
                          sendLinkButtonKey,
                        );
                      },
                      isTopBorderRadiusRemoved: true,
                    ),
                  const SizedBox(
                    height: 24,
                  ),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: AppLocalizations.of(context).removeLink,
                      textColor: warning500,
                      makeTextBold: true,
                    ),
                    leadingIcon: Icons.remove_circle_outline,
                    leadingIconColor: warning500,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    surfaceExecutionStates: false,
                    onTap: () async {
                      final bool result = await sharingActions.disableUrl(
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
        ? createProgressDialog(context, AppLocalizations.of(context).pleaseWait)
        : null;
    await dialog?.show();
    try {
      await CollectionsService.instance
          .updateShareUrl(widget.collection!, prop);
      await dialog?.hide();
      showShortToast(context, AppLocalizations.of(context).albumUpdated);
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
