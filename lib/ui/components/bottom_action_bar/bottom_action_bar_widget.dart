import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    //todo : restrict width of column
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
          GestureDetector(
            onTap: () {
              //unselect all files here
              //or collapse the expansion panel
              _expandableController.value = false;
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                child: Text(
                  "Cancel",
                  style: textTheme.bodyBold
                      .copyWith(color: colorScheme.blurTextBase),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _iconButtons() {
    final iconButtons = <Widget?>[
      ...?widget.iconButtons,
      ExpansionIconWidget(expandableController: _expandableController)
    ];
    iconButtons.removeWhere((element) => element == null);
    return iconButtons as List<Widget>;
  }
}

class ExpansionIconWidget extends StatefulWidget {
  final ExpandableController expandableController;
  const ExpansionIconWidget({required this.expandableController, super.key});

  @override
  State<ExpansionIconWidget> createState() => _ExpansionIconWidgetState();
}

class _ExpansionIconWidgetState extends State<ExpansionIconWidget> {
  @override
  void initState() {
    widget.expandableController.addListener(_expandableListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.expandableController.removeListener(_expandableListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOutExpo,
      child: widget.expandableController.value
          ? IconButtonWidget(
              key: const ValueKey<bool>(false),
              onTap: () {
                widget.expandableController.value = false;
                setState(() {});
              },
              icon: Icons.expand_more_outlined,
              iconButtonType: IconButtonType.primary,
            )
          : IconButtonWidget(
              key: const ValueKey<bool>(true),
              onTap: () {
                widget.expandableController.value = true;
                setState(() {});
              },
              icon: Icons.more_horiz_outlined,
              iconButtonType: IconButtonType.primary,
            ),
    );
  }

  _expandableListener() {
    if (mounted) {
      setState(() {});
    }
  }
}
