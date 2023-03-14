import "package:flutter/material.dart";
import "package:photos/ui/components/divider_widget.dart";

class FileDetialsDividerWidget extends StatelessWidget {
  const FileDetialsDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 15.5),
      child: DividerWidget(
        dividerType: DividerType.menu,
        divColorHasBlur: false,
      ),
    );
  }
}
