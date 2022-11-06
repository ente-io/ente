import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/opened_settings_event.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButtonWidget(
          iconButtonType: IconButtonType.primary,
          icon: Icons.menu_outlined,
          onTap: () {
            Scaffold.of(context).openDrawer();
            Bus.instance.fire(OpenedSettingsEvent());
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.centerWidget,
        ),
        const SearchIconWidget(),
      ],
    );
  }
}
