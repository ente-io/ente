import "dart:async";

import "package:ente_accounts/services/user_service.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/components/buttons/gradient_button.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/settings/pages/about_page.dart";
import "package:locker/ui/settings/pages/account_settings_page.dart";
import "package:locker/ui/settings/pages/general_settings_page.dart";
import "package:locker/ui/settings/pages/security_settings_page.dart";
import "package:locker/ui/settings/pages/support_page.dart";
import "package:locker/ui/settings/pages/theme_settings_page.dart";
import "package:locker/ui/settings/widgets/suggestion_chip.dart";

class SettingsSearchPage extends StatefulWidget {
  const SettingsSearchPage({super.key});

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState extends State<SettingsSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _searchQuery = "";
  List<_SearchableSetting> _searchResults = [];
  late List<_SearchableSetting> _allSettings;
  late List<_SearchableSetting> _suggestions;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allSettings = _buildSettingsList(context);
    _suggestions = _getDefaultSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<_SearchableSetting> _buildSettingsList(BuildContext context) {
    final l10n = context.l10n;
    final hasLoggedIn = Configuration.instance.hasConfiguredAccount();

    return [
      if (hasLoggedIn) ...[
        _SearchableSetting(
          title: l10n.account,
          category: l10n.account,
          page: const AccountSettingsPage(),
        ),
        _SearchableSetting(
          title: l10n.changeEmail,
          category: l10n.account,
          page: const AccountSettingsPage(),
        ),
        _SearchableSetting(
          title: l10n.recoveryKey,
          category: l10n.account,
          page: const AccountSettingsPage(),
        ),
        _SearchableSetting(
          title: l10n.changePassword,
          category: l10n.account,
          page: const AccountSettingsPage(),
        ),
        _SearchableSetting(
          title: l10n.deleteAccount,
          category: l10n.account,
          page: const AccountSettingsPage(),
        ),
        _SearchableSetting(
          title: l10n.security,
          category: l10n.security,
          page: const SecuritySettingsPage(),
        ),
        _SearchableSetting(
          title: l10n.appLock,
          category: l10n.security,
          page: const SecuritySettingsPage(),
        ),
        _SearchableSetting(
          title: l10n.appearance,
          category: l10n.appearance,
          page: const ThemeSettingsPage(),
        ),
      ],
      _SearchableSetting(
        title: l10n.general,
        category: l10n.general,
        page: const GeneralSettingsPage(),
      ),
      _SearchableSetting(
        title: l10n.selectLanguage,
        category: l10n.general,
        page: const GeneralSettingsPage(),
      ),
      _SearchableSetting(
        title: l10n.helpAndSupport,
        category: l10n.helpAndSupport,
        page: const SupportPage(),
      ),
      _SearchableSetting(
        title: l10n.contactSupport,
        category: l10n.helpAndSupport,
        page: const SupportPage(),
      ),
      _SearchableSetting(
        title: l10n.help,
        category: l10n.helpAndSupport,
        page: const SupportPage(),
      ),
      _SearchableSetting(
        title: l10n.suggestFeatures,
        category: l10n.helpAndSupport,
        page: const SupportPage(),
      ),
      _SearchableSetting(
        title: l10n.reportABug,
        category: l10n.helpAndSupport,
        page: const SupportPage(),
      ),
      _SearchableSetting(
        title: l10n.aboutUs,
        category: l10n.aboutUs,
        page: const AboutPage(),
      ),
      _SearchableSetting(
        title: l10n.weAreOpenSource,
        category: l10n.aboutUs,
        page: const AboutPage(),
      ),
      _SearchableSetting(
        title: l10n.privacy,
        category: l10n.aboutUs,
        page: const AboutPage(),
      ),
      _SearchableSetting(
        title: l10n.termsOfServicesTitle,
        category: l10n.aboutUs,
        page: const AboutPage(),
      ),
      if (hasLoggedIn)
        _SearchableSetting(
          title: l10n.logout,
          category: l10n.logout,
          onTap: _onLogoutTapped,
        ),
    ];
  }

  List<_SearchableSetting> _getDefaultSuggestions() {
    final l10n = context.l10n;
    final hasLoggedIn = Configuration.instance.hasConfiguredAccount();

    return _allSettings.where((s) {
      if (hasLoggedIn) {
        return s.title == l10n.appLock ||
            s.title == l10n.appearance ||
            s.title == l10n.selectLanguage ||
            s.title == l10n.privacy;
      } else {
        return s.title == l10n.selectLanguage ||
            s.title == l10n.help ||
            s.title == l10n.privacy;
      }
    }).toList();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim().toLowerCase();
          if (_searchQuery.isEmpty) {
            _searchResults = [];
          } else {
            _searchResults = _allSettings.where((setting) {
              return _containsQuery(setting.title, _searchQuery) ||
                  _containsQuery(setting.category, _searchQuery);
            }).toList();
          }
        });
      }
    });
  }

  bool _containsQuery(String text, String query) {
    if (text.isEmpty) return false;
    final lowerText = text.toLowerCase();
    if (lowerText.contains(query)) {
      return true;
    }
    final words = lowerText.split(RegExp(r'[\s\-_\.]+'));
    return words.any((word) => word.startsWith(query));
  }

  void _onSettingTapped(_SearchableSetting setting) {
    if (setting.onTap != null) {
      setting.onTap!();
    } else if (setting.page != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => setting.page!),
      );
    }
  }

  void _onLogoutTapped() {
    showAlertBottomSheet(
      context,
      title: context.l10n.warning,
      message: context.l10n.areYouSureYouWantToLogout,
      assetPath: "assets/warning-grey.png",
      buttons: [
        GradientButton(
          buttonType: GradientButtonType.critical,
          text: context.l10n.yesLogout,
          onTap: () async {
            await UserService.instance.logout(context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.backdropBase,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.only(left: 8, right: 16),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: colorScheme.textMuted,
                        size: 20,
                        strokeWidth: 1.75,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onSearchChanged,
                        style: textTheme.body.copyWith(
                          color: colorScheme.textBase,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.searchSettings,
                          hintStyle: textTheme.body.copyWith(
                            color: colorScheme.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: colorScheme.textMuted,
                        size: 20,
                        strokeWidth: 1.75,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildSuggestions(colorScheme, textTheme, l10n)
                  : _buildSearchResults(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.suggestions,
            style: textTheme.body.copyWith(
              color: colorScheme.textBase,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (setting) => SuggestionChip(
                    label: setting.title,
                    onTap: () => _onSettingTapped(setting),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noResultsFound,
          style: textTheme.body.copyWith(
            color: colorScheme.textMuted,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final setting = _searchResults[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onSettingTapped(setting),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.backdropBase,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        setting.title,
                        style: textTheme.body.copyWith(
                          color: colorScheme.textBase,
                        ),
                      ),
                      if (setting.title != setting.category)
                        Text(
                          setting.category,
                          style: textTheme.mini.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchableSetting {
  final String title;
  final String category;
  final Widget? page;
  final VoidCallback? onTap;

  const _SearchableSetting({
    required this.title,
    required this.category,
    this.page,
    this.onTap,
  });
}
