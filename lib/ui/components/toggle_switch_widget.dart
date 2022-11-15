import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/debouncer.dart';

enum ExecutionState {
  idle,
  inProgress,
  successful,
}

typedef OnChangedCallBack = Future<void> Function();
typedef FutureValueCallBack = Future<bool> Function();

class ToggleSwitchWidget extends StatefulWidget {
  final FutureValueCallBack value;
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
  late Future<bool> futureToggleValue;
  late bool toggleValue;
  ExecutionState executionState = ExecutionState.idle;
  final _debouncer = Debouncer(const Duration(milliseconds: 300));
  @override
  void initState() {
    futureToggleValue = widget.value.call();
//need to assign correct intiial value of toggleValue here
    toggleValue = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    final Widget stateIcon = _stateIcon(enteColorScheme);

    return FutureBuilder(
      future: futureToggleValue,
      builder: (context, snapshot) {
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
                  inactiveTrackColor: enteColorScheme.fillMuted,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: toggleValue,
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
                    await widget.onChanged.call();
                    //for toggle feedback on short unsuccessful onChanged
                    await _feedbackOnUnsuccessfulToggle(stopwatch);
                    //debouncer gets canceled if onChanged takes less than debounce time
                    _debouncer.cancelDebounce();

                    widget.value.call().then((newValue) {
                      setState(() {
                        //if onchanged on toggle is successful
                        // print('here');
                        // print(toggleValue);
                        // print("newValue : $newValue");
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
                          toggleValue = !toggleValue;
                          executionState = ExecutionState.idle;
                        }
                      });
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
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
