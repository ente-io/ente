import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/emergency/emergency_service.dart";
import "package:photos/emergency/model.dart";
import "package:photos/emergency/recover_others_account.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/api/user/key_attributes.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/menu_section_title.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/standalone/date_time.dart";

// OtherContactPage is used to start recovery process for other user's account
// Based on the state of the contact & recovery session, it will show
// different UI
class OtherContactPage extends StatefulWidget {
  final EmergencyContact contact;
  final EmergencyInfo emergencyInfo;

  const OtherContactPage({
    required this.contact,
    required this.emergencyInfo,
    super.key,
  });

  @override
  State<OtherContactPage> createState() => _OtherContactPageState();
}

class _OtherContactPageState extends State<OtherContactPage> {
  late String accountEmail = widget.contact.user.email;
  RecoverySessions? recoverySession;
  String? waitTill;
  final Logger _logger = Logger("_OtherContactPageState");
  late EmergencyInfo emergencyInfo = widget.emergencyInfo;

  @override
  void initState() {
    super.initState();
    recoverySession = widget.emergencyInfo.othersRecoverySession
        .firstWhereOrNull((session) => session.user.email == accountEmail);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await EmergencyContactService.instance.getInfo();
      if (mounted) {
        setState(() {
          recoverySession = result.othersRecoverySession.firstWhereOrNull(
            (session) => session.user.email == accountEmail,
          );
        });
      }
    } catch (e) {
      _logger.severe("Error fetching data", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('session ${widget.emergencyInfo}');
    if (recoverySession != null) {
      final dateTime = DateTime.now().add(
        Duration(
          microseconds: recoverySession!.waitTill,
        ),
      );
      waitTill = getFormattedTime(context, dateTime);
    }
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  TitleBarTitleWidget(
                    title: context.l10n.recoverAccount,
                  ),
                  Text(
                    accountEmail,
                    textAlign: TextAlign.left,
                    style:
                        textTheme.small.copyWith(color: colorScheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            recoverySession == null
                ? Text(
                    "You can recover $accountEmail's account in ${widget.contact.recoveryNoticeInDays} days"
                    " after starting the recovery process.",
                    style: textTheme.body,
                  )
                : (recoverySession!.status == "READY"
                    ? Text(
                        context.l10n.recoveryReady(email: accountEmail),
                        style: textTheme.body,
                      )
                    : Text(
                        "You can recover $accountEmail's"
                        " account after $waitTill.",
                        style: textTheme.bodyBold,
                      )),
            const SizedBox(height: 24),
            if (recoverySession == null)
              ButtonWidget(
                // icon: Icons.start_outlined,
                buttonType: ButtonType.trailingIconPrimary,
                icon: Icons.start_outlined,
                labelText:
                    AppLocalizations.of(context).startAccountRecoveryTitle,
                onTap: widget.contact.isPendingInvite()
                    ? null
                    : () async {
                        final actionResult = await showChoiceActionSheet(
                          context,
                          title: AppLocalizations.of(context)
                              .startAccountRecoveryTitle,
                          firstButtonLabel: AppLocalizations.of(context).yes,
                          body: "Are you sure you want to initiate recovery?",
                          isCritical: true,
                        );
                        if (actionResult?.action != null) {
                          if (actionResult!.action == ButtonAction.first) {
                            try {
                              await EmergencyContactService.instance
                                  .startRecovery(widget.contact);
                              if (mounted) {
                                _fetchData().ignore();
                                await showErrorDialog(
                                  context,
                                  context.l10n.recoveryInitiated,
                                  context.l10n.recoveryInitiatedDesc(
                                    days: widget.contact.recoveryNoticeInDays,
                                    email: Configuration.instance.getEmail()!,
                                  ),
                                );
                              }
                            } catch (e) {
                              showGenericErrorDialog(context: context, error: e)
                                  .ignore();
                            }
                          }
                        }
                      },
                // isTopBorderRadiusRemoved: true,
              ),
            if (recoverySession != null && recoverySession!.status == "READY")
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ButtonWidget(
                  buttonType: ButtonType.primary,
                  labelText: context.l10n.recoverAccount,
                  onTap: () async {
                    try {
                      final (String key, KeyAttributes attributes) =
                          await EmergencyContactService.instance
                              .getRecoveryInfo(recoverySession!);
                      routeToPage(
                        context,
                        RecoverOthersAccount(key, attributes, recoverySession!),
                      ).ignore();
                    } catch (e) {
                      showGenericErrorDialog(context: context, error: e)
                          .ignore();
                    }
                  },
                ),
              ),
            if (recoverySession != null &&
                (recoverySession!.status == "WAITING" ||
                    recoverySession!.status == "READY"))
              ButtonWidget(
                buttonType: ButtonType.neutral,
                labelText: AppLocalizations.of(context).cancelAccountRecovery,
                shouldSurfaceExecutionStates: false,
                onTap: () async {
                  final actionResult = await showChoiceActionSheet(
                    context,
                    title: AppLocalizations.of(context).cancelAccountRecovery,
                    firstButtonLabel: AppLocalizations.of(context).yes,
                    body:
                        AppLocalizations.of(context).cancelAccountRecoveryBody,
                    isCritical: true,
                    firstButtonOnTap: () async {
                      await EmergencyContactService.instance
                          .stopRecovery(recoverySession!);
                    },
                  );
                  if (actionResult?.action == ButtonAction.first) {
                    _fetchData().ignore();
                  }
                },
              ),
            SizedBox(height: recoverySession == null ? 48 : 24),
            MenuSectionTitle(
              title:
                  AppLocalizations.of(context).removeYourselfAsTrustedContact,
            ),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: AppLocalizations.of(context).remove,
                textColor: warning500,
                makeTextBold: true,
              ),
              leadingIcon: Icons.not_interested_outlined,
              leadingIconColor: warning500,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              surfaceExecutionStates: false,
              onTap: () async {
                await showRemoveSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showRemoveSheet() async {
    await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: context.l10n.remove,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonType: ButtonType.critical,
          buttonAction: ButtonAction.first,
          onTap: () async {
            try {
              await EmergencyContactService.instance.updateContact(
                widget.contact,
                ContactState.contactLeft,
              );
              Navigator.of(context).pop();
            } catch (e) {
              showGenericErrorDialog(context: context, error: e).ignore();
            }
          },
          isInAlert: true,
        ),
        ButtonWidget(
          labelText: AppLocalizations.of(context).cancel,
          buttonType: ButtonType.tertiary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.third,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
      body: "Are you sure your want to stop being a trusted "
          "contact for $accountEmail?",
      title: context.l10n.remove,
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    return;
  }
}
