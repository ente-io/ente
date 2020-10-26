import 'package:sentry/sentry.dart';

class TabChangedEvent extends Event {
  final selectedIndex;

  TabChangedEvent(this.selectedIndex);
}
