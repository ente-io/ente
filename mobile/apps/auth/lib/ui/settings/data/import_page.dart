import 'package:ente_accounts/models/user_details.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/divider_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/title_bar_title_widget.dart';
import 'package:ente_auth/ui/components/title_bar_widget.dart';
import 'package:ente_auth/ui/settings/data/import/import_service.dart';
import 'package:ente_auth/ui/settings_page.dart';
import 'package:flutter/material.dart';

enum ImportType {
  plainText,
  encrypted,
  ravio,
  googleAuthenticator,
  aegis,
  twoFas,
  bitwarden,
  lastpass,
  proton,
}

class ImportCodePage extends StatefulWidget {
  const ImportCodePage({super.key});

  @override
  State<ImportCodePage> createState() => _ImportCodePageState();
}

class _ImportCodePageState extends State<ImportCodePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<String?> _emailNotifier = ValueNotifier<String?>(null);
  late final SettingsPage _settingsPage;

  @override
  void initState() {
    super.initState();
    _settingsPage = SettingsPage(
      emailNotifier: _emailNotifier,
      scaffoldKey: _scaffoldKey,
    );
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    if (Configuration.instance.hasConfiguredAccount()) {
      try {
        final UserDetails details =
            await UserService.instance.getUserDetailsV2(memoryCount: false);
        _emailNotifier.value = details.email;
      } catch (_) {
        // Ignore errors
      }
    }
  }

  @override
  void dispose() {
    _emailNotifier.dispose();
    super.dispose();
  }

  static const List<ImportType> importOptions = [
    ImportType.plainText,
    ImportType.encrypted,
    ImportType.twoFas,
    ImportType.aegis,
    ImportType.bitwarden,
    ImportType.googleAuthenticator,
    ImportType.proton,
    ImportType.ravio,
    ImportType.lastpass,
  ];

  String _getTitle(BuildContext context, ImportType type) {
    switch (type) {
      case ImportType.plainText:
        return context.l10n.importTypePlainText;
      case ImportType.encrypted:
        return context.l10n.importTypeEnteEncrypted;
      case ImportType.ravio:
        return 'Raivo OTP';
      case ImportType.googleAuthenticator:
        return 'Google Authenticator';
      case ImportType.aegis:
        return 'Aegis Authenticator';
      case ImportType.twoFas:
        return '2FAS Authenticator';
      case ImportType.bitwarden:
        return 'Bitwarden';
      case ImportType.lastpass:
        return 'LastPass Authenticator';
      case ImportType.proton:
        return 'Proton Authenticator';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          width: 428,
          child: _settingsPage,
        ),
        body: CustomScrollView(
          primary: false,
          slivers: <Widget>[
            TitleBarWidget(
              flexibleSpaceTitle: TitleBarTitleWidget(
                title: context.l10n.importCodes,
              ),
              flexibleSpaceCaption: "Import source",
              actionIcons: const [],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (delegateBuildContext, index) {
                  final type = importOptions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        if (index == 0)
                          const SizedBox(
                            height: 24,
                          ),
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: _getTitle(context, type),
                          ),
                          alignCaptionedTextToLeft: true,
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          pressedColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: Icons.chevron_right_outlined,
                          isBottomBorderRadiusRemoved:
                              index != importOptions.length - 1,
                          isTopBorderRadiusRemoved: index != 0,
                          onTap: () async {
                            await ImportService().initiateImport(context, type);
                            // routeToPage(context, ImportCodePage());
                            // _showImportInstructionDialog(context);
                          },
                        ),
                        if (index != importOptions.length - 1)
                          DividerWidget(
                            dividerType: DividerType.menu,
                            bgColor: getEnteColorScheme(context).fillFaint,
                          ),
                      ],
                    ),
                  );
                },
                childCount: importOptions.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
