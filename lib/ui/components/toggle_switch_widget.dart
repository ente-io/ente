import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

typedef OnChangedCallBack = Future<void> Function();
typedef ValueCallBack = bool Function();

class ToggleSwitchWidget extends StatefulWidget {
  final ValueCallBack value;
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
  late bool toggleValue;
  @override
  void initState() {
    toggleValue = widget.value.call();
    super.initState();
  }

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
            value: toggleValue,
            onChanged: (value) async {
              setState(() {
                toggleValue = value;
              });
              await widget.onChanged.call();
              setState(() {
                toggleValue = widget.value.call();
              });
            },
          ),
        ),
      ),
    );
  }
}
