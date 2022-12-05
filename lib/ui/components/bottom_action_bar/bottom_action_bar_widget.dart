import 'dart:ui';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/bottom_action_bar/action_bar_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';

class BottomActionBarWidget extends StatelessWidget {
  final String? text;
  final List<Widget>? iconButtons;
  final Widget expandedMenu;
  final SelectedFiles? selectedFiles;
  final VoidCallback? onCancel;

  BottomActionBarWidget({
    required this.expandedMenu,
    this.selectedFiles,
    this.text,
    this.iconButtons,
    this.onCancel,
    super.key,
  });

  final ExpandableController _expandableController =
      ExpandableController(initialExpanded: false);

  @override
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    //todo : restrict width of column
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurBase, sigmaY: blurBase),
        child: Container(
          color: colorScheme.backdropBase,
          padding: EdgeInsets.only(
            top: 4,
            bottom: (selectedFiles?.files.isNotEmpty) ?? false ? 24 : 36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpandableNotifier(
                controller: _expandableController,
                child: ExpandablePanel(
                  theme: _getExpandableTheme(),
                  header: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: text == null ? 12 : 0,
                    ),
                    child: ActionBarWidget(
                      selectedFiles: selectedFiles,
                      text: text,
                      iconButtons: _iconButtons(context),
                    ),
                  ),
                  expanded: expandedMenu,
                  collapsed: const SizedBox.shrink(),
                  controller: _expandableController,
                ),
              ),
              GestureDetector(
                onTap: () {
                  //unselect all files here
                  //or collapse the expansion panel
                  onCancel?.call();
                  _expandableController.value = false;
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
        ),
      ),
    );
  }

  List<Widget> _iconButtons(BuildContext context) {
    final iconButtonsWithExpansionIcon = <Widget?>[
      ...?iconButtons,
      ExpansionIconWidget(expandableController: _expandableController)
    ];
    iconButtonsWithExpansionIcon.removeWhere((element) => element == null);
    return iconButtonsWithExpansionIcon as List<Widget>;
  }

  ExpandableThemeData _getExpandableTheme() {
    return const ExpandableThemeData(
      hasIcon: false,
      useInkWell: false,
      tapBodyToCollapse: false,
      tapBodyToExpand: false,
      tapHeaderToExpand: false,
      animationDuration: Duration(milliseconds: 400),
    );
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
