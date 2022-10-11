import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

typedef OnChangedCallBack = void Function(bool);

class ToggleSwitchWidget extends StatefulWidget {
  final bool value;
  final OnChangedCallBack onChanged;
  const ToggleSwitchWidget({
    required this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<ToggleSwitchWidget> createState() => _ToggleSwitchWidgetState();
}

class _ToggleSwitchWidgetState extends State<ToggleSwitchWidget> {
  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 30,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Switch.adaptive(
            activeColor: enteColorScheme.primary400,
            inactiveTrackColor: enteColorScheme.fillMuted,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            value: widget.value,
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
