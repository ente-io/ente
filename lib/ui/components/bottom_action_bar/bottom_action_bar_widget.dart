import 'dart:ui';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/bottom_action_bar/action_bar_widget.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';

class BottomActionBarWidget extends StatelessWidget {
  final String? text;
  final List<Widget>? iconButtons;
  final Widget expandedMenu;
  final SelectedFiles? selectedFiles;
  final VoidCallback? onCancel;
  final bool hasSmallerBottomPadding;
  final GalleryType type;

  BottomActionBarWidget({
    required this.expandedMenu,
    required this.hasSmallerBottomPadding,
    required this.type,
    this.selectedFiles,
    this.text,
    this.iconButtons,
    this.onCancel,
    super.key,
  });

  final ExpandableController _expandableController =
      ExpandableController(initialExpanded: false);

  @override
  Widget build(BuildContext context) {
    final widthOfScreen = MediaQuery.of(context).size.width;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final double leftRightPadding = widthOfScreen > restrictedMaxWidth
        ? (widthOfScreen - restrictedMaxWidth) / 2
        : 0;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurFaint, sigmaY: blurFaint),
        child: Container(
          color: colorScheme.backdropBase,
          padding: EdgeInsets.only(
            top: 4,
            bottom: hasSmallerBottomPadding ? 24 : 36,
            right: leftRightPadding,
            left: leftRightPadding,
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
                      galleryType: type,
                      text: text,
                      iconButtons: _iconButtons(context),
                    ),
                  ),
                  expanded: expandedMenu,
                  collapsed: const SizedBox.shrink(),
                  controller: _expandableController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    onCancel?.call();
                    _expandableController.value = false;
                  },
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
    final iconButtonsWithExpansionIcon = <Widget>[
      ...?iconButtons,
      ExpansionIconWidget(expandableController: _expandableController)
    ];
    return iconButtonsWithExpansionIcon;
  }

  ExpandableThemeData _getExpandableTheme() {
    return const ExpandableThemeData(
      hasIcon: false,
      useInkWell: false,
      tapBodyToCollapse: false,
      tapBodyToExpand: false,
      tapHeaderToExpand: false,
      animationDuration: Duration(milliseconds: 400),
      crossFadePoint: 0.5,
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
    final iconColor = getEnteColorScheme(context).blurStrokeBase;
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
              iconColor: iconColor,
            )
          : IconButtonWidget(
              key: const ValueKey<bool>(true),
              onTap: () {
                widget.expandableController.value = true;
                setState(() {});
              },
              icon: Icons.more_horiz_outlined,
              iconButtonType: IconButtonType.primary,
              iconColor: iconColor,
            ),
    );
  }

  _expandableListener() {
    if (mounted) {
      setState(() {});
    }
  }
}
