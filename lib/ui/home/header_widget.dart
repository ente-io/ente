import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/home/memories_widget.dart';
import 'package:photos/ui/home/status_bar_widget.dart';

class HeaderWidget extends StatelessWidget {
  static const _memoriesWidget = MemoriesWidget();
  static const _statusBarWidget = StatusBarWidget();

  const HeaderWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Logger("Header").info("Building header widget");
    const list = [
      _statusBarWidget,
      _memoriesWidget,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
    );
  }
}
