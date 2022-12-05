import 'package:flutter/material.dart';
import 'package:photos/ui/components/blur_menu_item_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';

class ExpandedMenuWidget extends StatelessWidget {
  final List<BlurMenuItemWidget> items;
  final List<int> groupingOrder;
  const ExpandedMenuWidget({
    required this.items,

    /// To specify the grouping of items. Eg: [2,2] for 2 sections with 2 items
    /// each, [4,1,2] for 3 sections with 4, 1 and 2 items respectively.
    /// Make sure sum of ints in this.groupingOrder is equal to length of this.items
    required this.groupingOrder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 48;
    const double whiteSpaceBetweenSections = 16;
    const double dividerHeightBetweenItems = 1;
    int totalItemIndex = 0;
    int numberOfDividers = 0;

    for (int group in groupingOrder) {
      //no divider if there is only one item in the section/group
      if (group != 1) {
        numberOfDividers += (group - 1);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SizedBox(
        height: (itemHeight * items.length) +
            (dividerHeightBetweenItems * numberOfDividers) +
            (whiteSpaceBetweenSections * (groupingOrder.length - 1)),
        child: ListView.separated(
          padding: const EdgeInsets.all(0),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, sectionIndex) {
            return ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: SizedBox(
                height: itemHeight * groupingOrder[sectionIndex] +
                    (dividerHeightBetweenItems *
                        (groupingOrder[sectionIndex] - 1)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, _) {
                    return items[totalItemIndex++];
                  },
                  separatorBuilder: (context, index) {
                    return const DividerWidget(
                      dividerType: DividerType.bottomBar,
                    );
                  },
                  itemCount: groupingOrder[sectionIndex],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) {
            return const SizedBox(height: whiteSpaceBetweenSections);
          },
          itemCount: groupingOrder.length,
        ),
      ),
    );
  }
}
