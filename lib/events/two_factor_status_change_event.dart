import 'package:photos/events/event.dart';

class TwoFactorStatusChangeEvent extends Event {
  final bool status;

  TwoFactorStatusChangeEvent(this.status);
}
