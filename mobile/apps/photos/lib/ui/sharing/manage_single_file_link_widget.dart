import "dart:convert";

import "package:ente_crypto/ente_crypto.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/file_share_url.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/single_file_share_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/menu_section_description_widget.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/sharing/pickers/single_file_device_limit_picker_page.dart";
import "package:photos/ui/sharing/pickers/single_file_link_expiry_picker_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/share_util.dart";
import "package:photos/utils/standalone/date_time.dart";

class ManageSingleFileLinkWidget extends StatefulWidget {
  final FileShareUrl fileShareUrl;
  final EnteFile? file;

  const ManageSingleFileLinkWidget({
    super.key,
    required this.fileShareUrl,
    this.file,
  });

  @override
  State<ManageSingleFileLinkWidget> createState() =>
      _ManageSingleFileLinkWidgetState();
}

class _ManageSingleFileLinkWidgetState
    extends State<ManageSingleFileLinkWidget> {
  final GlobalKey sendLinkButtonKey = GlobalKey();
  late FileShareUrl _fileShareUrl;

  @override
  void initState() {
    super.initState();
    _fileShareUrl = widget.fileShareUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isDownloadEnabled = _fileShareUrl.enableDownload;
    final isPasswordEnabled = _fileShareUrl.passwordEnabled;
    final enteColorScheme = getEnteColorScheme(context);
    final urlValue = _fileShareUrl.url;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).manageLink),
      ),
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Link Expiry
                  MenuItemWidget(
                    alignCaptionedTextToLeft: true,
                    captionedTextWidget: CaptionedTextWidget(
                      title: AppLocalizations.of(context).linkExpiry,
                      subTitle: (_fileShareUrl.hasExpiry
                          ? (_fileShareUrl.isExpired
                              ? AppLocalizations.of(context).linkExpired
                              : AppLocalizations.of(context).linkEnabled)
                          : AppLocalizations.of(context).linkNeverExpires),
                      subTitleColor:
                          _fileShareUrl.isExpired ? warning500 : null,
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    surfaceExecutionStates: false,
                    onTap: () async {
                      await routeToPage(
                        context,
                        SingleFileLinkExpiryPickerPage(
                          fileShareUrl: _fileShareUrl,
                          onUpdate: _onShareUrlUpdated,
                        ),
                      );
                    },
                  ),
                  _fileShareUrl.hasExpiry
                      ? MenuSectionDescriptionWidget(
                          content: _fileShareUrl.isExpired
                              ? AppLocalizations.of(context).expiredLinkInfo
                              : AppLocalizations.of(context).linkExpiresOn(
                                  expiryTime: getFormattedTime(
                                    context,
                                    DateTime.fromMicrosecondsSinceEpoch(
                                      _fileShareUrl.validTill,
                                    ),
                                  ),
                                ),
                        )
                      : const SizedBox.shrink(),
                  const Padding(padding: EdgeInsets.only(top: 24)),
                  // Device Limit
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: AppLocalizations.of(context).linkDeviceLimit,
                      subTitle: _fileShareUrl.deviceLimit == 0
                          ? AppLocalizations.of(context).noDeviceLimit
                          : "${_fileShareUrl.deviceLimit}",
                    ),
                    trailingIcon: Icons.chevron_right,
                    menuItemColor: enteColorScheme.fillFaint,
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    onTap: () async {
                      await routeToPage(
                        context,
                        SingleFileDeviceLimitPickerPage(
                          fileShareUrl: _fileShareUrl,
                          onUpdate: _onShareUrlUpdated,
                        ),
                      );
                    },
                    surfaceExecutionStates: false,
                  ),
                  DividerWidget(
                    dividerType: DividerType.menuNoIcon,
                    bgColor: enteColorScheme.fillFaint,
                  ),
                  // Allow Downloads
                  MenuItemWidget(
                    key: ValueKey("Allow downloads $isDownloadEnabled"),
                    captionedTextWidget: CaptionedTextWidget(
                      title: AppLocalizations.of(context).allowDownloads,
                    ),
                    alignCaptionedTextToLeft: true,
                    isBottomBorderRadiusRemoved: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: enteColorScheme.fillFaint,
                    trailingWidget: ToggleSwitchWidget(
                      value: () => isDownloadEnabled,
                      onChanged: () async {
                        await _updateUrlSettings(context, {
                          "enableDownload": !isDownloadEnabled,
                        });
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
                    bgColor: enteColorScheme.fillFaint,
                  ),
                  // Password Lock
                  MenuItemWidget(
                    key: ValueKey("Password lock $isPasswordEnabled"),
                    captionedTextWidget: CaptionedTextWidget(
                      title: AppLocalizations.of(context).passwordLock,
                    ),
                    alignCaptionedTextToLeft: true,
                    isTopBorderRadiusRemoved: true,
                    menuItemColor: enteColorScheme.fillFaint,
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
                                    await _getEncryptedPassword(password);
                                await _updateUrlSettings(
                                  context,
                                  propToUpdate,
                                  showProgressDialog: false,
                                );
                              }
                            },
                          );
                        } else {
                          await _updateUrlSettings(context, {
                            "disablePassword": true,
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Link actions
                  if (_fileShareUrl.isExpired)
                    MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: AppLocalizations.of(context).linkHasExpired,
                        textColor: enteColorScheme.warning500,
                      ),
                      leadingIcon: Icons.error_outline,
                      leadingIconColor: enteColorScheme.warning500,
                      menuItemColor: enteColorScheme.fillFaint,
                      isBottomBorderRadiusRemoved: true,
                    ),
                  if (!_fileShareUrl.isExpired)
                    MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: AppLocalizations.of(context).copyLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.copy,
                      menuItemColor: enteColorScheme.fillFaint,
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
                  if (!_fileShareUrl.isExpired)
                    DividerWidget(
                      dividerType: DividerType.menu,
                      bgColor: enteColorScheme.fillFaint,
                    ),
                  if (!_fileShareUrl.isExpired)
                    MenuItemWidget(
                      key: sendLinkButtonKey,
                      captionedTextWidget: CaptionedTextWidget(
                        title: AppLocalizations.of(context).sendLink,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.adaptive.share,
                      menuItemColor: enteColorScheme.fillFaint,
                      onTap: () async {
                        await shareText(
                          urlValue,
                          context: context,
                          key: sendLinkButtonKey,
                        );
                      },
                      isTopBorderRadiusRemoved: true,
                    ),
                  const SizedBox(height: 24),
                  // Remove Link
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: AppLocalizations.of(context).removeLink,
                      textColor: warning500,
                      makeTextBold: true,
                    ),
                    leadingIcon: Icons.remove_circle_outline,
                    leadingIconColor: warning500,
                    menuItemColor: enteColorScheme.fillFaint,
                    surfaceExecutionStates: false,
                    onTap: () async {
                      await _removeLink();
                    },
                  ),
                  const SizedBox(height: 24),
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
      "passHash": CryptoUtil.bin2base64(result.key),
      "nonce": CryptoUtil.bin2base64(kekSalt),
      "memLimit": result.memLimit,
      "opsLimit": result.opsLimit,
    };
  }

  Future<void> _updateUrlSettings(
    BuildContext context,
    Map<String, dynamic> prop, {
    bool showProgressDialog = true,
  }) async {
    final dialog = showProgressDialog
        ? createProgressDialog(
            context,
            AppLocalizations.of(context).pleaseWait,
          )
        : null;
    await dialog?.show();
    try {
      await SingleFileShareService.instance.updateShareUrl(
        _fileShareUrl.fileID,
        prop,
      );
      // Refresh the share URL
      final updatedUrl = SingleFileShareService.instance
          .getCachedShareUrl(_fileShareUrl.fileID);
      if (updatedUrl != null && mounted) {
        setState(() {
          _fileShareUrl = updatedUrl;
        });
      }
      await dialog?.hide();
      showShortToast(context, AppLocalizations.of(context).albumUpdated);
    } catch (e) {
      await dialog?.hide();
      await showGenericErrorDialog(context: context, error: e);
      rethrow;
    }
  }

  void _onShareUrlUpdated(FileShareUrl updatedUrl) {
    if (mounted) {
      setState(() {
        _fileShareUrl = updatedUrl;
      });
    }
  }

  Future<void> _removeLink() async {
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).pleaseWait,
    );
    await dialog.show();
    try {
      await SingleFileShareService.instance
          .disableShareUrl(_fileShareUrl.fileID);
      await dialog.hide();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }
}
