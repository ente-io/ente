import "dart:async";

import "package:ente_configuration/base_configuration.dart";
import "package:ente_contacts/contacts.dart";
import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_legacy/components/invite_reject_bottom_sheet.dart";
import "package:ente_legacy/components/trusted_contact_bottom_sheet.dart";
import "package:ente_legacy/models/emergency_models.dart";
import "package:ente_legacy/models/legacy_kit_models.dart";
import "package:ente_legacy/pages/create_legacy_kit_sheet.dart";
import "package:ente_legacy/pages/legacy_kit_advert_page.dart";
import "package:ente_legacy/pages/legacy_kit_creating_page.dart";
import "package:ente_legacy/pages/legacy_kit_page.dart";
import "package:ente_legacy/pages/other_contact_page.dart";
import "package:ente_legacy/pages/select_contact_page.dart";
import "package:ente_legacy/services/emergency_service.dart";
import "package:ente_legacy/services/legacy_kit_service.dart";
import "package:ente_sharing/extensions/user_extension.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/components/captioned_text_widget_v2.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/loading_widget.dart";
import "package:ente_ui/components/menu_item_widget_v2.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";

final _logger = Logger("EmergencyPage");
const _legacyEmptyStateDescription =
    "Keep your Ente account accessible to people you trust, even if something happens to you.";

class EmergencyPage extends StatefulWidget {
  final BaseConfiguration config;
  final LegacyKitAuthenticator? legacyKitAuthenticator;

  const EmergencyPage({
    required this.config,
    this.legacyKitAuthenticator,
    super.key,
  });

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  late int currentUserID;
  EmergencyInfo? info;
  List<LegacyKit> legacyKits = [];

  @override
  void initState() {
    super.initState();
    currentUserID = widget.config.getUserID()!;
    Future.delayed(const Duration(seconds: 0), () async {
      unawaited(_fetchData());
    });
  }

  Future<void> _fetchData() async {
    try {
      final result = await EmergencyContactService.instance.getInfo();
      final kits = await _fetchLegacyKits();
      if (mounted) {
        setState(() {
          info = result;
          legacyKits = kits;
        });
      }
    } catch (e) {
      showShortToast(context, context.strings.somethingWentWrong);
    }
  }

  Future<List<LegacyKit>> _fetchLegacyKits() async {
    if (!LegacyKitService.instance.isInitialized) {
      return <LegacyKit>[];
    }
    try {
      return await LegacyKitService.instance.getKits();
    } catch (error, stackTrace) {
      _logger.warning("Failed to fetch legacy kits", error, stackTrace);
      return legacyKits;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ContactsDisplayService.instance.changes,
      builder: (context, __, ___) {
        final colorScheme = getEnteColorScheme(context);
        final textTheme = getEnteTextTheme(context);
        final List<EmergencyContact> othersTrustedContacts =
            info?.othersEmergencyContact ?? [];
        final List<EmergencyContact> trustedContacts = info?.contacts ?? [];
        final hasSecondaryLegacyContent =
            legacyKits.isNotEmpty || othersTrustedContacts.isNotEmpty;
        final showFullEmptyState = info != null &&
            info!.recoverSessions.isEmpty &&
            trustedContacts.isEmpty &&
            othersTrustedContacts.isEmpty &&
            legacyKits.isEmpty;

        return Scaffold(
          backgroundColor: colorScheme.backgroundBase,
          appBar: AppBar(
            backgroundColor: colorScheme.backgroundBase,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 48,
            leadingWidth: 48,
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back_outlined),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPageTitle(colorScheme, textTheme),
                ),
              ),
              if (!showFullEmptyState)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      context.strings.legacyPageDesc,
                      style: textTheme.smallMuted,
                    ),
                  ),
                ),
              if (showFullEmptyState)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FullLegacyEmptyState(
                    onAddContact: _addTrustedContact,
                    onCreateLegacyKit: LegacyKitService.instance.isInitialized
                        ? _createLegacyKit
                        : null,
                  ),
                ),
              if (info == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: EnteLoadingWidget()),
                ),
              if (info != null && info!.recoverSessions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _WarningBanner(
                              text: context.strings.recoveryWarning,
                            ),
                          );
                        }
                        final listIndex = index - 1;
                        final RecoverySessions recoverSession =
                            info!.recoverSessions[listIndex];
                        final isLastItem =
                            listIndex == info!.recoverSessions.length - 1;
                        return Column(
                          children: [
                            MenuItemWidgetV2(
                              captionedTextWidget: CaptionedTextWidgetV2(
                                title: recoverSession
                                    .emergencyContact.resolvedDisplayName,
                                textStyle: textTheme.small.copyWith(
                                  color: colorScheme.warning500,
                                  fontWeight: recoverSession.status.isNotEmpty
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                              leadingIconSize: 24.0,
                              surfaceExecutionStates: false,
                              alwaysShowSuccessState: false,
                              leadingIconWidget: UserAvatarWidget(
                                recoverSession.emergencyContact,
                                type: AvatarType.mini,
                                currentUserID: currentUserID,
                                config: widget.config,
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingIcon: Icons.chevron_right,
                              trailingIconIsMuted: true,
                              onTap: () async {
                                await showRejectRecoveryDialog(recoverSession);
                              },
                              isTopBorderRadiusRemoved: listIndex > 0,
                              isBottomBorderRadiusRemoved: !isLastItem,
                              isFirstItem: listIndex == 0,
                              isLastItem: isLastItem,
                            ),
                            if (!isLastItem)
                              DividerWidget(
                                dividerType: DividerType.menu,
                                bgColor: colorScheme.fillFaint,
                              ),
                          ],
                        );
                      },
                      childCount: 1 + info!.recoverSessions.length,
                    ),
                  ),
                ),
              if (info != null && !showFullEmptyState)
                SliverPadding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0 &&
                            (trustedContacts.isNotEmpty ||
                                hasSecondaryLegacyContent)) {
                          return _buildSectionTitle(
                            title: context.strings.trustedContacts,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            bottom: 12,
                          );
                        } else if (index > 0 &&
                            index <= trustedContacts.length) {
                          final listIndex = index - 1;
                          final contact = trustedContacts[listIndex];
                          final rowColor = _legacyRowColor(colorScheme);
                          return Column(
                            children: [
                              MenuItemWidgetV2(
                                captionedTextWidget: CaptionedTextWidgetV2(
                                  title: contact
                                      .emergencyContact.resolvedDisplayName,
                                  subTitle: _contactStatusText(contact),
                                  subTitleInNewLine: true,
                                  textStyle: _legacyRowTitleStyle(
                                    colorScheme,
                                    textTheme,
                                  ),
                                  subTitleTextStyle: _legacyRowSubTitleStyle(
                                    colorScheme,
                                    textTheme,
                                  ),
                                ),
                                leadingIconSize: 32.0,
                                surfaceExecutionStates: false,
                                alwaysShowSuccessState: false,
                                leadingIconWidget: _ContactAvatarWithStatus(
                                  isPending: contact.isPendingInvite(),
                                  borderColor: rowColor,
                                  child: UserAvatarWidget(
                                    contact.emergencyContact,
                                    type: AvatarType.small,
                                    currentUserID: currentUserID,
                                    config: widget.config,
                                  ),
                                ),
                                menuItemColor: rowColor,
                                singleBorderRadius: 20,
                                trailingIcon: Icons.chevron_right,
                                trailingIconIsMuted: true,
                                onTap: () async {
                                  await showRevokeOrRemoveDialog(
                                    context,
                                    contact,
                                  );
                                },
                              ),
                              if (listIndex < trustedContacts.length - 1)
                                const SizedBox(height: 8),
                            ],
                          );
                        } else if (index == (1 + trustedContacts.length)) {
                          if (trustedContacts.isEmpty) {
                            if (hasSecondaryLegacyContent) {
                              return _TrustedContactsEmptyCard(
                                onAddContact: _addTrustedContact,
                              );
                            }
                            return Column(
                              children: [
                                if (legacyKits.isEmpty) ...[
                                  SizedBox(
                                    height: 200,
                                    width: 200,
                                    child: Image.asset(
                                      "assets/legacy.png",
                                      width: 200,
                                      height: 200,
                                    ),
                                  ),
                                  Text(
                                    context.strings.legacyPageDesc2,
                                    style: textTheme.smallMuted,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _buildAddTrustedContactButton(),
                                if (LegacyKitService.instance.isInitialized &&
                                    legacyKits.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  GradientButton(
                                    text: context.strings.createLegacyKit,
                                    height: 52,
                                    textStyle: _legacyButtonTextStyle(
                                      textTheme,
                                    ),
                                    onTap: () async {
                                      await _createLegacyKit();
                                    },
                                  ),
                                ],
                              ],
                            );
                          }
                          return Column(
                            children: [
                              const SizedBox(height: 12),
                              _buildAddTrustedContactButton(),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      childCount: 1 + trustedContacts.length + 1,
                    ),
                  ),
                ),
              if (info != null &&
                  !showFullEmptyState &&
                  info!.othersEmergencyContact.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0 && (othersTrustedContacts.isNotEmpty)) {
                          return Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildSectionTitle(
                                title: context.strings.legacyAccounts,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                              ),
                            ],
                          );
                        } else if (index > 0 &&
                            index <= othersTrustedContacts.length) {
                          final listIndex = index - 1;
                          final currentUser = othersTrustedContacts[listIndex];
                          final rowColor = _legacyRowColor(colorScheme);
                          return Column(
                            children: [
                              MenuItemWidgetV2(
                                captionedTextWidget: CaptionedTextWidgetV2(
                                  title: currentUser.user.resolvedDisplayName,
                                  subTitle: _contactStatusText(currentUser),
                                  subTitleInNewLine: true,
                                  textStyle: _legacyRowTitleStyle(
                                    colorScheme,
                                    textTheme,
                                  ),
                                  subTitleTextStyle: _legacyRowSubTitleStyle(
                                    colorScheme,
                                    textTheme,
                                  ),
                                ),
                                leadingIconSize: 32.0,
                                surfaceExecutionStates: false,
                                alwaysShowSuccessState: false,
                                leadingIconWidget: _ContactAvatarWithStatus(
                                  isPending: currentUser.isPendingInvite(),
                                  borderColor: rowColor,
                                  child: UserAvatarWidget(
                                    currentUser.user,
                                    type: AvatarType.small,
                                    currentUserID: currentUserID,
                                    config: widget.config,
                                  ),
                                ),
                                menuItemColor: rowColor,
                                singleBorderRadius: 20,
                                trailingIcon: Icons.chevron_right,
                                trailingIconIsMuted: true,
                                onTap: () async {
                                  if (currentUser.isPendingInvite()) {
                                    await showAcceptOrDeclineDialog(
                                      context,
                                      currentUser,
                                    );
                                  } else {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) {
                                          return OtherContactPage(
                                            contact: currentUser,
                                            emergencyInfo: info!,
                                            config: widget.config,
                                          );
                                        },
                                      ),
                                    );
                                    if (mounted) {
                                      unawaited(_fetchData());
                                    }
                                  }
                                },
                              ),
                              if (listIndex < othersTrustedContacts.length - 1)
                                const SizedBox(height: 8),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      childCount: 1 + othersTrustedContacts.length + 1,
                    ),
                  ),
                ),
              if (info != null &&
                  !showFullEmptyState &&
                  LegacyKitService.instance.isInitialized &&
                  (legacyKits.isNotEmpty ||
                      trustedContacts.isNotEmpty ||
                      othersTrustedContacts.isNotEmpty))
                _buildLegacyKitsSliver(colorScheme, textTheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageTitle(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return SizedBox(
      height: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          context.strings.legacy,
          style: textTheme.h3Bold.copyWith(
            color: colorScheme.textBase,
            fontSize: 20.0,
            height: 28 / 20,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildLegacyKitsSliver(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionTitle(
              title: context.strings.legacyKits,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            if (legacyKits.isEmpty)
              _LegacyKitEmptyCard(onCreate: _createLegacyKit)
            else
              ..._buildLegacyKitRows(colorScheme, textTheme),
            const SizedBox(height: 12),
            if (legacyKits.isNotEmpty && legacyKits.length < 5)
              GradientButton(
                text: context.strings.createAnotherKit,
                height: 52,
                textStyle: _legacyButtonTextStyle(textTheme),
                backgroundColor: _legacySecondaryButtonColor(colorScheme),
                textColor: colorScheme.primary700,
                onTap: () async {
                  await _createLegacyKit();
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLegacyKitRows(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final cardColor = _legacyRowColor(colorScheme);
    return [
      for (var index = 0; index < legacyKits.length; index++) ...[
        MenuItemWidgetV2(
          captionedTextWidget: CaptionedTextWidgetV2(
            title: legacyKits[index].displayName,
            subTitle: legacyKits[index].hasActiveRecoverySession
                ? context.strings.legacyKitRecoveryInProgress
                : context.strings.createdOn(
                    _formatKitDate(legacyKits[index].createdAt),
                  ),
            subTitleInNewLine: true,
            textStyle: _legacyRowTitleStyle(
              colorScheme,
              textTheme,
              isWarning: legacyKits[index].hasActiveRecoverySession,
            ),
            subTitleTextStyle: _legacyRowSubTitleStyle(
              colorScheme,
              textTheme,
              isWarning: legacyKits[index].hasActiveRecoverySession,
            ),
          ),
          leadingIconSize: 32,
          leadingIconWidget:
              _LegacyKitLeadingIcon(color: colorScheme.primary700),
          menuItemColor: cardColor,
          singleBorderRadius: 20,
          trailingIcon: Icons.chevron_right,
          trailingIconIsMuted: true,
          surfaceExecutionStates: false,
          alwaysShowSuccessState: false,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return LegacyKitPage(
                    kit: legacyKits[index],
                    accountEmail: widget.config.getEmail() ?? "",
                    authenticator: widget.legacyKitAuthenticator,
                    onChanged: () => unawaited(_fetchData()),
                  );
                },
              ),
            );
            if (mounted) {
              unawaited(_fetchData());
            }
          },
          isFirstItem: index == 0,
          isLastItem: index == legacyKits.length - 1,
        ),
        if (index < legacyKits.length - 1) const SizedBox(height: 8),
      ],
    ];
  }

  Widget _buildAddTrustedContactButton() {
    final textTheme = getEnteTextTheme(context);
    return GradientButton(
      text: context.strings.addTrustedContact,
      height: 52,
      textStyle: _legacyButtonTextStyle(textTheme),
      onTap: () async {
        await _addTrustedContact();
      },
    );
  }

  Future<void> _addTrustedContact() async {
    final result = await showAddContactSheet(
      context,
      emergencyInfo: info!,
      config: widget.config,
    );
    if (result == true) {
      unawaited(_fetchData());
    }
  }

  Widget _buildSectionTitle({
    required String title,
    required EnteColorScheme colorScheme,
    required EnteTextTheme textTheme,
    double bottom = 8,
  }) {
    return MenuSectionTitle(
      title: title,
      padding: EdgeInsets.only(bottom: bottom),
      textStyle: textTheme.bodyBold.copyWith(color: colorScheme.textBase),
    );
  }

  Color _legacyRowColor(EnteColorScheme colorScheme) {
    return colorScheme.backdropBase;
  }

  Color _legacySecondaryButtonColor(EnteColorScheme colorScheme) {
    return colorScheme.isLightTheme
        ? colorScheme.primary300
        : colorScheme.backdropBase;
  }

  TextStyle _legacyRowTitleStyle(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme, {
    bool isWarning = false,
  }) {
    return textTheme.small.copyWith(
      color: isWarning ? colorScheme.warning500 : colorScheme.textBase,
      fontWeight: isWarning ? FontWeight.w600 : FontWeight.w500,
      height: 20 / 14,
    );
  }

  TextStyle _legacyRowSubTitleStyle(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme, {
    bool isWarning = false,
  }) {
    return textTheme.mini.copyWith(
      color: isWarning ? colorScheme.warning500 : colorScheme.textMuted,
      height: 16 / 12,
    );
  }

  TextStyle _legacyButtonTextStyle(EnteTextTheme textTheme) {
    return textTheme.small.copyWith(height: 20 / 14);
  }

  Future<void> _createLegacyKit() async {
    if (legacyKits.length >= 5) {
      await showAlertBottomSheet(
        context,
        title: context.strings.legacyKits,
        message: context.strings.legacyKitMaxReached,
        assetPath: "assets/warning-blue.png",
      );
      return;
    }
    if (legacyKits.isEmpty) {
      final shouldStart = await showLegacyKitAdvertPage(context);
      if (!shouldStart || !mounted) {
        return;
      }
    }
    final input = await showCreateLegacyKitSheet(context);
    if (input == null) {
      return;
    }
    if (!await _authenticate(context.strings.authToManageLegacyKit)) {
      return;
    }

    final navigator = Navigator.of(context);
    unawaited(
      navigator.push<void>(
        MaterialPageRoute(
          builder: (context) => const LegacyKitCreatingPage(),
        ),
      ),
    );

    try {
      final result = await LegacyKitService.instance.createKit(
        partNames: input.partNames,
        noticePeriodInHours: input.noticePeriodInHours,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        legacyKits = [result.kit, ...legacyKits];
      });
      unawaited(_fetchData());
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return LegacyKitPage(
              kit: result.kit,
              accountEmail: widget.config.getEmail() ?? "",
              authenticator: widget.legacyKitAuthenticator,
              onChanged: () => unawaited(_fetchData()),
            );
          },
        ),
      );
      if (mounted) {
        unawaited(_fetchData());
      }
    } catch (_) {
      if (mounted) {
        navigator.pop();
        showShortToast(context, context.strings.somethingWentWrong);
      }
    }
  }

  Future<bool> _authenticate(String reason) async {
    final authenticator = widget.legacyKitAuthenticator;
    if (authenticator == null) {
      return true;
    }
    return authenticator(context, reason);
  }

  String _formatKitDate(int micros) {
    final dateTime = DateTime.fromMicrosecondsSinceEpoch(micros).toLocal();
    return DateFormat.yMMMd().format(dateTime);
  }

  String _contactStatusText(EmergencyContact contact) {
    return contact.isPendingInvite() ? "Pending" : "Accepted";
  }

  Future<void> showRevokeOrRemoveDialog(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final result = await showTrustedContactSheet(context, contact: contact);

    if (result?.action == TrustedContactAction.revoke) {
      final isPending = contact.isPendingInvite();
      final colorScheme = getEnteColorScheme(context);
      final confirmed = await showAlertBottomSheet<bool>(
        context,
        title: isPending
            ? context.strings.cancelInvite
            : context.strings.removeContact,
        message: isPending
            ? context.strings.cancelInviteDesc
            : context.strings.removeContactDesc,
        assetPath: "assets/warning-grey.png",
        buttons: [
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: isPending
                  ? context.strings.revokeInvite
                  : context.strings.removeContact,
              backgroundColor: colorScheme.warning700,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      );

      if (confirmed == true) {
        await EmergencyContactService.instance.updateContact(
          contact,
          ContactState.userRevokedContact,
        );
        info?.contacts.remove(contact);
        if (mounted) {
          setState(() {});
          unawaited(_fetchData());
        }
      }
    } else if (result?.action == TrustedContactAction.updateTime) {
      final selectedDays = result!.selectedDays;
      if (selectedDays == null) return;
      try {
        final success = await EmergencyContactService.instance
            .updateRecoveryNotice(contact, selectedDays);
        if (success) {
          final updatedContact = contact.copyWith(
            recoveryNoticeInDays: selectedDays,
          );
          final index = info?.contacts.indexOf(contact);
          if (index != null && index >= 0) {
            info?.contacts[index] = updatedContact;
          }
          if (mounted) {
            setState(() {});
          }
        } else {
          if (mounted) {
            await showAlertBottomSheet(
              context,
              title: context.strings.cannotUpdateRecoveryTime,
              message: context.strings.cannotUpdateRecoveryTimeMessage,
              assetPath: "assets/warning-blue.png",
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showShortToast(context, context.strings.somethingWentWrong);
        }
      }
    }
  }

  Future<void> showAcceptOrDeclineDialog(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final result = await showEmailSheet<String>(
      context,
      email: contact.user.email,
      message: context.strings.legacyInvite(contact.user.email),
      buttons: [
        GradientButton(
          text: context.strings.acceptTrustInvite,
          backgroundColor: colorScheme.primary700,
          onTap: () => Navigator.of(context).pop("accept"),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop("decline"),
            child: Text(
              context.strings.declineTrustInvite,
              style: textTheme.bodyBold.copyWith(
                color: colorScheme.warning400,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.warning400,
              ),
            ),
          ),
        ),
      ],
    );

    if (result == "accept") {
      await EmergencyContactService.instance.updateContact(
        contact,
        ContactState.contactAccepted,
      );
      final updatedContact = contact.copyWith(
        state: ContactState.contactAccepted,
      );
      info?.othersEmergencyContact.remove(contact);
      info?.othersEmergencyContact.add(updatedContact);
      if (mounted) {
        setState(() {});
      }
    } else if (result == "decline") {
      await EmergencyContactService.instance.updateContact(
        contact,
        ContactState.contactDenied,
      );
      info?.othersEmergencyContact.remove(contact);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> showRejectRecoveryDialog(RecoverySessions session) async {
    final String emergencyContactEmail = session.emergencyContact.email;
    final colorScheme = getEnteColorScheme(context);

    final confirmed = await showEmailSheet<bool>(
      context,
      email: emergencyContactEmail,
      message: context.strings.recoveryWarningBody(emergencyContactEmail),
      buttons: [
        GradientButton(
          text: context.strings.rejectRecovery,
          backgroundColor: colorScheme.warning700,
          onTap: () => Navigator.of(context).pop(true),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          GradientButton(
            text: "Approve recovery (to be removed)",
            backgroundColor: colorScheme.primary700,
            onTap: () async {
              Navigator.of(context).pop();
              await EmergencyContactService.instance.approveRecovery(session);
              if (mounted) {
                setState(() {});
              }
              unawaited(_fetchData());
            },
          ),
        ],
      ],
    );

    if (confirmed == true) {
      await EmergencyContactService.instance.rejectRecovery(session);
      info?.recoverSessions.removeWhere((element) => element.id == session.id);
      if (mounted) {
        setState(() {});
      }
      unawaited(_fetchData());
    }
  }
}

class _ContactAvatarWithStatus extends StatelessWidget {
  final Widget child;
  final bool isPending;
  final Color borderColor;

  const _ContactAvatarWithStatus({
    required this.child,
    required this.isPending,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (isPending)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: colorScheme.caution500,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  "!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.0,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FullLegacyEmptyState extends StatelessWidget {
  final Future<void> Function() onAddContact;
  final Future<void> Function()? onCreateLegacyKit;

  const _FullLegacyEmptyState({
    required this.onAddContact,
    required this.onCreateLegacyKit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final buttonTextStyle = textTheme.small.copyWith(height: 20 / 14);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 150,
                  child: Image.asset(
                    "assets/legacy.png",
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _legacyEmptyStateDescription,
                  textAlign: TextAlign.center,
                  style: textTheme.small.copyWith(
                    color: colorScheme.textMuted,
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GradientButton(
                text: context.strings.addTrustedContact,
                height: 52,
                textStyle: buttonTextStyle,
                onTap: () async {
                  await onAddContact();
                },
              ),
              if (onCreateLegacyKit != null) ...[
                const SizedBox(height: 12),
                GradientButton(
                  text: context.strings.createLegacyKit,
                  height: 52,
                  textStyle: buttonTextStyle,
                  onTap: () async {
                    await onCreateLegacyKit!();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LegacyKitLeadingIcon extends StatelessWidget {
  final Color color;

  const _LegacyKitLeadingIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.insert_drive_file_outlined,
        size: 18,
        color: color,
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String text;

  const _WarningBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.warning400.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Image.asset("assets/warning-red.png", width: 32, height: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyBold.copyWith(color: colorScheme.warning400),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustedContactsEmptyCard extends StatelessWidget {
  final Future<void> Function() onAddContact;

  const _TrustedContactsEmptyCard({required this.onAddContact});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final cardColor =
        colorScheme.isLightTheme ? Colors.white : colorScheme.backdropBase;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            colorScheme.isLightTheme
                ? "assets/trusted_contact_empty.png"
                : "assets/trusted_contact_empty_dark.png",
            width: 45,
            height: 45,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            "Nominate another Ente user as a trusted contact to recover your account",
            textAlign: TextAlign.center,
            style: textTheme.small.copyWith(
              color: colorScheme.textMuted,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            text: context.strings.addTrustedContact,
            height: 52,
            textStyle: textTheme.small.copyWith(height: 20 / 14),
            onTap: () async {
              await onAddContact();
            },
          ),
        ],
      ),
    );
  }
}

class _LegacyKitEmptyCard extends StatelessWidget {
  final Future<void> Function() onCreate;

  const _LegacyKitEmptyCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final cardColor = colorScheme.isLightTheme
        ? Colors.white
        : colorScheme.backgroundElevated2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/legacy_kit_empty.png",
            width: 43,
            height: 42,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            "Split your account recovery among people you really trust",
            textAlign: TextAlign.center,
            style: textTheme.small.copyWith(
              color: colorScheme.textMuted,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            text: context.strings.createLegacyKit,
            height: 52,
            textStyle: textTheme.small.copyWith(height: 20 / 14),
            onTap: () async {
              await onCreate();
            },
          ),
        ],
      ),
    );
  }
}
