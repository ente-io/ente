import 'package:photos/ui/components/buttons/button_widget.dart';

class ButtonResult {
  ///action can be null when action for the button that is returned when popping
  ///the widget (dialog, actionSheet) which uses a ButtonWidget isn't
  ///relevant/useful and so is not assigned a value when an instance of
  ///ButtonWidget is created.
  final ButtonAction? action;
  final Exception? exception;
  ButtonResult([this.action, this.exception]);
}
