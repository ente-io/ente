import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/common/loading_widget.dart';

enum ExecutionState {
  idle,
  inProgress,
  successful,
}

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
  late ExecutionState executionState;
  @override
  void initState() {
    toggleValue = widget.value.call();
    executionState = ExecutionState.idle;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    final Widget stateIcon = _stateIcon(enteColorScheme);

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInExpo,
          switchOutCurve: Curves.easeOutExpo,
          child: stateIcon,
        ),
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
                  executionState = ExecutionState.inProgress;
                });
                await widget.onChanged.call();
                setState(() {
                  final newValue = widget.value.call();
                  toggleValue = newValue;
                  if (toggleValue == newValue) {
                    executionState = ExecutionState.successful;
                    Future.delayed(const Duration(seconds: 1), () {
                      setState(() {
                        executionState = ExecutionState.idle;
                      });
                    });
                  } else {
                    executionState = ExecutionState.idle;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _stateIcon(enteColorScheme) {
    if (executionState == ExecutionState.idle) {
      return const SizedBox.shrink();
    } else if (executionState == ExecutionState.inProgress) {
      return EnteLoadingWidget(
        color: enteColorScheme.strokeMuted,
      );
    } else if (executionState == ExecutionState.successful) {
      return Icon(
        Icons.check_outlined,
        color: enteColorScheme.primary500,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
