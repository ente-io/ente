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
  double _textScale = 1;
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

  void _setTextScale(double scale) {
    setState(() => _textScale = scale);
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is! PointerUpEvent) {
      return;
    }

    final now = event.timeStamp;
    final lastPointerUpAt = _lastPointerUpAt;
    final lastPointerUpPosition = _lastPointerUpPosition;
    final isDoubleTap = lastPointerUpAt != null &&
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
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(_textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: CatalogHome(
        themeMode: _themeMode,
        textScale: _textScale,
        onThemeModeChanged: _setThemeMode,
        onTextScaleChanged: _setTextScale,
      ),
    );
  }
}

class CatalogHome extends StatefulWidget {
  const CatalogHome({
    super.key,
    required this.themeMode,
    required this.textScale,
    required this.onThemeModeChanged,
    required this.onTextScaleChanged,
  });

  final ThemeMode themeMode;
  final double textScale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  State<CatalogHome> createState() => _CatalogHomeState();
}

class _CatalogHomeState extends State<CatalogHome> {
  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final sections = _sections();

    return Scaffold(
      appBar: AppBarComponent(
        title: 'Components',
        leading: Builder(
          builder: (context) {
            return IconButtonComponent(
              tooltip: 'Settings',
              variant: IconButtonComponentVariant.unfilled,
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedMenu01),
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButtonComponent(
                tooltip: 'Text scale',
                variant: IconButtonComponentVariant.unfilled,
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const _CatalogHugeIcon(
                  HugeIcons.strokeRoundedTextFont,
                ),
              );
            },
          ),
          _CatalogThemeCycleButton(
            themeMode: widget.themeMode,
            onChanged: widget.onThemeModeChanged,
          ),
        ],
      ),
      drawer: const CatalogSettingsDrawer(),
      endDrawer: CatalogTextScaleDrawer(
        textScale: widget.textScale,
        onTextScaleChanged: widget.onTextScaleChanged,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          for (final section in sections) ...[
            _CatalogSectionTile(
              section: section,
              themeMode: widget.themeMode,
              textScale: widget.textScale,
              onThemeModeChanged: widget.onThemeModeChanged,
              onTextScaleChanged: widget.onTextScaleChanged,
            ),
            if (section != sections.last) const SizedBox(height: Spacing.lg),
          ],
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
        title: 'Title bar',
        icon: HugeIcons.strokeRoundedMenu01,
        components: const [
          'Default',
          'Home',
          'Preserving',
          'Partially preserved',
          'Preserved',
          'Syncing',
          'Video processing',
          'Back',
          'Onboarding',
          'Settings',
          'Title topbar',
          'Title topbar no icon',
          'Onboarding title',
        ],
        previewBuilder: (_) => const TitleBarPreview(),
      ),
      CatalogSection(
        title: 'Header',
        icon: HugeIcons.strokeRoundedHeading,
        components: const [
          'Title',
          'Subtitle',
          'Image',
          'One action',
          'Two actions',
        ],
        previewBuilder: (_) => const _HeaderPreview(),
      ),
      CatalogSection(
        title: 'Avatar',
        icon: HugeIcons.strokeRoundedUser,
        components: const [
          'Sizes',
          'Seed palette',
          'Add contact',
        ],
        previewBuilder: (_) => const _AvatarPreview(),
      ),
      CatalogSection(
        title: 'Selection controls',
        icon: HugeIcons.strokeRoundedSlidersHorizontal,
        components: const [
          'Checkbox',
          'Radio',
          'Switch',
          'Slider',
          'Stepper',
        ],
        previewBuilder: (_) => const _SelectionPreview(),
      ),
    ];
  }
}

class CatalogSection {
  const CatalogSection({
    required this.title,
    required this.icon,
    required this.components,
    required this.previewBuilder,
  });

  final String title;
  final HugeIconData icon;
  final List<String> components;
  final WidgetBuilder previewBuilder;
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyles.h1Bold.copyWith(
                      color: colors.textBase,
                    ),
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

class CatalogTextScaleDrawer extends StatefulWidget {
  const CatalogTextScaleDrawer({
    super.key,
    required this.textScale,
    required this.onTextScaleChanged,
  });

  final double textScale;
  final ValueChanged<double> onTextScaleChanged;

  @override
  State<CatalogTextScaleDrawer> createState() => _CatalogTextScaleDrawerState();
}

class _CatalogTextScaleDrawerState extends State<CatalogTextScaleDrawer> {
  late double _textScale = widget.textScale;

  void _setTextScale(double scale) {
    setState(() => _textScale = scale);
    widget.onTextScaleChanged(scale);
  }

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
                Expanded(
                  child: Text(
                    'Text scale',
                    style: TextStyles.h1Bold.copyWith(
                      color: colors.textBase,
                    ),
                  ),
                ),
                IconButtonComponent(
                  tooltip: 'Close text scale',
                  variant: IconButtonComponentVariant.unfilled,
                  icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedCancel01),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            _CatalogSettingsPreview(
              textScale: _textScale,
              onTextScaleChanged: _setTextScale,
            ),
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
  const _CatalogHugeIcon(
    this.icon, {
    this.color,
    this.size = 24,
  });

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
      variant: IconButtonComponentVariant.unfilled,
      icon: _CatalogHugeIcon(_icon),
      onPressed: () => onChanged(_nextMode),
    );
  }
}

class _CatalogSectionTile extends StatelessWidget {
  const _CatalogSectionTile({
    required this.section,
    required this.themeMode,
    required this.textScale,
    required this.onThemeModeChanged,
    required this.onTextScaleChanged,
  });

  final CatalogSection section;
  final ThemeMode themeMode;
  final double textScale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<double> onTextScaleChanged;

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
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CatalogDetailPage(
              section: section,
              themeMode: themeMode,
              textScale: textScale,
              onThemeModeChanged: onThemeModeChanged,
              onTextScaleChanged: onTextScaleChanged,
            ),
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
    required this.textScale,
    required this.onThemeModeChanged,
    required this.onTextScaleChanged,
  });

  final CatalogSection section;
  final ThemeMode themeMode;
  final double textScale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<double> onTextScaleChanged;

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
      appBar: AppBarComponent(
        title: widget.section.title,
        leading: IconButtonComponent(
          tooltip: 'Back',
          icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedArrowLeft02),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButtonComponent(
                tooltip: 'Text scale',
                variant: IconButtonComponentVariant.unfilled,
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedTextFont),
              );
            },
          ),
          _CatalogThemeCycleButton(
            themeMode: _themeMode,
            onChanged: _setThemeMode,
          ),
        ],
      ),
      endDrawer: CatalogTextScaleDrawer(
        textScale: widget.textScale,
        onTextScaleChanged: widget.onTextScaleChanged,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          widget.section.previewBuilder(context),
        ],
      ),
      backgroundColor: colors.backgroundBase,
    );
  }
}

class _CatalogSettingsPreview extends StatelessWidget {
  const _CatalogSettingsPreview({
    required this.textScale,
    required this.onTextScaleChanged,
  });

  final double textScale;
  final ValueChanged<double> onTextScaleChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Text scale',
                style: TextStyles.large.copyWith(
                  color: colors.textBase,
                ),
              ),
            ),
            Text(
              '${textScale.toStringAsFixed(2)}x',
              style: TextStyles.bodyBold.copyWith(color: colors.textBase),
            ),
          ],
        ),
        SliderComponent(
          value: textScale,
          min: 0.85,
          max: 2,
          divisions: 23,
          onChanged: onTextScaleChanged,
        ),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            ButtonComponent(
              label: '1.0x',
              variant: ButtonComponentVariant.secondary,
              onTap: () => onTextScaleChanged(1),
            ),
            ButtonComponent(
              label: '1.3x',
              variant: ButtonComponentVariant.secondary,
              onTap: () => onTextScaleChanged(1.3),
            ),
            ButtonComponent(
              label: '1.6x',
              variant: ButtonComponentVariant.secondary,
              onTap: () => onTextScaleChanged(1.6),
            ),
            ButtonComponent(
              label: '2.0x',
              variant: ButtonComponentVariant.secondary,
              onTap: () => onTextScaleChanged(2),
            ),
          ],
        ),
      ],
    );
  }
}

class _CatalogPreviewGroup extends StatelessWidget {
  const _CatalogPreviewGroup({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.large.copyWith(color: colors.textBase),
        ),
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
        const SizedBox(height: Spacing.xxl),
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
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => page),
        );
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
  const _SettingsExampleShell({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Scaffold(
      appBar: AppBarComponent(
        title: title,
        leading: IconButtonComponent(
          tooltip: 'Back',
          icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedArrowLeft02),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const SizedBox(height: Spacing.md),
          ],
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
        _Swatch(color: colors.info),
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
        Text(
          text,
          style: style.copyWith(color: color),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          detail,
          style: TextStyles.mini.copyWith(color: colors.textLight),
        ),
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
        _ButtonStateGroup(title: 'Default'),
        _ButtonStateGroup(
          title: 'Disabled',
          disabled: true,
        ),
        _CatalogPreviewGroup(
          title: 'Icon button',
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
  const _ButtonStateGroup({
    required this.title,
    this.disabled = false,
  });

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
  const _ButtonPreviewRow({
    required this.spec,
    required this.disabled,
  });

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
    const columns = [
      'Default',
      'Hover',
      'Pressed',
      'Disabled',
      'Loading',
      'Success',
    ];
    const rows = [
      _IconButtonPreviewRow(
        label: 'Primary',
        variant: IconButtonComponentVariant.primary,
        states: columns,
      ),
      _IconButtonPreviewRow(
        label: 'Critical',
        variant: IconButtonComponentVariant.critical,
        states: columns,
      ),
      _IconButtonPreviewRow(
        label: 'Unfilled',
        variant: IconButtonComponentVariant.unfilled,
        states: ['Default', 'Disabled', 'Loading', 'Success'],
      ),
      _IconButtonPreviewRow(
        label: 'Secondary',
        variant: IconButtonComponentVariant.secondary,
        states: ['Default', 'Disabled', 'Loading', 'Success'],
      ),
      _IconButtonPreviewRow(
        label: 'Green',
        variant: IconButtonComponentVariant.green,
        states: columns,
      ),
      _IconButtonPreviewRow(
        label: 'Circular',
        variant: IconButtonComponentVariant.circular,
        states: columns,
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
  const _IconButtonPreviewRow({
    required this.label,
    required this.variant,
    required this.states,
  });

  final String label;
  final IconButtonComponentVariant variant;
  final List<String> states;

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
          'Hover',
          'Pressed',
          'Disabled',
          'Loading',
          'Success',
        ])
          SizedBox(
            width: 76,
            child: Center(
              child: states.contains(state)
                  ? _IconButtonStatePreview(
                      variant: variant,
                      state: state,
                    )
                  : const SizedBox.square(dimension: 38),
            ),
          ),
      ],
    );
  }
}

class _IconButtonStatePreview extends StatelessWidget {
  const _IconButtonStatePreview({
    required this.variant,
    required this.state,
  });

  final IconButtonComponentVariant variant;
  final String state;

  @override
  Widget build(BuildContext context) {
    return IconButtonComponent(
      tooltip: state,
      variant: variant,
      state: switch (state) {
        'Hover' => IconButtonComponentState.hover,
        'Pressed' => IconButtonComponentState.pressed,
        _ => IconButtonComponentState.normal,
      },
      isLoading: state == 'Loading',
      isSuccess: state == 'Success',
      onPressed: state == 'Disabled' ? null : () {},
      icon: const _CatalogHugeIcon(
        HugeIcons.strokeRoundedAdd01,
        size: 18,
      ),
    );
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
                trailing:
                    const _CatalogHugeIcon(HugeIcons.strokeRoundedVideo01),
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
  const _AvatarTableRow({
    required this.label,
    required this.children,
  });

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
          SizedBox(
            width: 96,
            height: 64,
            child: Center(child: child),
          ),
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
  const _FaceAvatar({
    required this.seed,
    required this.initials,
  });

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
  late final TextEditingController _readOnlyController;

  @override
  void initState() {
    super.initState();
    _focusedController = TextEditingController(text: 'mira@example.com');
    _errorController = TextEditingController(text: 'short');
    _successController = TextEditingController(text: '482901');
    _disabledController = TextEditingController(text: 'mira.roy@example.com');
    _clearableController = TextEditingController(text: 'family trip');
    _passwordController = TextEditingController(text: 'correct horse');
    _readOnlyController = TextEditingController(text: 'Mira Roy');
  }

  @override
  void dispose() {
    _focusedController.dispose();
    _errorController.dispose();
    _successController.dispose();
    _disabledController.dispose();
    _clearableController.dispose();
    _passwordController.dispose();
    _readOnlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CatalogPreviewList(
      children: [
        const _CatalogPreviewGroup(
          title: 'Normal',
          child:
              TextInputComponent(label: 'Email address', hintText: 'Hint text'),
        ),
        _CatalogPreviewGroup(
          title: 'Focused',
          child: TextInputComponent(
            controller: _focusedController,
            label: 'Email address',
            isFocused: true,
            prefix: const _CatalogHugeIcon(HugeIcons.strokeRoundedMail01),
            suffix: const _CatalogHugeIcon(HugeIcons.strokeRoundedView),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Error',
          child: TextInputComponent(
            controller: _errorController,
            label: 'Password',
            errorText: 'Use at least 8 characters.',
            obscureText: true,
            prefix: const _CatalogHugeIcon(HugeIcons.strokeRoundedLockPassword),
            suffix: const _CatalogHugeIcon(HugeIcons.strokeRoundedView),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Success',
          child: TextInputComponent(
            controller: _successController,
            label: 'Recovery code',
            successText: 'Recovery code verified.',
            suffix: const _CatalogHugeIcon(
              HugeIcons.strokeRoundedCheckmarkCircle01,
            ),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Disabled',
          child: TextInputComponent(
            controller: _disabledController,
            label: 'Account email',
            enabled: false,
            prefix: const _CatalogHugeIcon(HugeIcons.strokeRoundedMail01),
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
            helperText: 'Used for receipts and security alerts.',
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Prefix icon',
          child: TextInputComponent(
            label: 'Search',
            hintText: 'Search albums',
            prefix: _CatalogHugeIcon(HugeIcons.strokeRoundedSearch01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Trailing icon',
          child: TextInputComponent(
            label: 'Password',
            hintText: 'Enter password',
            suffix: _CatalogHugeIcon(HugeIcons.strokeRoundedView),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Prefix and trailing icons',
          child: TextInputComponent(
            label: 'Search',
            hintText: 'Search people',
            prefix: _CatalogHugeIcon(HugeIcons.strokeRoundedSearch01),
            suffix: _CatalogHugeIcon(HugeIcons.strokeRoundedCancel01),
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Clearable search',
          child: TextInputComponent(
            controller: _clearableController,
            label: 'Search',
            hintText: 'Search files',
            prefix: const _CatalogHugeIcon(HugeIcons.strokeRoundedSearch01),
            isClearable: true,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Password visibility',
          child: TextInputComponent(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter password',
            obscureText: true,
            showPasswordToggle: true,
            prefix: const _CatalogHugeIcon(HugeIcons.strokeRoundedLockPassword),
            autofillHints: const [AutofillHints.password],
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Alert message',
          child: TextInputComponent(
            label: 'Recovery key',
            hintText: 'Enter recovery key',
            alertText: 'Save this key somewhere safe before continuing.',
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Read only',
          child: TextInputComponent(
            controller: _readOnlyController,
            label: 'Owner',
            readOnly: true,
            suffix: const _CatalogHugeIcon(HugeIcons.strokeRoundedLock),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Max length',
          child: TextInputComponent(
            label: 'Referral code',
            hintText: 'SUMMER2026',
            maxLength: 12,
            counterText: '',
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: label + trailing + warning message',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            errorText: 'This is an error',
            maxLines: 4,
            suffix: _CatalogHugeIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: label + trailing',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            suffix: _CatalogHugeIcon(HugeIcons.strokeRoundedCopy01),
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
            suffix: _CatalogHugeIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: no label',
          child: TextInputComponent(
            hintText: 'Hint text',
            maxLines: 4,
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: focused',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            isFocused: true,
            suffix: _CatalogHugeIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: error',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            errorText: 'This is an error',
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: success',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            successText: 'Saved',
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Multiline: disabled',
          child: TextInputComponent(
            label: 'Description',
            hintText: 'Hint text',
            maxLines: 4,
            enabled: false,
            suffix: _CatalogHugeIcon(HugeIcons.strokeRoundedCopy01),
          ),
        ),
      ],
    );
  }
}

class TitleBarPreview extends StatelessWidget {
  const TitleBarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CatalogPreviewList(
      children: [
        _CatalogPreviewGroup(
          title: 'Default',
          child: _TitleBarSample(variant: TitleBarComponentVariant.brand),
        ),
        _CatalogPreviewGroup(
          title: 'Home',
          child: _TitleBarSample(variant: TitleBarComponentVariant.home),
        ),
        _CatalogPreviewGroup(
          title: 'Preserving',
          child: _TitleBarSample(variant: TitleBarComponentVariant.preserving),
        ),
        _CatalogPreviewGroup(
          title: 'Partially preserved',
          child: _TitleBarSample(
            variant: TitleBarComponentVariant.partiallyPreserved,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Preserved',
          child: _TitleBarSample(variant: TitleBarComponentVariant.preserved),
        ),
        _CatalogPreviewGroup(
          title: 'Syncing',
          child: _TitleBarSample(variant: TitleBarComponentVariant.syncing),
        ),
        _CatalogPreviewGroup(
          title: 'Video processing',
          child: _TitleBarSample(
            variant: TitleBarComponentVariant.videoProcessing,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Back',
          child: _TitleBarSample(variant: TitleBarComponentVariant.back),
        ),
        _CatalogPreviewGroup(
          title: 'Onboarding',
          child: _TitleBarSample(variant: TitleBarComponentVariant.onboarding),
        ),
        _CatalogPreviewGroup(
          title: 'Settings',
          child: _TitleBarSample(variant: TitleBarComponentVariant.settings),
        ),
        _CatalogPreviewGroup(
          title: 'Title topbar',
          child: _TitleBarSample(variant: TitleBarComponentVariant.titleTopbar),
        ),
        _CatalogPreviewGroup(
          title: 'Title topbar no icon',
          child: _TitleBarSample(
            variant: TitleBarComponentVariant.titleTopbarNoIcon,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Onboarding title',
          child: _TitleBarSample(
            variant: TitleBarComponentVariant.onboardingTitle,
          ),
        ),
      ],
    );
  }
}

class _TitleBarSample extends StatelessWidget {
  const _TitleBarSample({required this.variant});

  final TitleBarComponentVariant variant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TitleBarComponent(
        variant: variant,
        title: _title,
        leading: _leading,
        trailing: _trailing,
        statusIcon: _statusIcon,
      ),
    );
  }

  String? get _title {
    return switch (variant) {
      TitleBarComponentVariant.brand => 'Photos',
      TitleBarComponentVariant.home => 'Home',
      TitleBarComponentVariant.onboarding => 'Create account',
      TitleBarComponentVariant.titleTopbar => 'Albums',
      TitleBarComponentVariant.titleTopbarNoIcon => 'Albums',
      TitleBarComponentVariant.onboardingTitle => 'Secure backup',
      _ => null,
    };
  }

  Widget? get _leading {
    return switch (variant) {
      TitleBarComponentVariant.onboarding => null,
      _ => const _CatalogHugeIcon(HugeIcons.strokeRoundedArrowLeft02),
    };
  }

  Widget? get _trailing {
    return switch (variant) {
      TitleBarComponentVariant.home ||
      TitleBarComponentVariant.preserving ||
      TitleBarComponentVariant.partiallyPreserved ||
      TitleBarComponentVariant.preserved ||
      TitleBarComponentVariant.syncing ||
      TitleBarComponentVariant.videoProcessing =>
        const _CatalogHugeIcon(HugeIcons.strokeRoundedMoreHorizontal),
      TitleBarComponentVariant.settings ||
      TitleBarComponentVariant.titleTopbar =>
        const _CatalogHugeIcon(HugeIcons.strokeRoundedSearch01),
      _ => null,
    };
  }

  Widget? get _statusIcon {
    return switch (variant) {
      TitleBarComponentVariant.preserving ||
      TitleBarComponentVariant.partiallyPreserved ||
      TitleBarComponentVariant.preserved =>
        const _CatalogHugeIcon(HugeIcons.strokeRoundedCheckmarkCircle01),
      TitleBarComponentVariant.syncing => const _CatalogHugeIcon(
          HugeIcons.strokeRoundedRefresh,
        ),
      TitleBarComponentVariant.videoProcessing => const _CatalogHugeIcon(
          HugeIcons.strokeRoundedVideo01,
        ),
      _ => null,
    };
  }
}

class _HeaderPreview extends StatelessWidget {
  const _HeaderPreview();

  @override
  Widget build(BuildContext context) {
    return const _CatalogPreviewList(
      children: [
        _CatalogPreviewGroup(
          title: 'Title + subtitle + two actions',
          child: _HeaderSample(
            subtitle: true,
            actionCount: 2,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Title + two actions',
          child: _HeaderSample(actionCount: 2),
        ),
        _CatalogPreviewGroup(
          title: 'Title + one action',
          child: _HeaderSample(actionCount: 1),
        ),
        _CatalogPreviewGroup(
          title: 'Title + subtitle',
          child: _HeaderSample(subtitle: true),
        ),
        _CatalogPreviewGroup(
          title: 'Title only',
          child: _HeaderSample(),
        ),
        _CatalogPreviewGroup(
          title: 'Title + subtitle + one action',
          child: _HeaderSample(
            subtitle: true,
            actionCount: 1,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Image + subtitle + two actions',
          child: _HeaderSample(
            image: true,
            subtitle: true,
            actionCount: 2,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Image + two actions',
          child: _HeaderSample(
            image: true,
            actionCount: 2,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Image + one action',
          child: _HeaderSample(
            image: true,
            actionCount: 1,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Image + subtitle',
          child: _HeaderSample(
            image: true,
            subtitle: true,
          ),
        ),
        _CatalogPreviewGroup(
          title: 'Image only',
          child: _HeaderSample(image: true),
        ),
        _CatalogPreviewGroup(
          title: 'Image + subtitle + one action',
          child: _HeaderSample(
            image: true,
            subtitle: true,
            actionCount: 1,
          ),
        ),
      ],
    );
  }
}

class _HeaderSample extends StatelessWidget {
  const _HeaderSample({
    this.image = false,
    this.subtitle = false,
    this.actionCount = 0,
  });

  final bool image;
  final bool subtitle;
  final int actionCount;

  @override
  Widget build(BuildContext context) {
    return HeaderComponent(
      title: 'Title',
      subtitle: subtitle ? 'Subtitle' : null,
      leading: image ? const _HeaderImage() : null,
      actions: [
        for (var index = 0; index < actionCount; index++)
          IconButtonComponent(
            tooltip: index == 0 ? 'Add' : 'Create',
            variant: IconButtonComponentVariant.primary,
            icon: const _CatalogHugeIcon(HugeIcons.strokeRoundedAdd01),
            onPressed: () {},
          ),
      ],
    );
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
                control:
                    ToggleSwitchComponent(selected: false, onChanged: null),
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

enum _MenuItemTrailingKind {
  icon,
  toggle,
  none,
}

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
          title: 'Loading',
          child: _MenuItemLoadingPreview(),
        ),
        const _CatalogPreviewGroup(
          title: 'Success',
          child: _MenuItemSuccessPreview(),
        ),
        const _CatalogPreviewGroup(
          title: 'Loading only',
          child: _MenuItemLoadingOnlyPreview(),
        ),
        _CatalogPreviewGroup(
          title: 'Display only',
          child: Builder(
            builder: (context) {
              final colors = context.componentColors;
              return MenuComponent(
                title: 'Storage plan',
                subtitle: 'Gestures disabled for read-only rows',
                leading:
                    const _CatalogHugeIcon(HugeIcons.strokeRoundedDatabase),
                trailing: Text(
                  '2 TB',
                  style: TextStyles.body.copyWith(color: colors.textLight),
                ),
                gesturesEnabled: false,
              );
            },
          ),
        ),
        const _CatalogPreviewGroup(
          title: 'Async state',
          child: MenuComponent(
            title: 'Check for updates',
            subtitle: 'Shows loading and success states',
            leading: _CatalogHugeIcon(HugeIcons.strokeRoundedRefresh),
            trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
            surfaceExecutionStates: true,
            alwaysShowSuccessState: true,
            onTap: _completeAfterDelay,
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
                leading:
                    const _CatalogHugeIcon(HugeIcons.strokeRoundedDelete02),
                trailing: const _CatalogTrailingIcon(
                  HugeIcons.strokeRoundedArrowRight01,
                ),
                titleColor: colors.warning,
                iconColor: colors.warning,
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

class _MenuItemLoadingPreview extends StatelessWidget {
  const _MenuItemLoadingPreview();

  @override
  Widget build(BuildContext context) {
    return const MenuComponent(
      title: 'Updating backup',
      subtitle: 'Tap to see the trailing loading state',
      leading: _CatalogHugeIcon(HugeIcons.strokeRoundedCloudUpload),
      trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
      surfaceExecutionStates: true,
      onTap: _completeAfterDelay,
    );
  }
}

class _MenuItemLoadingOnlyPreview extends StatelessWidget {
  const _MenuItemLoadingOnlyPreview();

  @override
  Widget build(BuildContext context) {
    return const MenuComponent(
      title: 'Opening sessions',
      subtitle: 'Loading-only execution state',
      leading: _CatalogHugeIcon(HugeIcons.strokeRoundedUserGroup),
      trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
      showOnlyLoadingState: true,
      onTap: _completeAfterDelay,
    );
  }
}

class _MenuItemSuccessPreview extends StatelessWidget {
  const _MenuItemSuccessPreview();

  @override
  Widget build(BuildContext context) {
    return const MenuComponent(
      title: 'Copied recovery key',
      subtitle: 'Tap to see completion replace trailing slot',
      leading: _CatalogHugeIcon(HugeIcons.strokeRoundedCopy01),
      trailing: _CatalogTrailingIcon(HugeIcons.strokeRoundedArrowRight01),
      alwaysShowSuccessState: true,
      onTap: _completeAfterDelay,
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
