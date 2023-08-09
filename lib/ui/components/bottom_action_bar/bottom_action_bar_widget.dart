import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/effects.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/bottom_action_bar/action_bar_widget.dart';
import "package:photos/ui/components/divider_widget.dart";

class BottomActionBarWidget extends StatelessWidget {
  final Widget expandedMenu;
  final SelectedFiles? selectedFiles;
  final VoidCallback? onCancel;
  final Color? backgroundColor;

  const BottomActionBarWidget({
    required this.expandedMenu,
    this.selectedFiles,
    this.onCancel,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final widthOfScreen = MediaQuery.of(context).size.width;
    final colorScheme = getEnteColorScheme(context);
    final double leftRightPadding = widthOfScreen > restrictedMaxWidth
        ? (widthOfScreen - restrictedMaxWidth) / 2
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.backgroundElevated2,
        boxShadow: shadowFloatFaintLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: EdgeInsets.only(
        top: 4,
        bottom: bottomPadding,
        right: leftRightPadding,
        left: leftRightPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SelectionOptionButton(
                  name: "Share link",
                  icon: Icons.link_outlined,
                ),
                SelectionOptionButton(name: "Add to album", icon: Icons.add),
                SelectionOptionButton(
                  name: "Delete",
                  icon: Icons.delete_outline,
                ),
                SelectionOptionButton(
                  name: "Hide",
                  icon: Icons.visibility_off_outlined,
                ),
                SelectionOptionButton(
                  name: "Archive",
                  icon: Icons.archive_outlined,
                ),
                SelectionOptionButton(
                  name: "Favorite",
                  icon: Icons.favorite_border_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const DividerWidget(dividerType: DividerType.bottomBar),
          ActionBarWidget(
            selectedFiles: selectedFiles,
            onCancel: onCancel,
          ),
          // const SizedBox(height: 2)
        ],
      ),
    );
  }
}

class SelectionOptionButton extends StatefulWidget {
  final String name;
  final IconData icon;
  const SelectionOptionButton({
    required this.name,
    required this.icon,
    super.key,
  });

  @override
  State<SelectionOptionButton> createState() => _SelectionOptionButtonState();
}

class _SelectionOptionButtonState extends State<SelectionOptionButton> {
  Color? backgroundColor;
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          backgroundColor = colorScheme.fillFaintPressed;
        });
      },
      onTapUp: (details) {
        setState(() {
          backgroundColor = null;
        });
      },
      onTapCancel: () {
        setState(() {
          backgroundColor = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 24,
                  color: getEnteColorScheme(context).textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: getEnteTextTheme(context).miniMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
