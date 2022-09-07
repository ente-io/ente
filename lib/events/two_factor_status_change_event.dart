// @dart=2.9

import 'package:photos/events/event.dart';

class TwoFactorStatusChangeEvent extends Event {
  final bool status;

  TwoFactorStatusChangeEvent(this.status);
}
