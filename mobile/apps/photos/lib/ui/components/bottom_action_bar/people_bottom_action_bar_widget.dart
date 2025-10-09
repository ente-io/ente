import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/actions/people_selection_action_widget.dart";

class PeopleBottomActionBarWidget extends StatelessWidget {
  final SelectedPeople selectedPeople;
  final VoidCallback? onCancel;
  final bool isCollapsed;

  const PeopleBottomActionBarWidget(
    this.selectedPeople, {
    this.isCollapsed = false,
    super.key,
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
        color: colorScheme.backgroundElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
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
          PeopleSelectionActionWidget(
            selectedPeople,
            isCollapsed: isCollapsed,
          ),
        ],
      ),
    );
  }
}
