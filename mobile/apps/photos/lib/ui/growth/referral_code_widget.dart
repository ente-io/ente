import "package:dio/dio.dart";
import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/user_details.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/dialog_util.dart";

// Figma: https://www.figma.com/file/SYtMyLBs5SAOkTbfMMzhqt/ente-Visual-Design?node-id=11219%3A62974&t=BRCLJhxXP11Q3Wyw-0
class ReferralCodeWidget extends StatelessWidget {
  final String codeValue;
  final bool shouldShowEdit;
  final UserDetails? userDetails;
  final Function? notifyParent;

  const ReferralCodeWidget(
    this.codeValue, {
    this.shouldShowEdit = false,
    this.userDetails,
    this.notifyParent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    return Center(
      child: Container(
        color: colorScheme.backgroundElevated2,
        child: DottedBorder(
          color: colorScheme.strokeMuted,
          strokeWidth: 1,
          dashPattern: const [6, 6],
          radius: const Radius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 26.0,
              top: 14,
              right: 12,
              bottom: 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  codeValue,
                  style: textStyle.bodyBold.copyWith(
                    color: colorScheme.primary700,
                  ),
                ),
                const SizedBox(width: 12),
                shouldShowEdit
                    ? GestureDetector(
                        onTap: () {
                          if (userDetails!.isPartOfFamily() &&
                              !userDetails!.isFamilyAdmin()) {
                            final String familyAdmin = userDetails!
                                .familyData!.members!
                                .firstWhere((element) => element.isAdmin)
                                .email;
                            showInfoDialog(
                              context,
                              title: AppLocalizations.of(context).error,
                              body: AppLocalizations.of(context)
                                  .onlyFamilyAdminCanChangeCode(
                                familyAdminEmail: familyAdmin,
                              ),
                              icon: Icons.error,
                            );
                          } else {
                            showUpdateReferralCodeDialog(context);
                          }
                        },
                        child: Icon(
                          Icons.edit,
                          size: 22,
                          color: colorScheme.strokeMuted,
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showUpdateReferralCodeDialog(BuildContext context) async {
    final result = await showTextInputDialog(
      context,
      title: AppLocalizations.of(context).changeYourReferralCode,
      submitButtonLabel: AppLocalizations.of(context).change,
      hintText: AppLocalizations.of(context).enterCode,
      alwaysShowSuccessState: true,
      initialValue: codeValue,
      textCapitalization: TextCapitalization.characters,
      onSubmit: (String text) async {
        // indicates user cancelled the request
        if (text == "" || text.trim() == codeValue) {
          return;
        }

        try {
          await storageBonusService.updateCode(text);
          notifyParent?.call();
        } catch (e, s) {
          Logger("ReferralCodeWidget").severe("Failed to update code", e, s);
          if (e is DioException) {
            if (e.response?.statusCode == 400) {
              await showInfoDialog(
                context,
                title: AppLocalizations.of(context).error,
                body: AppLocalizations.of(context).unavailableReferralCode,
                icon: Icons.error,
              );
              return;
            } else if (e.response?.statusCode == 429) {
              await showInfoDialog(
                context,
                title: AppLocalizations.of(context).error,
                body: AppLocalizations.of(context).codeChangeLimitReached,
                icon: Icons.error,
              );
              return;
            }
          }
          rethrow;
        }
      },
    );
    if (result is Exception) {
      await showGenericErrorDialog(context: context, error: result);
    }
  }
}
