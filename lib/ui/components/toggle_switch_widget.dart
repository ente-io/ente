import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class ToggleSwitch extends StatefulWidget {
  final bool value;
  final Function onChanged;
  const ToggleSwitch({required this.value, required this.onChanged, Key? key})
      : super(key: key);

  @override
  State<ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<ToggleSwitch> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch.adaptive(
          activeColor:
              Theme.of(context).colorScheme.enteTheme.colorScheme.primary400,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: widget.value,
          onChanged: (value) async {
            widget.onChanged;
            setState(() {});
          },
        ),
      ),
    );
  }
}
