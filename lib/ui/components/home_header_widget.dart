import 'package:flutter/material.dart';
import "package:photos/ui/components/buttons/icon_button_widget.dart";

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
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButtonWidget(
              iconButtonType: IconButtonType.primary,
              icon: Icons.menu_outlined,
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: widget.centerWidget,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
