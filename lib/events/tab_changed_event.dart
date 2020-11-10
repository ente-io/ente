import 'package:sentry/sentry.dart';

class TabChangedEvent extends Event {
  final int selectedIndex;
  final TabChangedEventSource source;

  TabChangedEvent(
    this.selectedIndex,
    this.source,
  );
}

enum TabChangedEventSource {
  tab_bar,
  page_view,
  collections_page,
}
