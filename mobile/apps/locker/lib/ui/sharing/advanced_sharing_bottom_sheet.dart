import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/toggle_switch_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_api_client.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/public_url.dart";
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
  static const double leadingSpace = 12;

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
                        leadingSpace: leadingSpace,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => _shareeCount > 0 || _hasPublicLink,
                          onChanged: () async {
                            // No action - just display current state
                          },
                        ),
                        isGestureDetectorDisabled: true,
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidget(
                        captionedTextWidget: const CaptionedTextWidget(
                          title: "Allow downloads",
                        ),
                        menuItemColor: colorScheme.backgroundElevated2,
                        leadingSpace: leadingSpace,
                        trailingWidget: ToggleSwitchWidget(
                          value: () => _publicUrl?.enableDownload ?? true,
                          onChanged: _publicUrl != null
                              ? () async {
                                  await _updatePublicUrlSettings(
                                    {
                                      'enableDownload':
                                          !_publicUrl!.enableDownload,
                                    },
                                  );
                                }
                              : () async {},
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
                        leadingSpace: leadingSpace,
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
                            title: "Allow downloads",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          leadingSpace: leadingSpace,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => _publicUrl!.enableDownload,
                            onChanged: () async {
                              await _updatePublicUrlSettings(
                                {'enableDownload': !_publicUrl!.enableDownload},
                              );
                            },
                          ),
                          isGestureDetectorDisabled: true,
                        ),
                        const SizedBox(height: 8),

                        MenuItemWidget(
                          captionedTextWidget: const CaptionedTextWidget(
                            title: "Allow uploads",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          leadingSpace: leadingSpace,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => _publicUrl!.enableCollect,
                            onChanged: () async {
                              await _updatePublicUrlSettings(
                                {'enableCollect': !_publicUrl!.enableCollect},
                              );
                            },
                          ),
                          isGestureDetectorDisabled: true,
                        ),
                        const SizedBox(height: 8),

                        // Password lock
                        MenuItemWidget(
                          captionedTextWidget: const CaptionedTextWidget(
                            title: "Password lock",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          leadingSpace: leadingSpace,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => _publicUrl!.passwordEnabled,
                            onChanged: () async {
                              if (!_publicUrl!.passwordEnabled) {
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
                                : "${_publicUrl!.deviceLimit} devices",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          leadingSpace: leadingSpace,
                          trailingWidget: Icon(
                            Icons.chevron_right,
                            color: colorScheme.textMuted,
                            size: 24,
                          ),
                          onTap: () async {
                            // TODO: Navigate to device limit picker
                          },
                        ),
                        const SizedBox(height: 8),

                        // Link Expiry
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: "Link Expiry",
                            subTitle: _publicUrl!.hasExpiry
                                ? (_publicUrl!.isExpired ? "Expired" : "Active")
                                : "Never",
                          ),
                          menuItemColor: colorScheme.backgroundElevated2,
                          leadingSpace: leadingSpace,
                          trailingWidget: Icon(
                            Icons.chevron_right,
                            color: colorScheme.textMuted,
                            size: 24,
                          ),
                          onTap: () async {
                            // TODO: Navigate to link expiry picker
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Disable public link"),
        content: const Text(
          "Are you sure you want to disable the public link? People with this link will no longer be able to access your collection.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Disable"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
  }

  Future<void> _updatePublicUrlSettings(
    Map<String, dynamic> updates,
  ) async {
    try {
      await CollectionApiClient.instance.updateShareUrl(
        widget.collection,
        updates,
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

  Future<void> _showPasswordDialog() async {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: colorScheme.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Set password",
                style: textTheme.h3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: "Enter password",
                  hintStyle: textTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                  filled: true,
                  fillColor: colorScheme.backgroundElevated2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      "Cancel",
                      style: textTheme.body,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final password = passwordController.text.trim();
                      if (password.isNotEmpty) {
                        Navigator.pop(dialogContext);
                        // TODO: Implement password encryption and update
                        await _updatePublicUrlSettings({
                          'passwordEnabled': true,
                        });
                      }
                    },
                    child: const Text("Set"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
