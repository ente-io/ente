import 'package:flutter/material.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/map/map_screen.dart';
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
        Flexible(
          flex: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButtonWidget(
                iconButtonType: IconButtonType.primary,
                icon: Icons.menu_outlined,
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: widget.centerWidget,
          ),
        ),
        Flexible(
          flex: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SearchIconWidget(),
              PopupMenuButton(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                offset: const Offset(0, 40),
                itemBuilder: (context) => [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Row(
                      children: const [
                        Icon(Icons.map_outlined),
                        SizedBox(width: 16),
                        Text(
                          "Map",
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (item) => {
                  if (item == 0)
                    {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      )
                    }
                },
              )
            ],
          ),
        )
      ],
    );
  }
}
