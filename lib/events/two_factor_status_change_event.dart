import 'package:photos/events/event.dart';
import 'package:photos/services/user_service.dart';

class TwoFactorStatusChangeEvent extends Event {
  final bool status;

  TwoFactorStatusChangeEvent(this.status) {
    UserService.instance.setTwoFactor(value: status);
  }
}
