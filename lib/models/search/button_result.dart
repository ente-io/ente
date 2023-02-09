import "package:photos/ui/components/button_widget.dart";

class ButtonResult {
  final ButtonAction? action;
  final Exception? exception;
  ButtonResult({required this.action, this.exception});
}
