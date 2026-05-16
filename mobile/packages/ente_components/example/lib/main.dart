import 'package:ente_components/ente_components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

typedef HugeIconData = List<List<dynamic>>;

void main() {
  runApp(const ComponentsCatalogApp());
}

class ComponentsCatalogApp extends StatefulWidget {
  const ComponentsCatalogApp({super.key});

  @override
  State<ComponentsCatalogApp> createState() => _ComponentsCatalogAppState();
}

class _ComponentsCatalogAppState extends State<ComponentsCatalogApp> {
  ThemeMode _themeMode = ThemeMode.light;
  EnteApp _appTheme = EnteApp.photos;
  Duration? _lastPointerUpAt;
  Offset? _lastPointerUpPosition;

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handlePointerEvent,
    );
    super.dispose();
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is! PointerUpEvent) {
      return;
    }

    final now = event.timeStamp;
    final lastPointerUpAt = _lastPointerUpAt;
    final lastPointerUpPosition = _lastPointerUpPosition;
    final isDoubleTap =
        lastPointerUpAt != null &&
        lastPointerUpPosition != null &&
        now - lastPointerUpAt <= const Duration(milliseconds: 320) &&
        (event.position - lastPointerUpPosition).distance <= 48;

    _lastPointerUpAt = isDoubleTap ? null : now;
    _lastPointerUpPosition = isDoubleTap ? null : event.position;

    if (isDoubleTap) {
      _cycleAppTheme();
    }
  }

  void _cycleAppTheme() {
    final nextTheme = switch (_appTheme) {
      EnteApp.photos => EnteApp.locker,
      EnteApp.locker => EnteApp.auth,
      EnteApp.auth => EnteApp.photos,
    };
    setState(() => _appTheme = nextTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Components',
      theme: ComponentTheme.lightTheme(app: _appTheme),
      darkTheme: ComponentTheme.darkTheme(app: _appTheme),
      themeMode: _themeMode,
      home: CatalogHome(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class CatalogHome extends StatefulWidget {
  const CatalogHome({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<CatalogHome> createState() => _CatalogHomeState();
}

class _CatalogHomeState extends State<CatalogHome> {
  late ThemeMode _themeMode = widget.themeMode;

  @override
  void didUpdateWidget(covariant CatalogHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _themeMode = widget.themeMode;
    }
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.onThemeModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final sections = _sections();

    return Scaffold(
      drawer: const CatalogSettingsDrawer(),
      body: CustomScrollView(
        slivers: [
          HeaderAppBarComponent(
            title: 'Components',
            subtitle: 'Design system catalog',
            backButton: Builder(
              builder: (context) {
                return IconButtonComponent(
                  tooltip: 'Settings',
                  variant: IconButtonComponentVariant.unfilled,
                  onTap: () => Scaffold.of(context).openDrawer(),
                  icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedMenu01),
                );
              },
            ),
            actions: [
              _CatalogThemeCycleButton(
                themeMode: _themeMode,
                onChanged: _setThemeMode,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xs,
              Spacing.lg,
              Spacing.lg,
            ),
            sliver: SliverList.builder(
              itemCount: sections.length * 2 - 1,
              itemBuilder: (context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: Spacing.lg);
                }
                return _CatalogSectionTile(
                  section: sections[index ~/ 2],
                  themeMode: _themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundBase,
    );
  }

  List<CatalogSection> _sections() {
    return [
      CatalogSection(
        title: 'Colours',
        icon: HugeIcons.strokeRoundedColors,
        components: const ['Color tokens'],
        previewBuilder: (_) => _ColorPreview(),
      ),
      CatalogSection(
        title: 'Text styles',
        icon: HugeIcons.strokeRoundedTextFont,
        components: const ['H1', 'H1-Bold', 'H2', 'Large', 'Body', 'Mini'],
        previewBuilder: (_) => const _TextStylesPreview(),
      ),
      CatalogSection(
        title: 'Menu Item',
        icon: HugeIcons.strokeRoundedUser,
        components: const [
          'Default',
          'Selected',
          'Loading',
          'Success',
          'Loading only',
          'Display only',
          'Leading icon',
          'No leading icon',
          'Subtitle',
          'No subtitle',
          'Trailing icon',
          'Trailing toggle',
          'No trailing',
          'Async state',
          'Destructive',
          'Long text',
        ],
        previewBuilder: (_) => const _MenuItemPreview(),
      ),
      CatalogSection(
        title: 'Buttons',
        icon: HugeIcons.strokeRoundedCursorPointer02,
        components: const ['Button', 'Icon button'],
        previewBuilder: (_) => const _ButtonMatrix(),
      ),
      CatalogSection(
        title: 'Filter chips',
        icon: HugeIcons.strokeRoundedFilter,
        components: const [
          'Selected',
          'Unselected',
          'Disabled',
          'Leading icon',
          'Trailing icon',
          'Face',
        ],
        previewBuilder: (_) => const _FilterChipPreview(),
      ),
      CatalogSection(
        title: 'Text input',
        icon: HugeIcons.strokeRoundedTypeCursor,
        components: const [
          'Single-line states',
          'Multiline states',
          'Label',
          'Trailing icon',
          'Clearable',
          'Password',
          'Warning message',
          'Alert message',
          'Read only',
          'Max length',
        ],
        previewBuilder: (_) => const _TextInputPreview(),
      ),
      CatalogSection(
        title: 'Header app bar',
        icon: HugeIcons.strokeRoundedHeading,
        components: const [
          'Expanded header',
          'Collapsed app bar',
          'Scroll animation',
          'Long list',
        ],
        previewBuilder: (_) => const _HeaderAppBarEntryPreview(),
        routeBuilder: _buildHeaderAppBarDemo,
      ),
      CatalogSection(
        title: 'Avatar',
        icon: HugeIcons.strokeRoundedUser,
        components: const ['Sizes', 'Seed palette', 'Add contact'],
        previewBuilder: (_) => const _AvatarPreview(),
      ),
      CatalogSection(
        title: 'Selection controls',
        icon: HugeIcons.strokeRoundedSlidersHorizontal,
        components: const ['Checkbox', 'Radio', 'Switch', 'Slider', 'Stepper'],
        previewBuilder: (_) => const _SelectionPreview(),
      ),
    ];
  }
}

typedef CatalogSectionRouteBuilder =
    Widget Function(
      BuildContext context,
      ThemeMode themeMode,
      ValueChanged<ThemeMode> onThemeModeChanged,
    );

Widget _buildHeaderAppBarDemo(
  BuildContext context,
  ThemeMode themeMode,
  ValueChanged<ThemeMode> onThemeModeChanged,
) {
  return HeaderAppBarDemoPage(
    themeMode: themeMode,
    onThemeModeChanged: onThemeModeChanged,
  );
}

class CatalogSection {
  const CatalogSection({
    required this.title,
    required this.icon,
    required this.components,
    required this.previewBuilder,
    this.routeBuilder,
  });

  final String title;
  final HugeIconData icon;
  final List<String> components;
  final WidgetBuilder previewBuilder;
  final CatalogSectionRouteBuilder? routeBuilder;
}

class CatalogSettingsDrawer extends StatelessWidget {
  const CatalogSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Drawer(
      width: _drawerWidth(context),
      shape: const RoundedRectangleBorder(),
      backgroundColor: colors.backgroundBase,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Row(
              children: [
                IconButtonComponent(
                  tooltip: 'Close settings',
                  variant: IconButtonComponentVariant.unfilled,
                  icon: const _CatalogHugeIcon(
                    HugeIcons.strokeRoundedArrowLeft02,
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyles.h1Bold.copyWith(color: colors.textBase),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            const _SettingsMainContent(),
          ],
        ),
      ),
    );
  }
}

double _drawerWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width < 430 ? width : 430;
}

class _CatalogHugeIcon extends StatelessWidget {
  const _CatalogHugeIcon(this.icon, {this.color, this.size = 24});

  final HugeIconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      color: color ?? IconTheme.of(context).color,
      size: size,
      strokeWidth: 1.6,
    );
  }
}

class _CatalogTrailingIcon extends StatelessWidget {
  const _CatalogTrailingIcon(this.icon);

  final HugeIconData icon;

  @override
  Widget build(BuildContext context) {
    return _CatalogHugeIcon(
      icon,
      color: context.componentColors.textLight,
      size: 18,
    );
  }
}

class _CatalogThemeCycleButton extends StatelessWidget {
  const _CatalogThemeCycleButton({
    required this.themeMode,
    required this.onChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  ThemeMode get _nextMode {
    return switch (themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
  }

  String get _currentLabel {
    return switch (themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'Light',
    };
  }

  String get _nextLabel {
    return switch (_nextMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'Light',
    };
  }

  HugeIconData get _icon {
    return switch (themeMode) {
      ThemeMode.light => HugeIcons.strokeRoundedSun01,
      ThemeMode.dark => HugeIcons.strokeRoundedMoon02,
      ThemeMode.system => HugeIcons.strokeRoundedSun01,
    };
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonComponent(
      tooltip: 'Theme: $_currentLabel. Tap for $_nextLabel',
      variant: IconButtonComponentVariant.primary,
      icon: _CatalogHugeIcon(_icon),
      onTap: () => onChanged(_nextMode),
    );
  }
}

class _CatalogSectionTile extends StatelessWidget {
  const _CatalogSectionTile({
    required this.section,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final CatalogSection section;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return MenuComponent(
      key: ValueKey('catalog-section-${section.title}'),
      title: section.title,
      leading: _CatalogHugeIcon(section.icon, size: 18),
      trailing: _CatalogHugeIcon(
        HugeIcons.strokeRoundedArrowRight02,
        color: colors.textLight,
        size: 18,
      ),
      onTap: () {
        final routeBuilder = section.routeBuilder;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => routeBuilder == null
                ? CatalogDetailPage(
                    section: section,
                    themeMode: themeMode,
                    onThemeModeChanged: onThemeModeChanged,
                  )
                : routeBuilder(context, themeMode, onThemeModeChanged),
          ),
        );
      },
    );
  }
}

class CatalogDetailPage extends StatefulWidget {
  const CatalogDetailPage({
    super.key,
    required this.section,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final CatalogSection section;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<CatalogDetailPage> createState() => _CatalogDetailPageState();
}

class _CatalogDetailPageState extends State<CatalogDetailPage> {
  late ThemeMode _themeMode = widget.themeMode;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.onThemeModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          HeaderAppBarComponent(
            title: widget.section.title,
            subtitle: widget.section.components.join(', '),
            onBack: () => Navigator.of(context).pop(),
            actions: [
              _CatalogThemeCycleButton(
                themeMode: _themeMode,
                onChanged: _setThemeMode,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xs,
              Spacing.lg,
              Spacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: widget.section.previewBuilder(context),
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundBase,
    );
  }
}

class _CatalogPreviewGroup extends StatelessWidget {
  const _CatalogPreviewGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyles.large.copyWith(color: colors.textBase)),
        const SizedBox(height: Spacing.md),
        child,
      ],
    );
  }
}

class _CatalogPreviewList extends StatelessWidget {
  const _CatalogPreviewList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) const SizedBox(height: Spacing.xl),
        ],
      ],
    );
  }
}

class _SettingsMainContent extends StatelessWidget {
  const _SettingsMainContent();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          child: Text(
            'aman@example.com',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.body.copyWith(color: colors.textLight),
          ),
        ),
        const SizedBox(height: Spacing.md),
        const _SettingsNavigationItem(
          title: 'Account',
          icon: HugeIcons.strokeRoundedUser,
          page: _SettingsAccountPage(),
        ),
        const SizedBox(height: Spacing.md),
        const _SettingsNavigationItem(
          title: 'Security',
          icon: HugeIcons.strokeRoundedSecurityCheck,
          page: _SettingsSecurityPage(),
        ),
        const SizedBox(height: Spacing.md),
        const _SettingsNavigationItem(
          title: 'Appearance',
          icon: HugeIcons.strokeRoundedPaintBoard,
          page: _SettingsAppearancePage(),
        ),
        const SizedBox(height: Spacing.md),
        const _SettingsNavigationItem(
          title: 'General',
          icon: HugeIcons.strokeRoundedSettings01,
          page: _SettingsGeneralPage(),
        ),
        const SizedBox(height: Spacing.md),
        const _SettingsNavigationItem(
          title: 'Help and support',
          icon: HugeIcons.strokeRoundedHelpCircle,
          page: _SettingsSupportPage(),
        ),
        const SizedBox(height: Spacing.md),
        const _SettingsNavigationItem(
          title: 'About',
          icon: HugeIcons.strokeRoundedInformationCircle,
          page: _SettingsAboutPage(),
        ),
        const SizedBox(height: Spacing.xl),
        MenuComponent(
          title: 'Logout',
          leading: _CatalogHugeIcon(
            HugeIcons.strokeRoundedLogout05,
            color: colors.warning,
          ),
          trailing: _SettingsTrailingIcon(color: colors.textLight),
        ),
        const SizedBox(height: Spacing.xl),
        Center(
          child: Text(
            'Version 1.0.0',
            style: TextStyles.mini.copyWith(color: colors.textLight),
          ),
        ),
      ],
    );
  }
}

class _SettingsNavigationItem extends StatelessWidget {
  const _SettingsNavigationItem({
    required this.title,
    required this.icon,
    required this.page,
  });

  final String title;
  final HugeIconData icon;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return MenuComponent(
      title: title,
      leading: _CatalogHugeIcon(icon),
      trailing: const _SettingsTrailingIcon(),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => page));
      },
    );
  }
}

class _SettingsTrailingIcon extends StatelessWidget {
  const _SettingsTrailingIcon({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _CatalogHugeIcon(
      HugeIcons.strokeRoundedArrowRight02,
      color: color ?? context.componentColors.textLight,
      size: 18,
    );
  }
}

class _SettingsExampleShell extends StatelessWidget {
  const _SettingsExampleShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          HeaderAppBarComponent(
            title: title,
            subtitle: 'Settings',
            onBack: () => Navigator.of(context).pop(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xs,
              Spacing.lg,
              Spacing.lg,
            ),
            sliver: SliverList.builder(
              itemCount: children.length * 2 - 1,
              itemBuilder: (context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: Spacing.md);
                }
                return children[index ~/ 2];
              },
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundBase,
    );
  }
}

class _SettingsAccountPage extends StatelessWidget {
  const _SettingsAccountPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return _SettingsExampleShell(
      title: 'Account',
      children: [
        const MenuComponent(
          title: 'Change email',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedMail01),
          trailing: _SettingsTrailingIcon(),
        ),
        const MenuComponent(
          title: 'Recovery key',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedKey01),
          trailing: _SettingsTrailingIcon(),
        ),
        const MenuComponent(
          title: 'Change password',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedSquareLock02),
          trailing: _SettingsTrailingIcon(),
        ),
        MenuComponent(
          title: 'Delete account',
          subtitle: 'Demo destructive row',
          leading: _CatalogHugeIcon(
            HugeIcons.strokeRoundedDelete02,
            color: colors.warning,
          ),
          trailing: _SettingsTrailingIcon(color: colors.textLight),
        ),
      ],
    );
  }
}

class _SettingsSecurityPage extends StatefulWidget {
  const _SettingsSecurityPage();

  @override
  State<_SettingsSecurityPage> createState() => _SettingsSecurityPageState();
}

class _SettingsSecurityPageState extends State<_SettingsSecurityPage> {
  bool _emailVerification = true;

  @override
  Widget build(BuildContext context) {
    return _SettingsExampleShell(
      title: 'Security',
      children: [
        MenuComponent(
          title: 'Email verification',
          leading: const _CatalogHugeIcon(HugeIcons.strokeRoundedMailLock02),
          trailing: ToggleSwitchComponent(
            selected: _emailVerification,
            onChanged: (value) {
              setState(() => _emailVerification = value);
            },
          ),
        ),
        const MenuComponent(
          title: 'Passkey',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedFingerPrint),
          trailing: _SettingsTrailingIcon(),
        ),
        const MenuComponent(
          title: 'App lock',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedLockKey),
          trailing: _SettingsTrailingIcon(),
        ),
        const MenuComponent(
          title: 'Active sessions',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedLaptop),
          trailing: _SettingsTrailingIcon(),
        ),
      ],
    );
  }
}

class _SettingsAppearancePage extends StatefulWidget {
  const _SettingsAppearancePage();

  @override
  State<_SettingsAppearancePage> createState() =>
      _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<_SettingsAppearancePage> {
  String _theme = 'System theme';

  @override
  Widget build(BuildContext context) {
    return _SettingsExampleShell(
      title: 'Appearance',
      children: [
        _SettingsThemeOption(
          title: 'System theme',
          icon: HugeIcons.strokeRoundedComputer,
          selected: _theme == 'System theme',
          onTap: () => _selectTheme('System theme'),
        ),
        _SettingsThemeOption(
          title: 'Light theme',
          icon: HugeIcons.strokeRoundedSun01,
          selected: _theme == 'Light theme',
          onTap: () => _selectTheme('Light theme'),
        ),
        _SettingsThemeOption(
          title: 'Dark theme',
          icon: HugeIcons.strokeRoundedMoon02,
          selected: _theme == 'Dark theme',
          onTap: () => _selectTheme('Dark theme'),
        ),
      ],
    );
  }

  void _selectTheme(String theme) {
    setState(() => _theme = theme);
  }
}

class _SettingsThemeOption extends StatelessWidget {
  const _SettingsThemeOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final HugeIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return MenuComponent(
      title: title,
      leading: _CatalogHugeIcon(icon),
      selected: selected,
      trailing: selected
          ? _CatalogHugeIcon(
              HugeIcons.strokeRoundedTick02,
              color: colors.primary,
              size: 18,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsGeneralPage extends StatefulWidget {
  const _SettingsGeneralPage();

  @override
  State<_SettingsGeneralPage> createState() => _SettingsGeneralPageState();
}

class _SettingsGeneralPageState extends State<_SettingsGeneralPage> {
  bool _largeIcons = true;
  bool _compactMode = false;
  bool _hideCodes = true;

  @override
  Widget build(BuildContext context) {
    return _SettingsExampleShell(
      title: 'General',
      children: [
        const MenuComponent(
          title: 'Language',
          subtitle: 'English',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedLanguageSquare),
          trailing: _SettingsTrailingIcon(),
        ),
        _SettingsToggleItem(
          title: 'Show large icons',
          icon: HugeIcons.strokeRoundedImage02,
          selected: _largeIcons,
          onChanged: (value) => setState(() => _largeIcons = value),
        ),
        _SettingsToggleItem(
          title: 'Compact mode',
          icon: HugeIcons.strokeRoundedLayoutTable01,
          selected: _compactMode,
          onChanged: (value) => setState(() => _compactMode = value),
        ),
        _SettingsToggleItem(
          title: 'Hide codes',
          icon: HugeIcons.strokeRoundedViewOff,
          selected: _hideCodes,
          onChanged: (value) => setState(() => _hideCodes = value),
        ),
      ],
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  const _SettingsToggleItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final HugeIconData icon;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuComponent(
      title: title,
      leading: _CatalogHugeIcon(icon),
      trailing: ToggleSwitchComponent(selected: selected, onChanged: onChanged),
    );
  }
}

class _SettingsSupportPage extends StatelessWidget {
  const _SettingsSupportPage();

  @override
  Widget build(BuildContext context) {
    return const _SettingsExampleShell(
      title: 'Help and support',
      children: [
        MenuComponent(
          title: 'Contact support',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedCustomerSupport),
          trailing: _SettingsTrailingIcon(),
        ),
        MenuComponent(
          title: 'Help',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedHelpCircle),
          trailing: _SettingsTrailingIcon(),
        ),
        MenuComponent(
          title: 'Suggest features',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedBulb),
          trailing: _SettingsTrailingIcon(),
        ),
        MenuComponent(
          title: 'Report a bug',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedBug02),
          trailing: _SettingsTrailingIcon(),
        ),
      ],
    );
  }
}

class _SettingsAboutPage extends StatelessWidget {
  const _SettingsAboutPage();

  @override
  Widget build(BuildContext context) {
    return const _SettingsExampleShell(
      title: 'About',
      children: [
        MenuComponent(
          title: 'Open source',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedGithub),
          trailing: _SettingsTrailingIcon(),
        ),
        MenuComponent(
          title: 'Privacy',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedShield01),
          trailing: _SettingsTrailingIcon(),
        ),
        MenuComponent(
          title: 'Terms of service',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedNote),
          trailing: _SettingsTrailingIcon(),
        ),
        MenuComponent(
          title: 'Check for updates',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedRefresh),
          trailing: _SettingsTrailingIcon(),
        ),
      ],
    );
  }
}

class _ColorPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _CatalogPreviewList(
      children: [
        _CatalogPreviewGroup(
          title: 'Light palette',
          child: _ColorColumn(colors: ColorTokens.light),
        ),
        _CatalogPreviewGroup(
          title: 'Dark palette',
          child: _ColorColumn(colors: ColorTokens.dark),
        ),
      ],
    );
  }
}

class _ColorColumn extends StatelessWidget {
  const _ColorColumn({required this.colors});

  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        _Swatch(color: colors.primary),
        _Swatch(color: colors.warning),
        _Swatch(color: colors.caution),
        _Swatch(color: colors.blue),
        _Swatch(color: colors.textBase),
        _Swatch(color: colors.backgroundBase),
        _Swatch(color: colors.fillLight),
        _Swatch(color: colors.strokeDark),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: context.componentColors.strokeFaint),
        borderRadius: BorderRadius.circular(Radii.xs),
      ),
    );
  }
}

class _TextStylesPreview extends StatelessWidget {
  const _TextStylesPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return _CatalogPreviewGroup(
      title: 'Type scale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeSample(
            text: 'Secure backup is ready',
            detail: 'H1 / 20 / 28 / Bold',
            style: TextStyles.h1,
            color: colors.textBase,
          ),
          const SizedBox(height: Spacing.xl),
          _TypeSample(
            text: 'Secure backup is ready',
            detail: 'H2 / 18 / 24 / Semi Bold',
            style: TextStyles.h2,
            color: colors.textBase,
          ),
          const SizedBox(height: Spacing.xl),
          _TypeSample(
            text: 'Secure backup is ready',
            detail: 'Large / 16 / 20 / Semi Bold',
            style: TextStyles.large,
            color: colors.textBase,
          ),
          const SizedBox(height: Spacing.xl),
          _TypeSample(
            text: 'Secure backup is ready',
            detail: 'Body / 14 / 20 / Medium',
            style: TextStyles.body,
            color: colors.textBase,
          ),
          const SizedBox(height: Spacing.xl),
          _TypeSample(
            text: 'Secure backup is ready',
            detail: 'Mini / 12 / 16 / Medium',
            style: TextStyles.mini,
            color: colors.textLight,
          ),
          const SizedBox(height: Spacing.xl),
          _TypeSample(
            text: 'Secure backup is ready',
            detail: 'Tiny / 10 / 12 / Medium',
            style: TextStyles.tiny,
            color: colors.textLight,
          ),
        ],
      ),
    );
  }
}

class _TypeSample extends StatelessWidget {
  const _TypeSample({
    required this.text,
    required this.detail,
    required this.style,
    required this.color,
  });

  final String text;
  final String detail;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: style.copyWith(color: color)),
        const SizedBox(height: Spacing.xs),
        Text(detail, style: TextStyles.mini.copyWith(color: colors.textLight)),
      ],
    );
  }
}

class _ButtonMatrix extends StatelessWidget {
  const _ButtonMatrix();

  @override
  Widget build(BuildContext context) {
    return const _CatalogPreviewList(
      children: [
        ButtonStateCyclePreview(),
        _ButtonExecutionPreview(),
        _ButtonStateGroup(title: 'Default'),
        _ButtonStateGroup(title: 'Disabled', disabled: true),
        _CatalogPreviewGroup(
          title: 'Icon button async actions',
          child: _IconButtonMatrix(),
        ),
      ],
    );
  }
}

class ButtonStateCyclePreview extends StatefulWidget {
  const ButtonStateCyclePreview({super.key});

  @override
  State<ButtonStateCyclePreview> createState() =>
      _ButtonStateCyclePreviewState();
}

class _ButtonStateCyclePreviewState extends State<ButtonStateCyclePreview> {
  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewGroup(
      title: 'State transition',
      child: ButtonComponent(
        key: const ValueKey('button-cycle'),
        label: 'Continue',
        variant: ButtonComponentVariant.primary,
        size: ButtonComponentSize.large,
        onTap: _runPreviewAction,
      ),
    );
  }

  Future<void> _runPreviewAction() {
    return Future<void>.delayed(const Duration(milliseconds: 900));
  }
}

class _ButtonExecutionPreview extends StatelessWidget {
  const _ButtonExecutionPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return _CatalogPreviewGroup(
      title: 'Async actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Success',
            style: TextStyles.large.copyWith(color: colors.textBase),
          ),
          const SizedBox(height: Spacing.xs),
          ButtonComponent(
            label: 'Save changes',
            variant: ButtonComponentVariant.primary,
            size: ButtonComponentSize.large,
            onTap: () =>
                Future<void>.delayed(const Duration(milliseconds: 900)),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Error',
            style: TextStyles.large.copyWith(color: colors.textBase),
          ),
          const SizedBox(height: Spacing.xs),
          ButtonComponent(
            label: 'Sync backup',
            variant: ButtonComponentVariant.critical,
            size: ButtonComponentSize.large,
            onTap: () => _runPreviewError(context),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Fast confirmation',
            style: TextStyles.large.copyWith(color: colors.textBase),
          ),
          const SizedBox(height: Spacing.xs),
          ButtonComponent(
            label: 'Copy link',
            variant: ButtonComponentVariant.secondary,
            size: ButtonComponentSize.large,
            shouldShowSuccessConfirmation: true,
            onTap: () =>
                Future<void>.delayed(const Duration(milliseconds: 120)),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Surface off',
            style: TextStyles.large.copyWith(color: colors.textBase),
          ),
          const SizedBox(height: Spacing.xs),
          ButtonComponent(
            label: 'Refresh',
            variant: ButtonComponentVariant.neutral,
            size: ButtonComponentSize.large,
            shouldSurfaceExecutionStates: false,
            onTap: () =>
                Future<void>.delayed(const Duration(milliseconds: 900)),
          ),
        ],
      ),
    );
  }

  Future<void> _runPreviewError(BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }
    throw StateError('Preview action failed');
  }
}

const _buttonPreviewSpecs = <_ButtonPreviewSpec>[
  _ButtonPreviewSpec(
    type: 'Primary',
    label: 'Continue',
    variant: ButtonComponentVariant.primary,
  ),
  _ButtonPreviewSpec(
    type: 'Secondary',
    label: 'Cancel',
    variant: ButtonComponentVariant.secondary,
  ),
  _ButtonPreviewSpec(
    type: 'Neutral',
    label: 'Use recovery key',
    variant: ButtonComponentVariant.neutral,
  ),
  _ButtonPreviewSpec(
    type: 'Critical',
    label: 'Delete account',
    variant: ButtonComponentVariant.critical,
  ),
  _ButtonPreviewSpec(
    type: 'Tertiary critical',
    label: 'Remove trusted contact',
    variant: ButtonComponentVariant.tertiaryCritical,
  ),
  _ButtonPreviewSpec(
    type: 'Link button',
    label: 'Forgot password?',
    variant: ButtonComponentVariant.link,
  ),
];

class _ButtonPreviewSpec {
  const _ButtonPreviewSpec({
    required this.type,
    required this.label,
    required this.variant,
  });

  final String type;
  final String label;
  final ButtonComponentVariant variant;
}

class _ButtonStateGroup extends StatelessWidget {
  const _ButtonStateGroup({required this.title, this.disabled = false});

  final String title;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewGroup(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < _buttonPreviewSpecs.length; index++) ...[
            _ButtonPreviewRow(
              spec: _buttonPreviewSpecs[index],
              disabled: disabled,
            ),
            if (index != _buttonPreviewSpecs.length - 1)
              const SizedBox(height: Spacing.md),
          ],
        ],
      ),
    );
  }
}

class _ButtonPreviewRow extends StatelessWidget {
  const _ButtonPreviewRow({required this.spec, required this.disabled});

  final _ButtonPreviewSpec spec;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.type,
          style: TextStyles.large.copyWith(color: colors.textBase),
        ),
        const SizedBox(height: Spacing.xs),
        ButtonComponent(
          label: spec.label,
          variant: spec.variant,
          size: ButtonComponentSize.large,
          onTap: disabled ? null : () {},
        ),
      ],
    );
  }
}

class _IconButtonMatrix extends StatelessWidget {
  const _IconButtonMatrix();

  @override
  Widget build(BuildContext context) {
    const columns = ['Default', 'Disabled', 'Loading', 'Success', 'Error'];
    const rows = [
      _IconButtonPreviewRow(
        label: 'Primary',
        variant: IconButtonComponentVariant.primary,
      ),
      _IconButtonPreviewRow(
        label: 'Critical',
        variant: IconButtonComponentVariant.critical,
      ),
      _IconButtonPreviewRow(
        label: 'Unfilled',
        variant: IconButtonComponentVariant.unfilled,
      ),
      _IconButtonPreviewRow(
        label: 'Secondary',
        variant: IconButtonComponentVariant.secondary,
      ),
      _IconButtonPreviewRow(
        label: 'Green',
        variant: IconButtonComponentVariant.green,
      ),
      _IconButtonPreviewRow(
        label: 'Circular',
        variant: IconButtonComponentVariant.circular,
      ),
    ];
    final colors = context.componentColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 84),
              for (final column in columns)
                SizedBox(
                  width: 76,
                  child: Text(
                    column,
                    textAlign: TextAlign.center,
                    style: TextStyles.large.copyWith(color: colors.textBase),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          for (final row in rows) ...[
            row,
            if (row != rows.last) const SizedBox(height: Spacing.md),
          ],
        ],
      ),
    );
  }
}

class _IconButtonPreviewRow extends StatelessWidget {
  const _IconButtonPreviewRow({required this.label, required this.variant});

  final String label;
  final IconButtonComponentVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyles.large.copyWith(color: colors.textBase),
          ),
        ),
        for (final state in const [
          'Default',
          'Disabled',
          'Loading',
          'Success',
          'Error',
        ])
          SizedBox(
            width: 76,
            child: Center(
              child: _IconButtonStatePreview(variant: variant, state: state),
            ),
          ),
      ],
    );
  }
}

class _IconButtonStatePreview extends StatelessWidget {
  const _IconButtonStatePreview({required this.variant, required this.state});

  final IconButtonComponentVariant variant;
  final String state;

  @override
  Widget build(BuildContext context) {
    return IconButtonComponent(
      tooltip: state,
      variant: variant,
      shouldShowSuccessConfirmation: state == 'Success',
      onTap: state == 'Disabled'
          ? null
          : state == 'Loading'
          ? () => Future<void>.delayed(const Duration(milliseconds: 900))
          : state == 'Success'
          ? () => Future<void>.delayed(const Duration(milliseconds: 120))
          : state == 'Error'
          ? () => _runPreviewError(context)
          : () {},
      icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01, size: 18),
    );
  }

  Future<void> _runPreviewError(BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }
    throw StateError('Preview action failed');
  }
}

class _FilterChipPreview extends StatefulWidget {
  const _FilterChipPreview();

  @override
  State<_FilterChipPreview> createState() => _FilterChipPreviewState();
}

class _FilterChipPreviewState extends State<_FilterChipPreview> {
  final Set<String> _selected = {'Faces', 'Favorites'};

  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewList(
      children: [
        _CatalogPreviewGroup(
          title: 'Editable',
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              _EditableChip(
                label: 'Faces',
                selected: _selected.contains('Faces'),
                onChanged: _toggle('Faces'),
                avatar: const _FaceAvatar(seed: 0, initials: 'AR'),
              ),
              _EditableChip(
                label: 'Favorites',
                selected: _selected.contains('Favorites'),
                onChanged: _toggle('Favorites'),
                leading: const _CatalogHugeIcon(HugeIcons.strokeRoundedStar),
              ),
              _EditableChip(
                label: 'Videos',
                selected: _selected.contains('Videos'),
                onChanged: _toggle('Videos'),
                trailing: const _CatalogHugeIcon(
                  HugeIcons.strokeRoundedVideo01,
                ),
              ),
            ],
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'States',
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              FilterChipComponent(
                label: 'Selected',
                state: FilterChipComponentState.selected,
              ),
              FilterChipComponent(
                label: 'Unselected',
                state: FilterChipComponentState.unselected,
              ),
              FilterChipComponent(
                label: 'Disabled',
                state: FilterChipComponentState.disabled,
              ),
            ],
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Icons',
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              FilterChipComponent(
                label: 'Albums',
                leading: _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                state: FilterChipComponentState.selected,
              ),
              FilterChipComponent(
                label: 'Shared',
                leading: _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                state: FilterChipComponentState.unselected,
              ),
              FilterChipComponent(
                label: 'Archived',
                leading: _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                state: FilterChipComponentState.disabled,
              ),
              FilterChipComponent(
                label: 'Recent',
                trailing: _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                state: FilterChipComponentState.selected,
              ),
              FilterChipComponent(
                label: 'Places',
                trailing: _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                state: FilterChipComponentState.unselected,
              ),
              FilterChipComponent(
                label: 'Hidden',
                trailing: _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                state: FilterChipComponentState.disabled,
              ),
            ],
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Faces',
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              FilterChipComponent(
                label: 'Aarav',
                avatar: _FaceAvatar(seed: 0, initials: 'AR'),
                state: FilterChipComponentState.selected,
              ),
              FilterChipComponent(
                label: 'Mira',
                avatar: _FaceAvatar(seed: 1, initials: 'MR'),
                state: FilterChipComponentState.unselected,
              ),
              FilterChipComponent(
                label: 'Nila',
                avatar: _FaceAvatar(seed: 2, initials: 'NS'),
                state: FilterChipComponentState.disabled,
              ),
              FilterChipComponent(
                avatar: _FaceAvatar(seed: 3, initials: 'KV'),
                state: FilterChipComponentState.selected,
              ),
              FilterChipComponent(
                avatar: _FaceAvatar(seed: 1, initials: 'MR'),
                state: FilterChipComponentState.unselected,
              ),
              FilterChipComponent(
                avatar: _FaceAvatar(seed: 2, initials: 'NS'),
                state: FilterChipComponentState.disabled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  ValueChanged<bool> _toggle(String label) {
    return (selected) {
      setState(() {
        if (selected) {
          _selected.add(label);
        } else {
          _selected.remove(label);
        }
      });
    };
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview();

  static const _sizes = [
    (label: 'Default', size: AvatarComponentSize.normal),
    (label: 'Small', size: AvatarComponentSize.small),
    (label: 'Large', size: AvatarComponentSize.large),
    (label: 'Contact (huge)', size: AvatarComponentSize.contactHuge),
  ];
  static const _colors = [
    (label: 'Yellow', color: AvatarComponentColor.yellow, initials: 'E'),
    (label: 'Green', color: AvatarComponentColor.green, initials: 'K'),
    (label: 'Orange', color: AvatarComponentColor.orange, initials: 'T'),
    (label: 'Pink', color: AvatarComponentColor.pink, initials: 'U'),
    (label: 'Purple', color: AvatarComponentColor.purple, initials: 'R'),
    (label: 'Blue', color: AvatarComponentColor.blue, initials: 'S'),
  ];

  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewList(
      children: [
        _CatalogPreviewGroup(
          title: 'Variants and sizes',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AvatarTableHeader(sizes: _sizes),
                const SizedBox(height: Spacing.lg),
                for (final item in _colors) ...[
                  _AvatarTableRow(
                    label: item.label,
                    children: [
                      for (final size in _sizes)
                        AvatarComponent(
                          initials: item.initials,
                          color: item.color,
                          size: size.size,
                        ),
                    ],
                  ),
                  if (item != _colors.last) const SizedBox(height: Spacing.md),
                ],
                const SizedBox(height: Spacing.md),
                const _AvatarTableRow(
                  label: 'Add icon',
                  children: [
                    SizedBox.shrink(),
                    SizedBox.shrink(),
                    SizedBox.shrink(),
                    AvatarComponent.icon(
                      icon: _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Seed palette',
          child: Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: [
              for (var index = 0; index < avatarLight.length; index++)
                AvatarComponent.seeded(
                  initials: String.fromCharCode(65 + index % 26),
                  seed: index,
                  size: AvatarComponentSize.large,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarTableHeader extends StatelessWidget {
  const _AvatarTableHeader({required this.sizes});

  final List<({String label, AvatarComponentSize size})> sizes;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Row(
      children: [
        const SizedBox(width: 92),
        for (final size in sizes)
          SizedBox(
            width: 96,
            child: Text(
              size.label,
              textAlign: TextAlign.center,
              style: TextStyles.large.copyWith(color: colors.textBase),
            ),
          ),
      ],
    );
  }
}

class _AvatarTableRow extends StatelessWidget {
  const _AvatarTableRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyles.large.copyWith(color: colors.textBase),
          ),
        ),
        for (final child in children)
          SizedBox(width: 96, height: 64, child: Center(child: child)),
      ],
    );
  }
}

class _EditableChip extends StatelessWidget {
  const _EditableChip({
    required this.label,
    required this.selected,
    required this.onChanged,
    this.leading,
    this.trailing,
    this.avatar,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final Widget? leading;
  final Widget? trailing;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    return FilterChipComponent(
      label: label,
      leading: leading,
      trailing: trailing,
      avatar: avatar,
      state: selected
          ? FilterChipComponentState.selected
          : FilterChipComponentState.unselected,
      onChanged: onChanged,
    );
  }
}

class _FaceAvatar extends StatelessWidget {
  const _FaceAvatar({required this.seed, required this.initials});

  final int seed;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return AvatarComponent.seeded(
      initials: initials,
      seed: seed,
      size: AvatarComponentSize.large,
    );
  }
}

class _TextInputPreview extends StatefulWidget {
  const _TextInputPreview();

  @override
  State<_TextInputPreview> createState() => _TextInputPreviewState();
}

class _TextInputPreviewState extends State<_TextInputPreview> {
  late final TextEditingController _focusedController;
  late final TextEditingController _errorController;
  late final TextEditingController _successController;
  late final TextEditingController _disabledController;
  late final TextEditingController _clearableController;
  late final TextEditingController _passwordController;
  late final TextEditingController _submitController;
  late final ValueNotifier<int> _submitNotifier;

  @override
  void initState() {
    super.initState();
    _focusedController = TextEditingController(text: 'mira@example.com');
    _errorController = TextEditingController(text: 'short');
    _successController = TextEditingController(text: '482901');
    _disabledController = TextEditingController(text: 'mira.roy@example.com');
    _clearableController = TextEditingController(text: 'family trip');
    _passwordController = TextEditingController(text: 'correct horse');
    _submitController = TextEditingController(text: 'wrong password');
    _submitNotifier = ValueNotifier<int>(0);
  }

  @override
  void dispose() {
    _focusedController.dispose();
    _errorController.dispose();
    _successController.dispose();
    _disabledController.dispose();
    _clearableController.dispose();
    _passwordController.dispose();
    _submitController.dispose();
    _submitNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewList(
      children: [
        const _CatalogPreviewGroup(
          title: 'Normal',
          child: TextInputComponent(
            label: 'Email address',
            hintText: 'Hint text',
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Focused',
          child: TextInputComponent(
            controller: _focusedController,
            label: 'Email address',
            prefix: const _TextInputPreviewIcon(HugeIcons.strokeRoundedMail01),
            suffix: const _TextInputPreviewIcon(HugeIcons.strokeRoundedView),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Error',
          child: TextInputComponent(
            controller: _errorController,
            label: 'Password',
            message: 'Use at least 8 characters.',
            messageType: TextInputComponentMessageType.error,
            isPasswordInput: true,
            prefix: const _TextInputPreviewIcon(
              HugeIcons.strokeRoundedLockPassword,
            ),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Submit error',
          child: Column(
            children: [
              TextInputComponent(
                controller: _submitController,
                submitNotifier: _submitNotifier,
                label: 'Password',
                hintText: 'Enter password',
                isPasswordInput: true,
                popNavAfterSubmission: true,
                prefix: const _TextInputPreviewIcon(
                  HugeIcons.strokeRoundedLockPassword,
                ),
                onSubmit: (_) async {
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                  throw Exception('Incorrect password');
                },
              ),
              const SizedBox(height: Spacing.md),
              ButtonComponent(
                label: 'Submit',
                size: ButtonComponentSize.small,
                shouldSurfaceExecutionStates: false,
                onTap: () {
                  _submitNotifier.value++;
                },
              ),
            ],
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Success',
          child: TextInputComponent(
            controller: _successController,
            label: 'Recovery code',
            message: 'Recovery code verified.',
            messageType: TextInputComponentMessageType.success,
            suffix: const _TextInputPreviewIcon(
              HugeIcons.strokeRoundedCheckmarkCircle01,
            ),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Disabled',
          child: TextInputComponent(
            controller: _disabledController,
            label: 'Account email',
            isDisabled: true,
            prefix: const _TextInputPreviewIcon(HugeIcons.strokeRoundedMail01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'No label',
          child: TextInputComponent(hintText: 'Hint text'),
        ),
        const _CatalogPreviewGroup(
          title: 'Required',
          child: TextInputComponent(
            label: 'Email address',
            hintText: 'mira@example.com',
            isRequired: true,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Helper text',
          child: TextInputComponent(
            label: 'Recovery email',
            hintText: 'mira@example.com',
            message: 'Used for receipts and security alerts.',
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Prefix icon',
          child: TextInputComponent(
            label: 'Search',
            hintText: 'Search albums',
            prefix: _TextInputPreviewIcon(HugeIcons.strokeRoundedSearch01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Trailing icon',
          child: TextInputComponent(
            label: 'Password',
            hintText: 'Enter password',
            suffix: _TextInputPreviewIcon(HugeIcons.strokeRoundedView),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Prefix and trailing icons',
          child: TextInputComponent(
            label: 'Search',
            hintText: 'Search people',
            prefix: _TextInputPreviewIcon(HugeIcons.strokeRoundedSearch01),
            suffix: _TextInputPreviewIcon(HugeIcons.strokeRoundedCancel01),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Clearable search',
          child: TextInputComponent(
            controller: _clearableController,
            label: 'Search',
            hintText: 'Search files',
            prefix: const _TextInputPreviewIcon(
              HugeIcons.strokeRoundedSearch01,
            ),
            isClearable: true,
            autocorrect: false,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Password visibility',
          child: TextInputComponent(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter password',
            isPasswordInput: true,
            prefix: const _TextInputPreviewIcon(
              HugeIcons.strokeRoundedLockPassword,
            ),
            autofillHints: const [AutofillHints.password],
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Alert message',
          child: TextInputComponent(
            label: 'Recovery key',
            hintText: 'Enter recovery key',
            message: 'Save this key somewhere safe before continuing.',
            messageType: TextInputComponentMessageType.alert,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Max length',
          child: TextInputComponent(
            label: 'Referral code',
            hintText: 'SUMMER2026',
            maxLength: 12,
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: label + trailing + warning message',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            message: 'This is an error',
            messageType: TextInputComponentMessageType.error,
            maxLines: 4,
            suffix: _TextInputPreviewIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: label + trailing',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            suffix: _TextInputPreviewIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: label only',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: no label + trailing',
          child: TextInputComponent(
            hintText: 'Hint text',
            maxLines: 4,
            suffix: _TextInputPreviewIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: no label',
          child: TextInputComponent(hintText: 'Hint text', maxLines: 4),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: focused',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            suffix: _TextInputPreviewIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: error',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            message: 'This is an error',
            messageType: TextInputComponentMessageType.error,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: success',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            message: 'Saved',
            messageType: TextInputComponentMessageType.success,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: disabled',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            isDisabled: true,
            suffix: _TextInputPreviewIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
      ],
    );
  }
}

class _TextInputPreviewIcon extends StatelessWidget {
  const _TextInputPreviewIcon(this.icon);

  final HugeIconData icon;

  @override
  Widget build(BuildContext context) {
    return _CatalogHugeIcon(icon, color: context.componentColors.textLighter);
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return ColoredBox(
      color: colors.fillDark,
      child: Center(
        child: _CatalogHugeIcon(
          HugeIcons.strokeRoundedUser,
          color: colors.textLight,
          size: 20,
        ),
      ),
    );
  }
}

class _HeaderAppBarEntryPreview extends StatelessWidget {
  const _HeaderAppBarEntryPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Text(
      'Open this section from the catalog list to test the pinned animated '
      'header app bar with a long scrollable list.',
      style: TextStyles.body.copyWith(color: colors.textLight),
    );
  }
}

class HeaderAppBarDemoPage extends StatefulWidget {
  const HeaderAppBarDemoPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HeaderAppBarDemoPage> createState() => _HeaderAppBarDemoPageState();
}

class _HeaderAppBarDemoPageState extends State<HeaderAppBarDemoPage> {
  static const _itemCount = 48;

  late ThemeMode _themeMode = widget.themeMode;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.onThemeModeChanged(mode);
  }

  void _showAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: CustomScrollView(
        slivers: [
          HeaderAppBarComponent(
            title: 'Menu items',
            subtitle: 'Scroll to collapse into a single app bar row',
            onBack: () => Navigator.of(context).pop(),
            leading: const _HeaderAppBarDemoLeading(),
            actions: [
              IconButtonComponent(
                tooltip: 'Add item',
                variant: IconButtonComponentVariant.primary,
                icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
                onTap: () => _showAction('Add tapped'),
              ),
              _CatalogThemeCycleButton(
                themeMode: _themeMode,
                onChanged: _setThemeMode,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xs,
              Spacing.lg,
              Spacing.xxl,
            ),
            sliver: SliverList.builder(
              itemCount: _itemCount * 2 - 1,
              itemBuilder: (context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: Spacing.md);
                }
                return _HeaderAppBarDemoListItem(index: index ~/ 2);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAppBarDemoLeading extends StatelessWidget {
  const _HeaderAppBarDemoLeading();

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.primary),
      child: Center(
        child: _CatalogHugeIcon(
          HugeIcons.strokeRoundedMenuCircle,
          color: colors.specialWhite,
          size: 20,
        ),
      ),
    );
  }
}

class _HeaderAppBarDemoListItem extends StatelessWidget {
  const _HeaderAppBarDemoListItem({required this.index});

  final int index;

  static const _titles = [
    'Camera uploads',
    'Private albums',
    'Recovery key',
    'Shared links',
    'Device folders',
    'Storage plan',
    'Notifications',
    'Hidden items',
    'Trash cleanup',
    'Export data',
  ];

  static const _subtitles = [
    'Enabled on Wi-Fi',
    'Only visible to you',
    'Last checked today',
    'Manage public access',
    'Choose folders to sync',
    'Family plan active',
    'Activity and reminders',
    'Protected by device lock',
    'Auto-delete in 30 days',
    'Prepare local archive',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final hasSubtitle = index % 3 != 1;
    final hasImage = index % 4 == 0 || index % 4 == 3;
    final hasAction = index % 5 != 2;
    final title = _titles[index % _titles.length];
    final subtitle = _subtitles[index % _subtitles.length];

    return MenuComponent(
      title: '$title ${index + 1}',
      subtitle: hasSubtitle ? subtitle : null,
      leading: hasImage ? const _HeaderImage() : null,
      trailing: hasAction
          ? IconButtonComponent(
              tooltip: 'Add $title',
              variant: IconButtonComponentVariant.primary,
              icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
              onTap: () {},
            )
          : const _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight02),
      titleColor: index % 7 == 0 ? colors.primary : null,
    );
  }
}

class _SelectionPreview extends StatefulWidget {
  const _SelectionPreview();

  @override
  State<_SelectionPreview> createState() => _SelectionPreviewState();
}

class _SelectionPreviewState extends State<_SelectionPreview> {
  bool _checkbox = true;
  bool _radio = true;
  bool _switch = true;
  double _slider = 0.42;
  int _stepper = 3;

  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewList(
      children: [
        _CatalogPreviewGroup(
          title: 'Interactive controls',
          child: Wrap(
            spacing: Spacing.xl,
            runSpacing: Spacing.md,
            children: [
              LabeledControlComponent(
                control: CheckboxComponent(
                  selected: _checkbox,
                  onChanged: (value) => setState(() => _checkbox = value),
                ),
                label: 'Checkbox',
              ),
              LabeledControlComponent(
                control: RadioComponent(
                  selected: _radio,
                  onChanged: (value) => setState(() => _radio = value),
                ),
                label: 'Radio',
              ),
              LabeledControlComponent(
                control: ToggleSwitchComponent(
                  selected: _switch,
                  onChanged: (value) => setState(() => _switch = value),
                ),
                label: 'Switch',
              ),
            ],
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Disabled controls',
          child: Wrap(
            spacing: Spacing.xl,
            runSpacing: Spacing.md,
            children: [
              LabeledControlComponent(
                control: CheckboxComponent(selected: true, onChanged: null),
                label: 'Selected checkbox',
              ),
              LabeledControlComponent(
                control: CheckboxComponent(selected: false, onChanged: null),
                label: 'Empty checkbox',
              ),
              LabeledControlComponent(
                control: RadioComponent(selected: true, onChanged: null),
                label: 'Selected radio',
              ),
              LabeledControlComponent(
                control: ToggleSwitchComponent(
                  selected: false,
                  onChanged: null,
                ),
                label: 'Off switch',
              ),
            ],
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Slider',
          child: SliderComponent(
            value: _slider,
            onChanged: (value) => setState(() => _slider = value),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Disabled slider',
          child: SliderComponent(value: 0.7, onChanged: null),
        ),
        _CatalogPreviewGroup(
          title: 'Stepper',
          child: StepperComponent(
            value: _stepper,
            onChanged: (value) => setState(() => _stepper = value),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Stepper limits',
          child: Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.md,
            children: [
              StepperComponent(value: 0, min: 0, max: 5, onChanged: null),
              StepperComponent(value: 5, min: 0, max: 5, onChanged: null),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MenuItemTrailingKind { icon, toggle, none }

class _MenuItemPreview extends StatefulWidget {
  const _MenuItemPreview();

  @override
  State<_MenuItemPreview> createState() => _MenuItemPreviewState();
}

class _MenuItemPreviewState extends State<_MenuItemPreview> {
  bool _toggleSelected = true;

  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewList(
      children: [
        _CatalogPreviewGroup(
          title: 'Default',
          child: _MenuItemMatrix(
            toggleSelected: _toggleSelected,
            onToggleChanged: _setToggleSelected,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Selected',
          child: _MenuItemMatrix(
            selected: true,
            toggleSelected: _toggleSelected,
            onToggleChanged: _setToggleSelected,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Interaction states',
          child: _MenuItemInteractionStatesPreview(),
        ),
        _CatalogPreviewGroup(
          title: 'Display only',
          child: Builder(
            builder: (context) {
              final colors = context.componentColors;
              return MenuComponent(
                title: 'Storage plan',
                subtitle: 'Gestures disabled for read-only rows',
                leading: const _CatalogHugeIcon(
                  HugeIcons.strokeRoundedDatabase,
                ),
                trailing: Text(
                  '2 TB',
                  style: TextStyles.body.copyWith(color: colors.textLight),
                ),
                isDisabled: true,
              );
            },
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Destructive',
          child: Builder(
            builder: (context) {
              final colors = context.componentColors;
              return MenuComponent(
                title: 'Delete account',
                subtitle: 'Warning color title and icon',
                leading: _CatalogHugeIcon(
                  HugeIcons.strokeRoundedDelete02,
                  color: colors.warning,
                  size: 18,
                ),
                trailing: const _CatalogTrailingIcon(
                  HugeIcons.strokeRoundedArrowRight01,
                ),
                titleColor: colors.warning,
                onTap: () {},
              );
            },
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Long text',
          child: MenuComponent(
            title:
                'Camera uploads from this device and shared albums waiting for review',
            subtitle:
                'This subtitle remains one line and truncates like Photos and Locker menu rows',
            leading: _CatalogHugeIcon(HugeIcons.strokeRoundedImageUpload),
            trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
            onTap: _completeAfterDelay,
          ),
        ),
      ],
    );
  }

  void _setToggleSelected(bool value) {
    setState(() => _toggleSelected = value);
  }
}

Future<void> _completeAfterDelay() {
  return Future<void>.delayed(const Duration(milliseconds: 650));
}

Future<void> _completeSlowly() {
  return Future<void>.delayed(const Duration(milliseconds: 900));
}

Future<void> _completeQuickly() {
  return Future<void>.delayed(const Duration(milliseconds: 120));
}

Future<void> _failAfterDelay(BuildContext context) async {
  await Future<void>.delayed(const Duration(milliseconds: 900));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
  }
  throw StateError('Preview action failed');
}

class _MenuItemInteractionStatesPreview extends StatelessWidget {
  const _MenuItemInteractionStatesPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuComponent(
          title: 'Open storage plan',
          subtitle: 'Tap only, no execution UI',
          leading: const _CatalogHugeIcon(HugeIcons.strokeRoundedDatabase),
          trailing: const _CatalogTrailingIcon(
            HugeIcons.strokeRoundedArrowRight01,
          ),
          shouldSurfaceExecutionStates: false,
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Opened')));
          },
        ),
        const SizedBox(height: Spacing.md),
        const MenuComponent(
          title: 'Updating backup',
          subtitle: 'Execution loading, then success',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedCloudUpload),
          trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
          onTap: _completeSlowly,
        ),
        const SizedBox(height: Spacing.md),
        const MenuComponent(
          title: 'Copied recovery key',
          subtitle: 'Fast success confirmation',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedCopy01),
          trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
          shouldShowSuccessConfirmation: true,
          onTap: _completeQuickly,
        ),
        const SizedBox(height: Spacing.md),
        MenuComponent(
          title: 'Sync backup',
          subtitle: 'Error resets to idle',
          leading: const _CatalogHugeIcon(HugeIcons.strokeRoundedRefresh),
          trailing: const _CatalogTrailingIcon(
            HugeIcons.strokeRoundedArrowRight01,
          ),
          titleColor: context.componentColors.warning,
          iconColor: context.componentColors.warning,
          onTap: () => _failAfterDelay(context),
        ),
        const SizedBox(height: Spacing.md),
        const MenuComponent(
          title: 'Opening sessions',
          subtitle: 'Loading only, no success tick',
          leading: _CatalogHugeIcon(HugeIcons.strokeRoundedUserGroup),
          trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
          showOnlyLoadingState: true,
          onTap: _completeSlowly,
        ),
      ],
    );
  }
}

class _MenuItemMatrix extends StatelessWidget {
  const _MenuItemMatrix({
    required this.toggleSelected,
    required this.onToggleChanged,
    this.selected = false,
  });

  final bool toggleSelected;
  final ValueChanged<bool> onToggleChanged;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final trailingKinds = selected
        ? const [_MenuItemTrailingKind.icon, _MenuItemTrailingKind.none]
        : _MenuItemTrailingKind.values;
    return Wrap(
      spacing: Spacing.lg,
      runSpacing: Spacing.md,
      children: [
        for (final hasSubtitle in const [true, false])
          for (final hasLeading in const [true, false])
            for (final trailingKind in trailingKinds)
              _MenuItemExample(
                selected: selected,
                hasLeading: hasLeading,
                hasSubtitle: hasSubtitle,
                trailingKind: trailingKind,
                toggleSelected: toggleSelected,
                onToggleChanged: onToggleChanged,
              ),
      ],
    );
  }
}

class _MenuItemExample extends StatelessWidget {
  const _MenuItemExample({
    required this.selected,
    required this.hasLeading,
    required this.hasSubtitle,
    required this.trailingKind,
    required this.toggleSelected,
    required this.onToggleChanged,
  });

  final bool selected;
  final bool hasLeading;
  final bool hasSubtitle;
  final _MenuItemTrailingKind trailingKind;
  final bool toggleSelected;
  final ValueChanged<bool> onToggleChanged;

  @override
  Widget build(BuildContext context) {
    return MenuComponent(
      title: hasLeading ? 'Camera uploads' : 'Storage plan',
      subtitle: hasSubtitle ? '834 items' : null,
      leading: hasLeading
          ? const _CatalogHugeIcon(HugeIcons.strokeRoundedUser, size: 18)
          : null,
      trailing: _trailing(context),
      selected: selected,
      onTap: () {},
    );
  }

  Widget? _trailing(BuildContext context) {
    final colors = context.componentColors;
    if (selected) {
      return _CatalogHugeIcon(
        HugeIcons.strokeRoundedCheckmarkCircle02,
        color: colors.primary,
        size: 18,
      );
    }
    return switch (trailingKind) {
      _MenuItemTrailingKind.icon => const _CatalogTrailingIcon(
        HugeIcons.strokeRoundedMoreVertical,
      ),
      _MenuItemTrailingKind.toggle => ToggleSwitchComponent(
        selected: toggleSelected,
        onChanged: onToggleChanged,
      ),
      _MenuItemTrailingKind.none => null,
    };
  }
}
