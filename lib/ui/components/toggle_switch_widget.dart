import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/common/loading_widget.dart';

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
  late bool inProgress;
  @override
  void initState() {
    toggleValue = widget.value.call();
    inProgress = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    return Row(
      children: [
        inProgress
            ? EnteLoadingWidget(color: enteColorScheme.strokeMuted)
            : const SizedBox.shrink(),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch.adaptive(
              activeColor: enteColorScheme.primary400,
              inactiveTrackColor: enteColorScheme.fillMuted,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: toggleValue,
              onChanged: (negationOfToggleValue) async {
                setState(() {
                  toggleValue = negationOfToggleValue;
                  inProgress = true;
                });
                await widget.onChanged.call();
                setState(() {
                  final newValue = widget.value.call();
                  toggleValue = newValue;
                  inProgress = false;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
