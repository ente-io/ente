// @dart=2.9

import 'package:ente_auth/app/view/app.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/locale.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/account/change_email_dialog.dart';
import 'package:ente_auth/ui/account/password_entry_page.dart';
import 'package:ente_auth/ui/account/recovery_key_page.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/ui/settings/language_picker.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

class AccountSectionWidget extends StatelessWidget {
  AccountSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.account,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.account_circle_outlined,
    );
  }

  Column _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    List<Widget> children = [];
    children.addAll([
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.recoveryKey,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            l10n.authToViewYourRecoveryKey,
          );
          if (hasAuthenticated) {
            String recoveryKey;
            try {
              recoveryKey =
                  Sodium.bin2hex(Configuration.instance.getRecoveryKey());
            } catch (e) {
              showGenericErrorDialog(context);
              return;
            }
            routeToPage(
              context,
              RecoveryKeyPage(
                recoveryKey,
                l10n.ok,
                showAppBar: true,
                onDone: () {},
              ),
            );
          }
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.changeEmail,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            l10n.authToChangeYourEmail,
          );
          if (hasAuthenticated) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const ChangeEmailDialog();
              },
              barrierColor: Colors.black.withOpacity(0.85),
              barrierDismissible: false,
            );
          }
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.changePassword,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            l10n.authToChangeYourPassword,
          );
          if (hasAuthenticated) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const PasswordEntryPage(
                    mode: PasswordEntryMode.update,
                  );
                },
              ),
            );
          }
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.language,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final locale = await getLocale();
          routeToPage(
            context,
            LanguageSelectorPage(
              appSupportedLocales,
              (locale) async {
                await setLocale(locale);
                App.setLocale(context, locale);
              },
              locale,
            ),
          );
        },
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }
}
