import "dart:async";

import "package:ente_configuration/base_configuration.dart";
import "package:ente_legacy/models/emergency_models.dart";
import "package:ente_legacy/pages/other_contact_page.dart";
import "package:ente_legacy/pages/select_contact_page.dart";
import "package:ente_legacy/services/emergency_service.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/action_sheet_widget.dart";
import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_type.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/loading_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/components/notification_widget.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/components/title_bar_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/navigation_util.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:flutter_svg/svg.dart";

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
          if (info != null) {
            hasTrustedContact = info!.contacts.isNotEmpty;
          }
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
    final List<EmergencyContact> othersTrustedContacts =
        info?.othersEmergencyContact ?? [];
    final List<EmergencyContact> trustedContacts = info?.contacts ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: context.strings.legacy,
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
                        child: NotificationWidget(
                          startIcon: Icons.warning_amber_rounded,
                          text: context.strings.recoveryWarning,
                          actionIcon: null,
                          onTap: () {},
                        ),
                      );
                    }
                    final RecoverySessions recoverSession =
                        info!.recoverSessions[index - 1];
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: recoverSession.emergencyContact.email,
                        makeTextBold: recoverSession.status.isNotEmpty,
                        textColor: colorScheme.warning500,
                      ),
                      leadingIconWidget: UserAvatarWidget(
                        recoverSession.emergencyContact,
                        currentUserID: currentUserID,
                        config: widget.config,
                      ),
                      leadingIconSize: 24,
                      menuItemColor: colorScheme.fillFaint,
                      singleBorderRadius: 8,
                      trailingIcon: Icons.chevron_right,
                      onTap: () async {
                        await showRejectRecoveryDialog(recoverSession);
                      },
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
                      return Column(
                        children: [
                          MenuItemWidget(
                            captionedTextWidget: CaptionedTextWidget(
                              title: contact.emergencyContact.email,
                              subTitle: contact.isPendingInvite() ? "⚠" : null,
                              makeTextBold: contact.isPendingInvite(),
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
                            menuItemColor:
                                getEnteColorScheme(context).fillFaint,
                            trailingIcon: Icons.chevron_right,
                            trailingIconIsMuted: true,
                            onTap: () async {
                              await showRevokeOrRemoveDialog(context, contact);
                            },
                            isTopBorderRadiusRemoved: listIndex > 0,
                            isBottomBorderRadiusRemoved: true,
                            singleBorderRadius: 8,
                          ),
                          DividerWidget(
                            dividerType: DividerType.menu,
                            bgColor: getEnteColorScheme(context).fillFaint,
                          ),
                        ],
                      );
                    } else if (index == (1 + trustedContacts.length)) {
                      if (trustedContacts.isEmpty) {
                        return Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              context.strings.legacyPageDesc,
                              style: getEnteTextTheme(context).body,
                            ),
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: SvgPicture.asset(
                                getEnteColorScheme(context).backdropBase ==
                                        backgroundBaseDark
                                    ? "assets/icons/legacy-light.svg"
                                    : "assets/icons/legacy-dark.svg",
                                width: 156,
                                height: 152,
                              ),
                            ),
                            Text(
                              context.strings.legacyPageDesc2,
                              style: getEnteTextTheme(context).smallMuted,
                            ),
                            const SizedBox(height: 16),
                            ButtonWidget(
                              buttonType: ButtonType.primary,
                              labelText: context.strings.addTrustedContact,
                              shouldSurfaceExecutionStates: false,
                              onTap: () async {
                                await routeToPage(
                                  context,
                                  AddContactPage(
                                    info!,
                                    config: widget.config,
                                  ),
                                  forceCustomPageRoute: true,
                                );
                                unawaited(_fetchData());
                              },
                            ),
                          ],
                        );
                      }
                      return MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: trustedContacts.isNotEmpty
                              ? context.strings.addMore
                              : context.strings.addTrustedContact,
                          makeTextBold: true,
                        ),
                        leadingIcon: Icons.add_outlined,
                        surfaceExecutionStates: false,
                        menuItemColor: getEnteColorScheme(context).fillFaint,
                        onTap: () async {
                          await routeToPage(
                            context,
                            AddContactPage(
                              info!,
                              config: widget.config,
                            ),
                            forceCustomPageRoute: true,
                          );
                          unawaited(_fetchData());
                        },
                        isTopBorderRadiusRemoved: trustedContacts.isNotEmpty,
                        singleBorderRadius: 8,
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
                          MenuItemWidget(
                            captionedTextWidget: CaptionedTextWidget(
                              title: currentUser.user.email,
                              makeTextBold: currentUser.isPendingInvite(),
                              subTitle:
                                  currentUser.isPendingInvite() ? "⚠" : null,
                            ),
                            leadingIconSize: 24.0,
                            leadingIconWidget: UserAvatarWidget(
                              currentUser.user,
                              type: AvatarType.mini,
                              currentUserID: currentUserID,
                              config: widget.config,
                            ),
                            menuItemColor:
                                getEnteColorScheme(context).fillFaint,
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
                            singleBorderRadius: 8,
                            surfaceExecutionStates: false,
                          ),
                          isLastItem
                              ? const SizedBox.shrink()
                              : DividerWidget(
                                  dividerType: DividerType.menu,
                                  bgColor:
                                      getEnteColorScheme(context).fillFaint,
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
    if (contact.isPendingInvite()) {
      await showActionSheet(
        context: context,
        body:
            "You have invited ${contact.emergencyContact.email} to be a trusted contact",
        bodyHighlight: "They are yet to accept your invite",
        buttons: [
          ButtonWidget(
            labelText: "context.strings.removeInvite",
            buttonType: ButtonType.critical,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.first,
            shouldStickToDarkTheme: true,
            shouldSurfaceExecutionStates: true,
            shouldShowSuccessConfirmation: false,
            onTap: () async {
              await EmergencyContactService.instance
                  .updateContact(contact, ContactState.userRevokedContact);
              info?.contacts.remove(contact);
              if (mounted) {
                setState(() {});
                unawaited(_fetchData());
              }
            },
            isInAlert: true,
          ),
          ButtonWidget(
            labelText: context.strings.cancel,
            buttonType: ButtonType.tertiary,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.second,
            shouldStickToDarkTheme: true,
            isInAlert: true,
          ),
        ],
      );
    } else {
      await showActionSheet(
        context: context,
        body:
            "You have added ${contact.emergencyContact.email} as a trusted contact",
        bodyHighlight: "They have accepted your invite",
        buttons: [
          ButtonWidget(
            labelText: "context.strings.remove",
            buttonType: ButtonType.critical,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.second,
            shouldStickToDarkTheme: true,
            shouldSurfaceExecutionStates: true,
            shouldShowSuccessConfirmation: false,
            onTap: () async {
              await EmergencyContactService.instance
                  .updateContact(contact, ContactState.userRevokedContact);
              info?.contacts.remove(contact);
              if (mounted) {
                setState(() {});
                unawaited(_fetchData());
              }
            },
            isInAlert: true,
          ),
          ButtonWidget(
            labelText: context.strings.cancel,
            buttonType: ButtonType.tertiary,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.third,
            shouldStickToDarkTheme: true,
            isInAlert: true,
          ),
        ],
      );
    }
  }

  Future<void> showAcceptOrDeclineDialog(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: "context.strings.acceptTrustInvite",
          buttonType: ButtonType.primary,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          onTap: () async {
            await EmergencyContactService.instance
                .updateContact(contact, ContactState.contactAccepted);
            final updatedContact =
                contact.copyWith(state: ContactState.contactAccepted);
            info?.othersEmergencyContact.remove(contact);
            info?.othersEmergencyContact.add(updatedContact);
            if (mounted) {
              setState(() {});
            }
          },
          isInAlert: true,
        ),
        ButtonWidget(
          labelText: context.strings.declineTrustInvite,
          buttonType: ButtonType.critical,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
          shouldStickToDarkTheme: true,
          onTap: () async {
            await EmergencyContactService.instance
                .updateContact(contact, ContactState.contactDenied);
            info?.othersEmergencyContact.remove(contact);
            if (mounted) {
              setState(() {});
            }
          },
          isInAlert: true,
        ),
        ButtonWidget(
          labelText: context.strings.cancel,
          buttonType: ButtonType.tertiary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.third,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
      body: "context.strings.legacyInvite(email: contact.user.email)",
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    return;
  }

  Future<void> showRejectRecoveryDialog(RecoverySessions session) async {
    final String emergencyContactEmail = session.emergencyContact.email;
    await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: context.strings.rejectRecovery,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonType: ButtonType.critical,
          buttonAction: ButtonAction.first,
          onTap: () async {
            await EmergencyContactService.instance.rejectRecovery(session);
            info?.recoverSessions
                .removeWhere((element) => element.id == session.id);
            if (mounted) {
              setState(() {});
            }
            unawaited(_fetchData());
          },
          isInAlert: true,
        ),
        if (kDebugMode)
          ButtonWidget(
            labelText: "Approve recovery (to be removed)",
            buttonType: ButtonType.primary,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.second,
            shouldStickToDarkTheme: true,
            onTap: () async {
              await EmergencyContactService.instance.approveRecovery(session);
              if (mounted) {
                setState(() {});
              }
              unawaited(_fetchData());
            },
            isInAlert: true,
          ),
        ButtonWidget(
          labelText: context.strings.cancel,
          buttonType: ButtonType.tertiary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.third,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
      body: context.strings.recoveryWarningBody(emergencyContactEmail),
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    return;
  }
}
