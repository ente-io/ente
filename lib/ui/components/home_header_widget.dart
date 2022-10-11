import 'package:flutter/material.dart';
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
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            onPressed: () {},
            splashColor: Colors.transparent,
            icon: const Icon(
              Icons.menu_outlined,
            ),
          ),
          widget.centerWidget,
          // const BrandTitleWidget(
          //   size: SizeVarient.medium,
          // ),
          const SearchIconWidget(),
        ],
      ),
    );
  }
}
