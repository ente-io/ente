import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/tab_changed_event.dart';
import "package:photos/models/selected_albums.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/tabs/nav_bar.dart';

class HomeBottomNavigationBar extends StatefulWidget {
  const HomeBottomNavigationBar(
    this.selectedFiles,
    this.selectedAlbums, {
    required this.selectedTabIndex,
    super.key,
  });

  final SelectedFiles selectedFiles;
  final SelectedAlbums selectedAlbums;
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
    widget.selectedFiles.addListener(_selectedFilesListener);
    widget.selectedAlbums.addListener(_selectedAlbumsListener);
    _tabChangedEventSubscription =
        Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.source != TabChangedEventSource.tabBar) {
        debugPrint(
          '${(TabChangedEvent).toString()} index changed  from '
          '$currentTabIndex to ${event.selectedIndex} via ${event.source}',
        );
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
    widget.selectedFiles.removeListener(_selectedFilesListener);
    widget.selectedAlbums.removeListener(_selectedAlbumsListener);
    super.dispose();
  }

  void _selectedFilesListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectedAlbumsListener() {
    if (mounted) {
      setState(() {});
    }
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
    final bool albumsAreSelected = widget.selectedAlbums.albums.isNotEmpty;
    final enteColorScheme = getEnteColorScheme(context);

    return SafeArea(
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: filesAreSelected || albumsAreSelected ? 0 : 56,
          child: IgnorePointer(
            ignoring: filesAreSelected || albumsAreSelected,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GNav(
                      curve: Curves.easeOutExpo,
                      backgroundColor:
                          getEnteColorScheme(context).backgroundElevated2,
                      mainAxisAlignment: MainAxisAlignment.center,
                      iconSize: 24,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      duration: const Duration(milliseconds: 200),
                      gap: 0,
                      tabBorderRadius: 32,
                      tabBackgroundColor:
                          Theme.of(context).brightness == Brightness.light
                              ? strokeFainterLight
                              : strokeSolidFaintLight,
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
                        GButton(
                          margin: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                          icon: Icons.search_outlined,
                          iconColor: enteColorScheme.tabIcon,
                          iconActiveColor: strokeBaseLight,
                          text: '',
                          onPressed: () {
                            _onTabChange(
                              3,
                              mode: "OnPressed",
                            ); // To take care
                            // of occasional missing events
                          },
                        ),
                      ],
                      selectedIndex: currentTabIndex,
                      onTabChange: _onTabChange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
