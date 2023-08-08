import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/effects.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/bottom_action_bar/action_bar_widget.dart';

class BottomActionBarWidget extends StatelessWidget {
  final Widget expandedMenu;
  final SelectedFiles? selectedFiles;
  final VoidCallback? onCancel;
  final bool hasSmallerBottomPadding;
  final Color? backgroundColor;

  const BottomActionBarWidget({
    required this.expandedMenu,
    required this.hasSmallerBottomPadding,
    this.selectedFiles,
    this.onCancel,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final widthOfScreen = MediaQuery.of(context).size.width;
    final colorScheme = getEnteColorScheme(context);
    final double leftRightPadding = widthOfScreen > restrictedMaxWidth
        ? (widthOfScreen - restrictedMaxWidth) / 2
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.backgroundElevated2,
        boxShadow: shadowFloatFaintLight,
      ),
      padding: EdgeInsets.only(
        top: 4,
        bottom: hasSmallerBottomPadding ? 24 : 36,
        right: leftRightPadding,
        left: leftRightPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionBarWidget(
            selectedFiles: selectedFiles,
            onCancel: onCancel,
          ),
        ],
      ),
    );
  }
}
