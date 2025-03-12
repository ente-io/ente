import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:launcher_icon_switcher/launcher_icon_switcher.dart";
import "package:logging/logging.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";

enum AppIcon {
  iconLight(
    "The light icon",
    "IconLight",
    "assets/launcher_icon/icon-light.png",
  ),
  iconDark(
    "The dark icon",
    "IconDark",
    "assets/launcher_icon/icon-dark.png",
  ),
  iconGreen(
    "The green icon",
    "IconGreen",
    "assets/launcher_icon/icon-green.png",
  ),
  ;

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
  bool _ready = false;
  final _logger = Logger("_AppIconSelectionScreenState");
  final _currentSelectionNotifier = ValueNotifier("Unassigned");

  @override
  void initState() {
    super.initState();
    LauncherIconSwitcher()
        .initialize(["IconGreen", "IconDark", "IconLight"], "IconGreen");
    LauncherIconSwitcher().getCurrentIcon().then(
      (value) {
        _currentSelectionNotifier.value = value;
        setState(() {
          _ready = true;
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
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "App Icon",
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          _ready
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (delegateBuildContext, index) {
                        return _AppIconTile(
                          AppIcon.values[index],
                          currentSelection: _currentSelectionNotifier,
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
    );
  }
}

class _AppIconTile extends StatefulWidget {
  final AppIcon appIcon;
  final ValueNotifier<String> currentSelection;
  const _AppIconTile(this.appIcon, {required this.currentSelection});

  @override
  State<_AppIconTile> createState() => _AppIconTileState();
}

class _AppIconTileState extends State<_AppIconTile> {
  bool _isSelection = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentSelection.value == widget.appIcon.id) {
      _isSelection = true;
    }
    widget.currentSelection.addListener(
      currentStateListener,
    );
  }

  @override
  void dispose() {
    widget.currentSelection.removeListener(
      currentStateListener,
    );
    super.dispose();
  }

  void currentStateListener() {
    final pervSelectionState = _isSelection;
    if (widget.currentSelection.value == widget.appIcon.id) {
      _isSelection = true;
    } else {
      _isSelection = false;
    }
    if (pervSelectionState != _isSelection) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          // LauncherIconSwitcher().setIcon(widget.appIcon.id);
          widget.currentSelection.value = widget.appIcon.id;
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
                value: _isSelection,
                groupValue: true,
                onChanged: (_) {
                  // LauncherIconSwitcher().setIcon(widget.appIcon.id);
                  widget.currentSelection.value = widget.appIcon.id;
                },
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (_isSelection) {
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
                          widget.appIcon.path,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      child: Text(
                        key: ValueKey(_isSelection),
                        widget.appIcon.name,
                        style: _isSelection
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
