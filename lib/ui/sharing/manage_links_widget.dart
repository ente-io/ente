import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import "package:fast_base58/fast_base58.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/public_url.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/sharing/pickers/device_limit_picker_page.dart';
import 'package:photos/ui/sharing/pickers/link_expiry_picker_page.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import "package:photos/utils/share_util.dart";
import 'package:photos/utils/toast_util.dart';

class ManageSharedLinkWidget extends StatefulWidget {
  final Collection? collection;

  const ManageSharedLinkWidget({Key? key, this.collection}) : super(key: key);

  @override
  State<ManageSharedLinkWidget> createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  final CollectionActions sharingActions =
      CollectionActions(CollectionsService.instance);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isCollectEnabled =
        widget.collection!.publicURLs?.firstOrNull?.enableCollect ?? false;
    final isDownloadEnabled =
        widget.collection!.publicURLs?.firstOrNull?.enableDownload ?? true;
    final isPasswordEnabled =
        widget.collection!.publicURLs?.firstOrNull?.passwordEnabled ?? false;
    final enteColorScheme = getEnteColorScheme(context);
    final PublicURL url = widget.collection!.publicURLs!.firstOrNull!;
    final String collectionKey = Base58Encode(
      CollectionsService.instance.getCollectionKey(widget.collection!.id),
    );
    final String urlValue = "${url.url}#$collectionKey";
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          S.of(context).manageLink,
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
                      title: S.of(context).allowAddingPhotos,
                    ),
                    alignCaptionedTextToLeft: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: widget.collection!.publicURLs?.firstOrNull
                              ?.enableCollect ??
                          false,
                      onChanged: (value) async {
                        await _updateUrlSettings(
                          context,
                          {'enableCollect': value},
                        );
                      },
                    ),
                  ),
                  MenuSectionDescriptionWidget(
                    content: S.of(context).allowAddPhotosDescription,
                  ),
                  const SizedBox(height: 24),
                  MenuItemWidget(
                    alignCaptionedTextToLeft: true,
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).linkExpiry,
                      subTitle: (url.hasExpiry
                          ? (url.isExpired
                              ? S.of(context).linkExpired
                              : S.of(context).linkEnabled)
                          : S.of(context).linkNeverExpires),
                      subTitleColor: url.isExpired ? warning500 : null,
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    surfaceExecutionStates: false,
                    onTap: () async {
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
                              ? S.of(context).expiredLinkInfo
                              : S.of(context).linkExpiresOn(
                                    getFormattedTime(
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
                      title: S.of(context).linkDeviceLimit,
                      subTitle: widget
                          .collection!.publicURLs!.first!.deviceLimit
                          .toString(),
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    onTap: () async {
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
                      title: S.of(context).allowDownloads,
                    ),
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: isDownloadEnabled,
                      onChanged: (value) async {
                        await _updateUrlSettings(
                          context,
                          {'enableDownload': value},
                        );
                        if (!value) {
                          showErrorDialog(
                            context,
                            S.of(context).disableDownloadWarningTitle,
                            S.of(context).disableDownloadWarningBody,
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
                      title: S.of(context).passwordLock,
                    ),
                    alignCaptionedTextToLeft: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: getEnteColorScheme(context).fillFaint,
                    trailingWidget: Switch.adaptive(
                      value: isPasswordEnabled,
                      onChanged: (enablePassword) async {
                        if (enablePassword) {
                          showTextInputDialog(
                            context,
                            title: S.of(context).setAPassword,
                            submitButtonLabel: S.of(context).lockButtonLabel,
                            hintText: S.of(context).enterPassword,
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
                        title: S.of(context).linkHasExpired,
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
                        title: S.of(context).copyLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.copy,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      showOnlyLoadingState: true,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: urlValue));
                        showShortToast(
                            context, S.of(context).linkCopiedToClipboard);
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
                      captionedTextWidget: CaptionedTextWidget(
                        title: S.of(context).sendLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.adaptive.share,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        shareText(urlValue);
                      },
                      isTopBorderRadiusRemoved: true,
                    ),
                  const SizedBox(
                    height: 24,
                  ),
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).removeLink,
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
      utf8.encode(pass) as Uint8List,
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
        ? createProgressDialog(context, S.of(context).pleaseWait)
        : null;
    await dialog?.show();
    try {
      await CollectionsService.instance
          .updateShareUrl(widget.collection!, prop);
      await dialog?.hide();
      showShortToast(context, S.of(context).albumUpdated);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      await dialog?.hide();
      await showGenericErrorDialog(context: context);
      rethrow;
    }
  }
}
