import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/models/execution_states.dart';
import 'package:ente_auth/models/typedefs.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:ente_auth/utils/debouncer.dart';
import 'package:flutter/material.dart';

typedef OnChangedCallBack = void Function(bool);

class ToggleSwitchWidget extends StatefulWidget {
  final BoolCallBack value;
  final FutureVoidCallback onChanged;
  const ToggleSwitchWidget({
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  State<ToggleSwitchWidget> createState() => _ToggleSwitchWidgetState();
}

class _ToggleSwitchWidgetState extends State<ToggleSwitchWidget> {
  bool? toggleValue;
  ExecutionState executionState = ExecutionState.idle;
  final _debouncer = Debouncer(const Duration(milliseconds: 300));

  @override
  void initState() {
    toggleValue = widget.value.call();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    final Widget stateIcon = _stateIcon(enteColorScheme);

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 175),
            switchInCurve: Curves.easeInExpo,
            switchOutCurve: Curves.easeOutExpo,
            child: stateIcon,
          ),
        ),
        SizedBox(
          height: 31,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch.adaptive(
              activeColor: enteColorScheme.primary400,
              activeTrackColor: enteColorScheme.primary300,
              inactiveTrackColor: enteColorScheme.fillMuted,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: toggleValue ?? false,
              onChanged: (negationOfToggleValue) async {
                setState(() {
                  toggleValue = negationOfToggleValue;
                  //start showing inProgress statu icons if toggle takes more than debounce time
                  _debouncer.run(
                    () => Future(
                      () {
                        setState(() {
                          executionState = ExecutionState.inProgress;
                        });
                      },
                    ),
                  );
                });
                final Stopwatch stopwatch = Stopwatch()..start();
                await widget.onChanged.call().onError(
                      (error, stackTrace) => _debouncer.cancelDebounce(),
                    );
                //for toggle feedback on short unsuccessful onChanged
                await _feedbackOnUnsuccessfulToggle(stopwatch);
                //debouncer gets canceled if onChanged takes less than debounce time
                _debouncer.cancelDebounce();

                final newValue = widget.value.call();
                setState(() {
                  if (toggleValue == newValue) {
                    if (executionState == ExecutionState.inProgress) {
                      executionState = ExecutionState.successful;
                      Future.delayed(const Duration(seconds: 2), () {
                        setState(() {
                          executionState = ExecutionState.idle;
                        });
                      });
                    }
                  } else {
                    toggleValue = !toggleValue!;
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
      return const SizedBox(width: 24);
    } else if (executionState == ExecutionState.inProgress) {
      return EnteLoadingWidget(
        color: enteColorScheme.strokeMuted,
      );
    } else if (executionState == ExecutionState.successful) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Icon(
          Icons.check_outlined,
          size: 22,
          color: enteColorScheme.primary500,
        ),
      );
    } else {
      return const SizedBox(width: 24);
    }
  }

  Future<void> _feedbackOnUnsuccessfulToggle(Stopwatch stopwatch) async {
    final timeElapsed = stopwatch.elapsedMilliseconds;
    if (timeElapsed < 200) {
      await Future.delayed(
        Duration(milliseconds: 200 - timeElapsed),
      );
    }
  }
}
