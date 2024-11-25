import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import "package:photos/ui/home/memories/memories_widget.dart";
import 'package:photos/ui/home/status_bar_widget.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Logger("Header").info("Building header widget");
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBarWidget(),
        MemoriesWidget(),
      ],
    );
  }
}
