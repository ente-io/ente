import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:ente_auth/ui/components/title_bar_title_widget.dart';
import 'package:ente_auth/ui/components/title_bar_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:launcher_icon_switcher/launcher_icon_switcher.dart';
import 'package:logging/logging.dart';

enum AppIcon {
  iconDefault(
    "Default",
    "IconDefault",
    "assets/launcher_icon/icon-default.png",
  ),
  iconLight("Light", "IconLight", "assets/launcher_icon/icon-light.png"),
  iconDark("Dark", "IconDark", "assets/launcher_icon/icon-dark.png"),
  iconOG("Shield", "IconOG", "assets/launcher_icon/icon-og.png");

  final String name;
  final String id;
  final String path;
  const AppIcon(this.name, this.id, this.path);
}

class AppIconSelectionScreen extends StatefulWidget {
  const AppIconSelectionScreen({super.key});

  @override
  State<AppIconSelectionScreen> createState() => _AppIconSelectionScreenState();
}

class _AppIconSelectionScreenState extends State<AppIconSelectionScreen> {
  final _logger = Logger("_AppIconSelectionScreenState");
  final _iconSwitcher = LauncherIconSwitcher();
  String? _currentIcon;
  // ignore: prefer_final_fields
  bool _isChangingIcon = false;

  @override
  void initState() {
    super.initState();
    _iconSwitcher.initialize(
      AppIcon.values.map((e) => e.id).toList(),
      AppIcon.iconDefault.id,
    );
    _iconSwitcher.getCurrentIcon().then(
      (icon) {
        _logger.info("Current icon is $icon");
        setState(() {
          _currentIcon = icon;
        });
      },
    ).onError(
      (error, stackTrace) {
        _logger.severe("Error getting current icon", error, stackTrace);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints.tightFor(width: 450),
          child: CustomScrollView(
            primary: false,
            slivers: <Widget>[
              TitleBarWidget(
                flexibleSpaceTitle: TitleBarTitleWidget(
                  title: l10n.appIcon,
                ),
              ),
              _currentIcon != null
                  ? SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (delegateBuildContext, index) {
                            final icon = AppIcon.values[index];
                            final isCurrentIcon = icon.id == _currentIcon;
                            return _AppIconTile(
                              icon,
                              isCurrentIcon,
                              () {
                                if (!isCurrentIcon) {
                                  _changeIcon(icon.id);
                                }
                              },
                            );
                          },
                          childCount: AppIcon.values.length,
                        ),
                      ),
                    )
                  : SliverToBoxAdapter(
                      child: EnteLoadingWidget(
                        color: getEnteColorScheme(context).strokeMuted,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeIcon(String icon) async {
    if (_isChangingIcon) return;
    setState(() {
      _isChangingIcon = true;
    });
    try {
      _logger.info("Changing icon to $icon");
      await _iconSwitcher.setIcon(icon);
      _logger.info("Icon changed to $icon");
      setState(() {
        _currentIcon = icon;
      });
    } catch (error, stackTrace) {
      _logger.severe("Error changing icon", error, stackTrace);
    } finally {
      setState(() {
        _isChangingIcon = false;
      });
    }
  }
}

class _AppIconTile extends StatelessWidget {
  final AppIcon appIcon;
  final bool isSelected;
  final Function() onSelect;
  const _AppIconTile(this.appIcon, this.isSelected, this.onSelect);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          onSelect();
        },
        child: Container(
          decoration: BoxDecoration(
            color: getEnteColorScheme(context).fillFaint,
            borderRadius: const BorderRadius.all(
              Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Radio(
                value: isSelected,
                groupValue: true,
                onChanged: (_) {
                  onSelect();
                },
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (isSelected) {
                    return getEnteColorScheme(context).primary700;
                  } else {
                    return getEnteColorScheme(context).fillMuted;
                  }
                }),
                visualDensity: VisualDensity.compact,
                splashRadius: 0,
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    ClipSmoothRect(
                      radius: SmoothBorderRadius(
                        cornerRadius: 12,
                        cornerSmoothing: 1,
                      ),
                      child: Image(
                        width: 60,
                        height: 60,
                        image: AssetImage(
                          appIcon.path,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      child: Text(
                        key: ValueKey(isSelected),
                        appIcon.name,
                        style: isSelected
                            ? getEnteTextTheme(context).bodyBold
                            : getEnteTextTheme(context).bodyFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
