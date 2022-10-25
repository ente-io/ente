import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/nav_bar.dart';

class HomeBottomNavigationBar extends StatefulWidget {
  const HomeBottomNavigationBar(
    this.selectedFiles, {
    required this.selectedTabIndex,
    Key? key,
  }) : super(key: key);

  final SelectedFiles selectedFiles;
  final int selectedTabIndex;

  @override
  State<HomeBottomNavigationBar> createState() =>
      _HomeBottomNavigationBarState();
}

class _HomeBottomNavigationBarState extends State<HomeBottomNavigationBar> {
  late StreamSubscription<TabChangedEvent> _tabChangedEventSubscription;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    currentTabIndex = widget.selectedTabIndex;
    widget.selectedFiles.addListener(() {
      setState(() {});
    });
    _tabChangedEventSubscription =
        Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.source != TabChangedEventSource.tabBar) {
        debugPrint('${(TabChangedEvent).toString()} index changed  from '
            '$currentTabIndex to ${event.selectedIndex} via ${event.source}');
        if (mounted) {
          setState(() {
            currentTabIndex = event.selectedIndex;
          });
        }
      } else if (event.source == TabChangedEventSource.tabBar &&
          currentTabIndex == event.selectedIndex) {
        // user tapped on the currently selected index on the tapBar
        Bus.instance.fire(TabDoubleTapEvent(currentTabIndex));
      }
    });
  }

  @override
  void dispose() {
    _tabChangedEventSubscription.cancel();
    super.dispose();
  }

  void _onTabChange(int index, {String mode = 'tabChanged'}) {
    debugPrint("_TabChanged called via method $mode");
    Bus.instance.fire(
      TabChangedEvent(
        index,
        TabChangedEventSource.tabBar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool filesAreSelected = widget.selectedFiles.files.isNotEmpty;
    final enteColorScheme = getEnteColorScheme(context);
    final navBarBlur =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? blurBase
            : blurMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: filesAreSelected ? 0 : 56,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: filesAreSelected ? 0.0 : 1.0,
        curve: Curves.easeIn,
        child: IgnorePointer(
          ignoring: filesAreSelected,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      height: 48,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: navBarBlur,
                            sigmaY: navBarBlur,
                          ),
                          child: GNav(
                            curve: Curves.easeOutExpo,
                            backgroundColor:
                                getEnteColorScheme(context).fillMuted,
                            mainAxisAlignment: MainAxisAlignment.center,
                            rippleColor: Colors.white.withOpacity(0.1),
                            activeColor: Theme.of(context)
                                .colorScheme
                                .gNavBarActiveColor,
                            iconSize: 24,
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                            duration: const Duration(milliseconds: 200),
                            gap: 0,
                            tabBorderRadius: 32,
                            tabBackgroundColor: Theme.of(context)
                                .colorScheme
                                .gNavBarActiveColor,
                            haptic: false,
                            tabs: [
                              GButton(
                                margin: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                                icon: Icons.home_rounded,
                                iconColor: enteColorScheme.tabIcon,
                                iconActiveColor: strokeBaseLight,
                                text: '',
                                onPressed: () {
                                  _onTabChange(
                                    0,
                                    mode: "OnPressed",
                                  ); // To take care of occasional missing events
                                },
                              ),
                              GButton(
                                margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                                icon: Icons.collections_rounded,
                                iconColor: enteColorScheme.tabIcon,
                                iconActiveColor: strokeBaseLight,
                                text: '',
                                onPressed: () {
                                  _onTabChange(
                                    1,
                                    mode: "OnPressed",
                                  ); // To take care of occasional missing
                                  // events
                                },
                              ),
                              GButton(
                                margin: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                                icon: Icons.people_outlined,
                                iconColor: enteColorScheme.tabIcon,
                                iconActiveColor: strokeBaseLight,
                                text: '',
                                onPressed: () {
                                  _onTabChange(
                                    2,
                                    mode: "OnPressed",
                                  ); // To take care
                                  // of occasional missing events
                                },
                              ),
                            ],
                            selectedIndex: currentTabIndex,
                            onTabChange: _onTabChange,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
