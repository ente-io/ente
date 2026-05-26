import 'dart:async';
import 'dart:math' as math;

import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/tab_changed_event.dart';
import "package:photos/models/selected_albums.dart";
import 'package:photos/models/selected_files.dart';

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
  static const int _searchTabIndex = 3;
  static const Duration _doubleTapWindow = Duration(milliseconds: 350);
  late StreamSubscription<TabChangedEvent> _tabChangedEventSubscription;
  int currentTabIndex = 0;
  int? _lastTapIndex;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    currentTabIndex = widget.selectedTabIndex;
    widget.selectedFiles.addListener(_selectedFilesListener);
    widget.selectedAlbums.addListener(_selectedAlbumsListener);
    _tabChangedEventSubscription = Bus.instance.on<TabChangedEvent>().listen((
      event,
    ) {
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
    if (mode == "OnPressed") {
      _handleSearchTabDoubleTap(index);
    }
    debugPrint("_TabChanged called via method $mode");
    Bus.instance.fire(TabChangedEvent(index, TabChangedEventSource.tabBar));
  }

  void _handleSearchTabDoubleTap(int index) {
    final now = DateTime.now();
    final isRepeatTap =
        _lastTapIndex == index &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!) <= _doubleTapWindow;
    _lastTapIndex = index;
    _lastTapAt = now;
    if (index != _searchTabIndex || !isRepeatTap) {
      return;
    }
    if (currentTabIndex != _searchTabIndex) {
      Bus.instance.fire(TabDoubleTapEvent(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool filesAreSelected = widget.selectedFiles.files.isNotEmpty;
    final bool albumsAreSelected = widget.selectedAlbums.albums.isNotEmpty;

    return SafeArea(
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: filesAreSelected || albumsAreSelected ? 0 : 62,
          child: IgnorePointer(
            ignoring: filesAreSelected || albumsAreSelected,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FigmaHomeNavBar(
                      selectedIndex: currentTabIndex,
                      onTabChange: (index) {
                        _onTabChange(index, mode: "OnPressed");
                      },
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

class _FigmaHomeNavBar extends StatelessWidget {
  const _FigmaHomeNavBar({
    required this.selectedIndex,
    required this.onTabChange,
  });

  static const _tabs = [
    _FigmaNavTab(
      semanticLabel: 'Home',
      outlineAsset: 'assets/icons/nav_bar/home_outline.svg',
      filledAsset: 'assets/icons/nav_bar/home_filled.svg',
    ),
    _FigmaNavTab(
      semanticLabel: 'Albums',
      outlineAsset: 'assets/icons/nav_bar/albums_outline.svg',
      filledAsset: 'assets/icons/nav_bar/albums_filled.svg',
    ),
    _FigmaNavTab(
      semanticLabel: 'Feed',
      outlineAsset: 'assets/icons/nav_bar/feed_outline.svg',
      filledAsset: 'assets/icons/nav_bar/feed_filled.svg',
    ),
    _FigmaNavTab(
      semanticLabel: 'Search',
      outlineAsset: 'assets/icons/nav_bar/search_outline.svg',
      filledAsset: 'assets/icons/nav_bar/search_filled.svg',
    ),
  ];

  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final navWidth = math.min(
      318.0,
      math.max(0.0, MediaQuery.sizeOf(context).width - 32.0),
    );

    return Container(
      width: navWidth,
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.fillLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            offset: Offset(0, 4),
            blurRadius: 8.75,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_tabs.length, (index) {
          return _FigmaNavButton(
            tab: _tabs[index],
            selected: selectedIndex == index,
            onTap: () => onTabChange(index),
          );
        }),
      ),
    );
  }
}

class _FigmaNavButton extends StatelessWidget {
  const _FigmaNavButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _FigmaNavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final iconColor = colors.iconColor;
    return Semantics(
      label: tab.semanticLabel,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? colors.fillDark : colors.fillLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _FigmaNavIcon(tab: tab, selected: selected, color: iconColor),
        ),
      ),
    );
  }
}

class _FigmaNavIcon extends StatelessWidget {
  const _FigmaNavIcon({
    required this.tab,
    required this.selected,
    required this.color,
  });

  final _FigmaNavTab tab;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    return SvgPicture.asset(
      selected ? tab.filledAsset : tab.outlineAsset,
      width: 18,
      height: 18,
      colorFilter: colorFilter,
    );
  }
}

class _FigmaNavTab {
  const _FigmaNavTab({
    required this.semanticLabel,
    required this.outlineAsset,
    required this.filledAsset,
  });

  final String semanticLabel;
  final String outlineAsset;
  final String filledAsset;
}
