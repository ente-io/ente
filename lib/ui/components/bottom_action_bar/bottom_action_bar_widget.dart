import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ui/components/bottom_action_bar/action_bar_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';

class BottomActionBarWidget extends StatefulWidget {
  final Widget? textWidget;
  final List<Widget>? iconButtons;
  final Widget expandedMenu;
  const BottomActionBarWidget({
    required this.expandedMenu,
    this.textWidget,
    this.iconButtons,
    super.key,
  });

  @override
  State<BottomActionBarWidget> createState() => _BottomActionBarWidgetState();
}

class _BottomActionBarWidgetState extends State<BottomActionBarWidget> {
  final ExpandableController _expandableController =
      ExpandableController(initialExpanded: false);

  @override
  Widget build(BuildContext context) {
    //todo : restric width of column
    return Container(
      padding: const EdgeInsets.only(top: 4, bottom: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpandableNotifier(
            controller: _expandableController,
            child: ExpandablePanel(
              theme: getExpandableTheme(context),
              header: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.textWidget == null ? 12 : 0,
                ),
                child: ActionBarWidget(
                  textWidget: widget.textWidget,
                  iconButtons: _iconButtons(),
                ),
              ),
              expanded: widget.expandedMenu,
              collapsed: const SizedBox.shrink(),
              controller: _expandableController,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _iconButtons() {
    final iconButtons = <Widget?>[
      ...?widget.iconButtons,
      IconButtonWidget(
        onTap: () {
          _expandableController.value = !_expandableController.value;
        },
        icon: Icons.more_horiz_outlined,
        iconButtonType: IconButtonType.primary,
      ),
    ];
    iconButtons.removeWhere((element) => element == null);
    return iconButtons as List<Widget>;
  }
}
