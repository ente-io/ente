import "dart:async";

import "package:ente_configuration/base_configuration.dart";
import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_legacy/components/invite_reject_bottom_sheet.dart";
import "package:ente_legacy/components/trusted_contact_bottom_sheet.dart";
import "package:ente_legacy/models/emergency_models.dart";
import "package:ente_legacy/pages/other_contact_page.dart";
import "package:ente_legacy/pages/select_contact_page.dart";
import "package:ente_legacy/services/emergency_service.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/components/captioned_text_widget_v2.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/loading_widget.dart";
import "package:ente_ui/components/menu_item_widget_v2.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';

class EmergencyPage extends StatefulWidget {
  final BaseConfiguration config;

  const EmergencyPage({
    required this.config,
    super.key,
  });

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  late int currentUserID;
  EmergencyInfo? info;
  bool hasTrustedContact = false;

  @override
  void initState() {
    super.initState();
    currentUserID = widget.config.getUserID()!;
    Future.delayed(
      const Duration(seconds: 0),
      () async {
        unawaited(_fetchData());
      },
    );
  }

  Future<void> _fetchData() async {
    try {
      final result = await EmergencyContactService.instance.getInfo();
      if (mounted) {
        setState(() {
          info = result;
          hasTrustedContact = info?.contacts.isNotEmpty ?? false;
        });
      }
    } catch (e) {
      showShortToast(
        context,
        context.strings.somethingWentWrong,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final List<EmergencyContact> othersTrustedContacts =
        info?.othersEmergencyContact ?? [];
    final List<EmergencyContact> trustedContacts = info?.contacts ?? [];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TitleBarTitleWidget(
                title: context.strings.legacy,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.strings.legacyPageDesc,
                style: textTheme.smallMuted,
              ),
            ),
          ),
          if (info == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EnteLoadingWidget(),
              ),
            ),
          if (info != null && info!.recoverSessions.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
              ),
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
                            title: recoverSession.emergencyContact.email,
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
          if (info != null)
            SliverPadding(
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0 && trustedContacts.isNotEmpty) {
                      return MenuSectionTitle(
                        title: context.strings.trustedContacts,
                      );
                    } else if (index > 0 && index <= trustedContacts.length) {
                      final listIndex = index - 1;
                      final contact = trustedContacts[listIndex];
                      final isLastItem =
                          listIndex == trustedContacts.length - 1;
                      return Column(
                        children: [
                          MenuItemWidgetV2(
                            captionedTextWidget: CaptionedTextWidgetV2(
                              title: contact.emergencyContact.email,
                              textStyle: textTheme.small
                                  .copyWith(color: colorScheme.textMuted),
                              trailingTitleWidget: contact.isPendingInvite()
                                  ? Image.asset(
                                      "assets/warning-yellow.png",
                                      width: 20,
                                      height: 20,
                                    )
                                  : null,
                            ),
                            leadingIconSize: 24.0,
                            surfaceExecutionStates: false,
                            alwaysShowSuccessState: false,
                            leadingIconWidget: UserAvatarWidget(
                              contact.emergencyContact,
                              type: AvatarType.mini,
                              currentUserID: currentUserID,
                              config: widget.config,
                            ),
                            menuItemColor: colorScheme.fillFaint,
                            trailingIcon: Icons.chevron_right,
                            trailingIconIsMuted: true,
                            onTap: () async {
                              await showRevokeOrRemoveDialog(context, contact);
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
                    } else if (index == (1 + trustedContacts.length)) {
                      if (trustedContacts.isEmpty) {
                        return Column(
                          children: [
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
                            GradientButton(
                              text: context.strings.addTrustedContact,
                              onTap: () async {
                                final result = await showAddContactSheet(
                                  context,
                                  emergencyInfo: info!,
                                  config: widget.config,
                                );
                                if (result == true) {
                                  unawaited(_fetchData());
                                }
                              },
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          GradientButton(
                            text: context.strings.addTrustedContact,
                            onTap: () async {
                              final result = await showAddContactSheet(
                                context,
                                emergencyInfo: info!,
                                config: widget.config,
                              );
                              if (result == true) {
                                unawaited(_fetchData());
                              }
                            },
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: 1 + trustedContacts.length + 1,
                ),
              ),
            ),
          if (info != null && info!.othersEmergencyContact.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0 && (othersTrustedContacts.isNotEmpty)) {
                      return Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: DividerWidget(
                              dividerType: DividerType.solid,
                            ),
                          ),
                          MenuSectionTitle(
                            title: context.strings.legacyAccounts,
                          ),
                        ],
                      );
                    } else if (index > 0 &&
                        index <= othersTrustedContacts.length) {
                      final listIndex = index - 1;
                      final currentUser = othersTrustedContacts[listIndex];
                      final isLastItem = index == othersTrustedContacts.length;
                      return Column(
                        children: [
                          MenuItemWidgetV2(
                            captionedTextWidget: CaptionedTextWidgetV2(
                              title: currentUser.user.email,
                              textStyle: textTheme.small.copyWith(
                                color: colorScheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              trailingTitleWidget: currentUser.isPendingInvite()
                                  ? Image.asset(
                                      "assets/warning-yellow.png",
                                      width: 20,
                                      height: 20,
                                    )
                                  : null,
                            ),
                            leadingIconSize: 24.0,
                            surfaceExecutionStates: false,
                            alwaysShowSuccessState: false,
                            leadingIconWidget: UserAvatarWidget(
                              currentUser.user,
                              type: AvatarType.mini,
                              currentUserID: currentUserID,
                              config: widget.config,
                            ),
                            menuItemColor: colorScheme.fillFaint,
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
                            isTopBorderRadiusRemoved: listIndex > 0,
                            isBottomBorderRadiusRemoved: !isLastItem,
                            isFirstItem: listIndex == 0,
                            isLastItem: isLastItem,
                          ),
                          isLastItem
                              ? const SizedBox.shrink()
                              : DividerWidget(
                                  dividerType: DividerType.menu,
                                  bgColor: colorScheme.fillFaint,
                                ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: 1 + othersTrustedContacts.length + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> showRevokeOrRemoveDialog(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final result = await showTrustedContactSheet(
      context,
      contact: contact,
    );

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
        await EmergencyContactService.instance
            .updateContact(contact, ContactState.userRevokedContact);
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
          final updatedContact =
              contact.copyWith(recoveryNoticeInDays: selectedDays);
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
      await EmergencyContactService.instance
          .updateContact(contact, ContactState.contactAccepted);
      final updatedContact =
          contact.copyWith(state: ContactState.contactAccepted);
      info?.othersEmergencyContact.remove(contact);
      info?.othersEmergencyContact.add(updatedContact);
      if (mounted) {
        setState(() {});
      }
    } else if (result == "decline") {
      await EmergencyContactService.instance
          .updateContact(contact, ContactState.contactDenied);
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
        color: colorScheme.warning400.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Image.asset("assets/warning-red.png", width: 32, height: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyBold.copyWith(
                color: colorScheme.warning400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
