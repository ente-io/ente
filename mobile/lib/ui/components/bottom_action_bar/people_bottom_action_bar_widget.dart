import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/bottom_action_bar/people_action_bar_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/viewer/actions/people_selection_action_widget.dart";

class PeopleBottomActionBarWidget extends StatelessWidget {
  final SelectedPeople selectedPeople;
  final VoidCallback? onCancel;
  final Color? backgroundColor;

  const PeopleBottomActionBarWidget(
    this.selectedPeople, {
    super.key,
    this.backgroundColor,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final widthOfScreen = MediaQuery.sizeOf(context).width;
    final colorScheme = getEnteColorScheme(context);
    final double leftRightPadding = widthOfScreen > restrictedMaxWidth
        ? (widthOfScreen - restrictedMaxWidth) / 2
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.backgroundElevated2,
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
          const SizedBox(height: 8),
          PeopleSelectionActionWidget(selectedPeople),
          const DividerWidget(dividerType: DividerType.bottomBar),
          PeopleActionBarWidget(
            selectedPeople: selectedPeople,
            onCancel: onCancel,
          ),
        ],
      ),
    );
  }
}
