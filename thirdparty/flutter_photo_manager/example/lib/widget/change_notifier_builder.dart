import 'package:flutter/material.dart';

typedef ChangeNotifierWidgetBuilder<T extends ChangeNotifier> = Widget Function(
  BuildContext context,
  T value,
);

class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ChangeNotifierBuilder({
    Key? key,
    required this.builder,
    required this.value,
  }) : super(key: key);

  final ChangeNotifierWidgetBuilder<T> builder;
  final T value;

  @override
  _ChangeNotifierBuilderState createState() => _ChangeNotifierBuilderState();
}

class _ChangeNotifierBuilderState extends State<ChangeNotifierBuilder> {
  @override
  void initState() {
    super.initState();
    widget.value.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.value.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.value);
  }
}
