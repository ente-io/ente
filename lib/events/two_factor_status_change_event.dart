import 'package:photos/core/configuration.dart';
import 'package:photos/events/event.dart';

class TwoFactorStatusChangeEvent extends Event {
  final bool status;

  TwoFactorStatusChangeEvent(this.status) {
    Configuration.instance.setTwoFactor(value: status);
  }
}
