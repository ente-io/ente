import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/service_locator.dart';
import "package:photos/services/wrapped/wrapped_service.dart";
import "package:photos/ui/home/memories/memories_widget.dart";
import 'package:photos/ui/home/status_bar_widget.dart';
import "package:photos/ui/wrapped/rewind_banner.dart";

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({
    super.key,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final Logger _logger = Logger("Header");
  late WrappedEntryState _wrappedState;

  @override
  void initState() {
    super.initState();
    _wrappedState = wrappedService.state;
    wrappedService.stateListenable.addListener(_onWrappedStateChanged);
  }

  @override
  void dispose() {
    wrappedService.stateListenable.removeListener(_onWrappedStateChanged);
    super.dispose();
  }

  void _onWrappedStateChanged() {
    final WrappedEntryState next = wrappedService.state;
    if (!mounted) {
      return;
    }
    if (_wrappedState == next) {
      return;
    }
    setState(() {
      _wrappedState = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building header widget");
    final bool showWrappedBanner = wrappedService.shouldShowHomeBanner;
    final List<Widget> children = <Widget>[
      const StatusBarWidget(),
      const MemoriesWidget(),
    ];
    if (showWrappedBanner) {
      children.add(RewindBanner(state: _wrappedState));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
