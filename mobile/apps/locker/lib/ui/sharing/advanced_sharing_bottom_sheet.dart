import "dart:convert";

import "package:ente_crypto_dart/ente_crypto_dart.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/toggle_switch_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/navigation_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_api_client.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/public_url.dart";
import "package:locker/ui/sharing/pickers/device_limit_picker_page.dart";
import "package:locker/ui/sharing/pickers/link_expiry_picker_page.dart";
import "package:locker/utils/collection_actions.dart";

/// A bottom sheet widget for advanced sharing options.
///
/// This widget provides advanced configuration options for:
/// - Sharing settings (enabled/disabled, download permissions)
/// - Public link settings (enable/disable, downloads, uploads, password protection)
/// - Device limits and link expiry settings
class AdvancedSharingBottomSheet extends StatefulWidget {
  final Collection collection;

  const AdvancedSharingBottomSheet({
    super.key,
    required this.collection,
  });

  @override
  State<AdvancedSharingBottomSheet> createState() =>
      _AdvancedSharingBottomSheetState();
}

class _AdvancedSharingBottomSheetState
    extends State<AdvancedSharingBottomSheet> {
  int get _shareeCount => widget.collection.getSharees().length;

  PublicURL? get _publicUrl => widget.collection.publicURLs.isNotEmpty
      ? widget.collection.publicURLs.first
      : null;

  bool get _hasPublicLink => _publicUrl != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final shareText = context.l10n.shareWithPeopleSectionTitle(_shareeCount);

    final isDownloadEnabled =
        widget.collection.publicURLs.firstOrNull?.enableDownload ?? true;
    final isCollectEnabled =
        widget.collection.publicURLs.firstOrNull?.enableCollect ?? false;
    final isPasswordEnabled =
        widget.collection.publicURLs.firstOrNull?.passwordEnabled ?? false;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 20,
                      color: colorScheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shareText,
                        style: textTheme.body.copyWith(
                          color: colorScheme.textMuted,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.textBase,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sharing",
                        style: textTheme.largeBold,
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Sharing enabled",
                        ),
                        menuItemColor: colorScheme.backgroundElevated2,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => _shareeCount > 0 || _hasPublicLink,
                          onChanged: () async {},
                        ),
                        isGestureDetectorDisabled: true,
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Allow downloads",
                        ),
                        menuItemColor: colorScheme.backgroundElevated2,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => isDownloadEnabled,
                          onChanged: () async {
                            await _updatePublicUrlSettings(
                              {
                                'enableDownload': !isDownloadEnabled,
                              },
                            );
                            if (isDownloadEnabled) {
                              // ignore: unawaited_futures
                              showErrorDialog(
                                context,
                                "Please note",
                                "Viewers can still take screenshots or save a copy of your photos using external tools",
                              );
                            }
                          },
                        ),
                        isGestureDetectorDisabled: true,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Public Link",
                        style: textTheme.h3Bold.copyWith(
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Link enabled",
                        ),
                        menuItemColor: colorScheme.backgroundElevated2,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => _hasPublicLink,
                          onChanged: () async {
                            if (_hasPublicLink) {
                              await _disablePublicLink();
                            } else {
                              await _createPublicLink();
                            }
                          },
                        ),
                        isGestureDetectorDisabled: true,
                      ),
                      if (_hasPublicLink && _publicUrl != null) ...[
                        const SizedBox(height: 8),
                        MenuItemWidget(
                          captionedTextWidget: const CaptionedTextWidget(
                            title: "Allow uploads",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => isCollectEnabled,
                            onChanged: () async {
                              await _updatePublicUrlSettings(
                                {'enableCollect': !isCollectEnabled},
                              );
                            },
                          ),
                          isGestureDetectorDisabled: true,
                        ),
                        const SizedBox(height: 8),
                        MenuItemWidget(
                          captionedTextWidget: const CaptionedTextWidget(
                            title: "Password lock",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => isPasswordEnabled,
                            onChanged: () async {
                              if (!isPasswordEnabled) {
                                await _showPasswordDialog();
                              } else {
                                await _updatePublicUrlSettings(
                                  {'disablePassword': true},
                                );
                              }
                            },
                          ),
                          isGestureDetectorDisabled: true,
                        ),
                        const SizedBox(height: 8),
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: "Device limit",
                            subTitle: _publicUrl!.deviceLimit == 0
                                ? "None"
                                : "${_publicUrl!.deviceLimit}",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          trailingWidget: Icon(
                            Icons.chevron_right,
                            color: colorScheme.textMuted,
                            size: 24,
                          ),
                          onTap: () async {
                            await routeToPage(
                              context,
                              DeviceLimitPickerPage(widget.collection),
                            ).then((value) {
                              setState(() {});
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: "Link Expiry",
                            subTitle: _publicUrl!.hasExpiry
                                ? (_publicUrl!.isExpired
                                    ? "Expired"
                                    : "Enabled")
                                : "Never",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          trailingWidget: Icon(
                            Icons.chevron_right,
                            color: colorScheme.textMuted,
                            size: 24,
                          ),
                          onTap: () async {
                            await routeToPage(
                              context,
                              LinkExpiryPickerPage(widget.collection),
                            ).then((value) {
                              setState(() {});
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
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

  Future<void> _createPublicLink() async {
    final success = await CollectionActions.enableUrl(
      context,
      widget.collection,
    );
    if (success && mounted) {
      setState(() {});
    }
  }

  Future<void> _disablePublicLink() async {
    try {
      await CollectionActions.disableUrl(
        context,
        widget.collection,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        await showGenericErrorDialog(context: context, error: e);
      }
    }
  }

  Future<void> _updatePublicUrlSettings(
    Map<String, dynamic> updates, {
    bool showProgressDialog = true,
  }) async {
    final dialog = showProgressDialog
        ? createProgressDialog(context, "Please wait...")
        : null;
    await dialog?.show();
    try {
      await CollectionApiClient.instance.updateShareUrl(
        widget.collection,
        updates,
      );
      await dialog?.hide();
      showShortToast(context, "Collection updated");
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        await dialog?.hide();
        await showGenericErrorDialog(context: context, error: e);
        rethrow;
      }
    }
  }

  Future<void> _showPasswordDialog() async {
    await showTextInputDialog(
      context,
      title: context.l10n.setAPassword,
      submitButtonLabel: context.l10n.lockButtonLabel,
      hintText: context.l10n.enterPassword,
      isPasswordInput: true,
      alwaysShowSuccessState: true,
      onSubmit: (String password) async {
        if (password.trim().isNotEmpty) {
          final propToUpdate = await _getEncryptedPassword(password);
          await _updatePublicUrlSettings(
            propToUpdate,
            showProgressDialog: false,
          );
        }
      },
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
}
