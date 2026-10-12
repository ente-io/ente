import "dart:convert";

import 'package:ente_components/ente_components.dart';
import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/date_time_picker.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/core/constants.dart";
import "package:locker/services/collections/collections_api_client.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/public_url.dart";
import "package:locker/ui/components/text_input_sheet.dart";
import "package:locker/utils/collection_actions.dart";
import "package:locker/utils/error_sheet.dart";

class ManageSharedLinkWidget extends StatefulWidget {
  final Collection? collection;

  const ManageSharedLinkWidget({super.key, this.collection});

  @override
  State<ManageSharedLinkWidget> createState() => _ManageSharedLinkWidgetState();
}

class _ManageSharedLinkWidgetState extends State<ManageSharedLinkWidget> {
  static const Duration _expiryPresetSelectionTolerance = Duration(minutes: 5);

  final GlobalKey sendLinkButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final PublicURL url = widget.collection!.publicURLs.firstOrNull!;
    Widget linkIcon(List<List<dynamic>> icon, {Color? color}) => HugeIcon(
      icon: icon,
      color: color ?? colors.textLight,
      size: IconSizes.small,
      strokeWidth: 1.6,
    );
    final chevron = Icon(
      Icons.chevron_right_rounded,
      color: colors.textLight,
      size: IconSizes.medium,
    );
    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: AppBarComponent(
        title: context.strings.linkSettings,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.xl,
              ),
              sliver: SliverList.list(
                children: [
                  _LinkSettingsGroup(
                    items: [
                      if (url.isExpired)
                        MenuComponent(
                          title: context.strings.linkHasExpired,
                          titleColor: colors.warning,
                          isDisabled: true,
                          iconColor: colors.warning,
                          leading: const Icon(Icons.error_outline_rounded),
                        ),
                      if (!url.isExpired) ...[
                        MenuComponent(
                          title: context.strings.copyLink,
                          leading: linkIcon(HugeIcons.strokeRoundedCopy01),
                          showOnlyLoadingState: true,
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: CollectionService.instance.getPublicUrl(
                                  widget.collection!,
                                ),
                              ),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            showShortToast(
                              context,
                              context.strings.linkCopiedToClipboard,
                            );
                          },
                        ),
                        MenuComponent(
                          key: sendLinkButtonKey,
                          title: context.strings.sendLink,
                          leading: linkIcon(HugeIcons.strokeRoundedSent),
                          onTap: () async {
                            await shareText(
                              CollectionService.instance.getPublicUrl(
                                widget.collection!,
                              ),
                              context: context,
                              key: sendLinkButtonKey,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  if (!url.isExpired)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Text(
                        context.strings.publicCollectionLinkAccessDescription,
                        style: TextStyles.mini.copyWith(
                          color: colors.textLight,
                        ),
                      ),
                    ),
                  const SizedBox(height: Spacing.lg),
                  _LinkSettingsGroup(
                    items: [
                      MenuComponent(
                        title: context.strings.linkDeviceLimit,
                        leading: linkIcon(HugeIcons.strokeRoundedLaptop),
                        subtitle: url.deviceLimit == 0
                            ? context.strings.noLimit
                            : "${url.deviceLimit}",
                        trailing: chevron,
                        onTap: () async {
                          await _showDeviceLimitSheet(context, url);
                        },
                      ),
                      MenuComponent(
                        key: ValueKey("Password lock ${url.passwordEnabled}"),
                        title: context.strings.password,
                        leading: linkIcon(HugeIcons.strokeRoundedSquareLock01),
                        trailing: ToggleSwitchComponent.async(
                          value: () => url.passwordEnabled,
                          onChanged: () async {
                            if (!url.passwordEnabled) {
                              await showTextInputSheet(
                                context,
                                title: context.strings.setAPassword,
                                submitButtonLabel:
                                    context.strings.lockButtonLabel,
                                hintText: context.strings.enterPassword,
                                onSubmit: (String password) async {
                                  if (password.trim().isEmpty) {
                                    return;
                                  }
                                  final propToUpdate =
                                      await _getEncryptedPassword(password);
                                  await _updateUrlSettings(
                                    context.mounted ? context : null,
                                    propToUpdate,
                                    showProgressDialog: false,
                                  );
                                },
                                isPasswordInput: true,
                                textCapitalization: TextCapitalization.none,
                                maxLength: 256,
                              );
                            } else {
                              await _updateUrlSettings(context, {
                                'disablePassword': true,
                              });
                            }
                          },
                        ),
                      ),
                      MenuComponent(
                        title: context.strings.linkExpiry,
                        leading: linkIcon(HugeIcons.strokeRoundedCalendar03),
                        subtitle: url.hasExpiry
                            ? (url.isExpired
                                  ? context.strings.linkExpired
                                  : context.strings.linkEnabled)
                            : context.strings.linkNeverExpires,
                        trailing: chevron,
                        onTap: () async {
                          await _showLinkExpirySheet(context, url);
                        },
                      ),
                    ],
                  ),
                  if (url.hasExpiry)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Text(
                        url.isExpired
                            ? context.strings.expiredLinkInfo
                            : context.strings.linkExpiresOn(
                                expiryTime: getFormattedTime(
                                  DateTime.fromMicrosecondsSinceEpoch(
                                    url.validTill,
                                  ),
                                  context: context,
                                ),
                              ),
                        style: TextStyles.body.copyWith(
                          color: colors.textLight,
                        ),
                      ),
                    ),
                  const SizedBox(height: Spacing.lg),
                  _LinkSettingsGroup(
                    items: [
                      MenuComponent(
                        title: context.strings.removeLink,
                        titleColor: colors.warning,
                        iconColor: colors.warning,
                        leading: linkIcon(
                          HugeIcons.strokeRoundedMinusSignCircle,
                          color: colors.warning,
                        ),
                        onTap: () async {
                          final bool result =
                              await CollectionActions.disableUrl(
                                context,
                                widget.collection!,
                              );
                          if (!context.mounted || !result) {
                            return;
                          }
                          Navigator.of(context).pop();
                          if (widget.collection!.isQuickLinkCollection()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkExpirySheet(BuildContext context, PublicURL url) async {
    final l10n = context.strings;
    final expiryOptions = [
      (title: l10n.never, expireAfterInMicroseconds: 0),
      (
        title: l10n.after1Hour,
        expireAfterInMicroseconds: const Duration(hours: 1).inMicroseconds,
      ),
      (
        title: l10n.after1Day,
        expireAfterInMicroseconds: const Duration(days: 1).inMicroseconds,
      ),
      (
        title: l10n.after1Week,
        expireAfterInMicroseconds: const Duration(days: 7).inMicroseconds,
      ),
      (
        title: l10n.after1Month,
        expireAfterInMicroseconds: const Duration(days: 30).inMicroseconds,
      ),
      (
        title: l10n.after1Year,
        expireAfterInMicroseconds: const Duration(days: 365).inMicroseconds,
      ),
      (title: l10n.custom, expireAfterInMicroseconds: -1),
    ];
    final selectedExpiryOption = _selectedExpiryOption(
      url,
      expiryOptions.map((option) => option.expireAfterInMicroseconds),
    );
    var selectionPending = false;

    await showBottomSheetComponent<void>(
      context: context,
      builder: (sheetContext) => BottomSheetComponent(
        title: l10n.linkExpiry,
        isScrollable: true,
        content: MenuGroupComponent(
          items: [
            for (final expiryOption in expiryOptions)
              MenuComponent(
                key: ValueKey(expiryOption.expireAfterInMicroseconds),
                title: expiryOption.title,
                trailing:
                    selectedExpiryOption ==
                        expiryOption.expireAfterInMicroseconds
                    ? Icon(
                        Icons.check,
                        color: sheetContext.componentColors.primary,
                      )
                    : null,
                showOnlyLoadingState:
                    expiryOption.expireAfterInMicroseconds != -1,
                onTap: () async {
                  if (selectionPending) return;
                  selectionPending = true;
                  if (expiryOption.expireAfterInMicroseconds < 0) {
                    Navigator.of(sheetContext).pop();
                    await _pickCustomExpiry(context);
                    return;
                  }

                  final newValidTill = _validTillForExpiryOption(
                    expiryOption.expireAfterInMicroseconds,
                  );
                  try {
                    await _updateUrlSettings(
                      context,
                      {'validTill': newValidTill},
                      showProgressDialog: false,
                      showToast: false,
                    );
                  } catch (_) {
                    selectionPending = false;
                    rethrow;
                  }
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomExpiry(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDateTimePickerSheet(
      context,
      initialDateTime: now,
      minDateTime: now,
    );
    final timeInMicrosecondsFromEpoch = picked?.microsecondsSinceEpoch;
    if (timeInMicrosecondsFromEpoch == null) {
      return;
    }

    if (!context.mounted) return;
    await _updateUrlSettings(
      context,
      {'validTill': timeInMicrosecondsFromEpoch},
      showProgressDialog: false,
      showToast: false,
    );
  }

  int _validTillForExpiryOption(int expireAfterInMicroseconds) {
    if (expireAfterInMicroseconds == 0) {
      return 0;
    }
    return DateTime.now().microsecondsSinceEpoch + expireAfterInMicroseconds;
  }

  int _selectedExpiryOption(PublicURL url, Iterable<int> expireAfterOptions) {
    if (!url.hasExpiry) {
      return 0;
    }

    final remainingMicroseconds =
        url.validTill - DateTime.now().microsecondsSinceEpoch;
    if (remainingMicroseconds <= 0) {
      return -1;
    }

    for (final expireAfterOption in expireAfterOptions) {
      if (expireAfterOption <= 0) {
        continue;
      }
      final difference = (remainingMicroseconds - expireAfterOption).abs();
      if (difference <= _expiryPresetSelectionTolerance.inMicroseconds) {
        return expireAfterOption;
      }
    }

    return -1;
  }

  Future<void> _showDeviceLimitSheet(
    BuildContext context,
    PublicURL url,
  ) async {
    final l10n = context.strings;
    final currentDeviceLimit = url.deviceLimit;
    final deviceLimits = [
      if (!publicLinkDeviceLimits.contains(currentDeviceLimit))
        currentDeviceLimit,
      ...publicLinkDeviceLimits,
    ];
    var selectionPending = false;

    await showBottomSheetComponent<void>(
      context: context,
      builder: (sheetContext) => BottomSheetComponent(
        title: l10n.linkDeviceLimit,
        isScrollable: true,
        content: MenuGroupComponent(
          items: [
            for (final deviceLimit in deviceLimits)
              MenuComponent(
                key: ValueKey(deviceLimit),
                title: deviceLimit == 0 ? l10n.noLimit : "$deviceLimit",
                trailing: currentDeviceLimit == deviceLimit
                    ? Icon(
                        Icons.check,
                        color: sheetContext.componentColors.primary,
                      )
                    : null,
                showOnlyLoadingState: true,
                onTap: () async {
                  if (selectionPending) return;
                  selectionPending = true;
                  try {
                    await _updateUrlSettings(
                      context,
                      {'deviceLimit': deviceLimit},
                      showProgressDialog: false,
                      showToast: false,
                    );
                  } catch (_) {
                    selectionPending = false;
                    rethrow;
                  }
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
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
    BuildContext? context,
    Map<String, dynamic> prop, {
    bool showProgressDialog = true,
    bool showToast = true,
  }) async {
    final dialog = showProgressDialog && context != null && context.mounted
        ? createProgressDialog(context, context.strings.pleaseWait)
        : null;
    await dialog?.show();
    try {
      await CollectionApiClient.instance.updateShareUrl(
        widget.collection!,
        prop,
      );
      await dialog?.hide();
      if (showToast && context != null && context.mounted) {
        showShortToast(context, context.strings.collectionUpdated);
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      await dialog?.hide();
      if (context != null && context.mounted) {
        await showLockerErrorSheet(context, e);
      }
      rethrow;
    }
  }
}

class _LinkSettingsGroup extends StatelessWidget {
  const _LinkSettingsGroup({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return MenuGroupComponent(
      items: items.length > 1
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      items[index],
                      if (index < items.length - 1)
                        const SizedBox(height: Spacing.xs),
                    ],
                  ],
                ),
              ),
            ]
          : items,
    );
  }
}
