import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/opened_settings_event.dart';
import 'package:photos/ui/viewer/search/search_widget.dart';

class HomeHeaderWidget extends StatefulWidget {
  final Widget centerWidget;
  const HomeHeaderWidget({required this.centerWidget, Key? key})
      : super(key: key);

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final hasNotch = window.viewPadding.top > 65;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, hasNotch ? 4 : 8, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            onPressed: () {
              Scaffold.of(context).openDrawer();
              Bus.instance.fire(OpenedSettingsEvent());
            },
            splashColor: Colors.transparent,
            icon: const Icon(
              Icons.menu_outlined,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: widget.centerWidget,
          ),
          const SearchIconWidget(),
        ],
      ),
    );
  }
}
