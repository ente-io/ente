import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/models/execution_states.dart';
import 'package:photos/models/typedefs.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/debouncer.dart';
import 'package:photos/utils/separators_util.dart';

class TextInputWidget extends StatefulWidget {
  final String? label;
  final String? message;
  final String? hintText;
  final IconData? prefixIcon;
  final String? initialValue;
  final Alignment? alignMessage;
  final bool? autoFocus;
  final int? maxLength;
  final double borderRadius;

  ///TextInputWidget will listen to this notifier and executes onSubmit when
  ///notified.
  final ValueNotifier? submitNotifier;

  ///TextInputWidget will listen to this notifier and clears and unfocuses the
  ///textFiled when notified.
  final ValueNotifier? cancelNotifier;
  final bool alwaysShowSuccessState;
  final bool showOnlyLoadingState;
  final FutureVoidCallbackParamStr? onSubmit;
  final VoidCallbackParamStr? onChange;
  final bool popNavAfterSubmission;
  final bool shouldSurfaceExecutionStates;
  final TextCapitalization? textCapitalization;
  final bool isPasswordInput;
  final bool isClearable;
  final bool shouldUnfocusOnClearOrSubmit;
  final FocusNode? focusNode;
  const TextInputWidget({
    this.onSubmit,
    this.onChange,
    this.label,
    this.message,
    this.hintText,
    this.prefixIcon,
    this.initialValue,
    this.alignMessage,
    this.autoFocus,
    this.maxLength,
    this.submitNotifier,
    this.cancelNotifier,
    this.alwaysShowSuccessState = false,
    this.showOnlyLoadingState = false,
    this.popNavAfterSubmission = false,
    this.shouldSurfaceExecutionStates = true,
    this.textCapitalization = TextCapitalization.none,
    this.isPasswordInput = false,
    this.isClearable = false,
    this.shouldUnfocusOnClearOrSubmit = false,
    this.borderRadius = 8,
    this.focusNode,
    super.key,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  ExecutionState executionState = ExecutionState.idle;
  final _textController = TextEditingController();
  final _debouncer = Debouncer(const Duration(milliseconds: 300));
  late final ValueNotifier<bool> _obscureTextNotifier;

  ///This is to pass if the TextInputWidget is in a dialog and an error is
  ///thrown in executing onSubmit by passing it as arg in Navigator.pop()
  Exception? _exception;

  @override
  void initState() {
    widget.submitNotifier?.addListener(_onSubmit);
    widget.cancelNotifier?.addListener(_onCancel);

    if (widget.initialValue != null) {
      _textController.value = TextEditingValue(
        text: widget.initialValue!,
        selection: TextSelection.collapsed(offset: widget.initialValue!.length),
      );
    }
    if (widget.onChange != null) {
      _textController.addListener(() {
        widget.onChange!.call(_textController.text);
      });
    }
    _obscureTextNotifier = ValueNotifier(widget.isPasswordInput);
    _obscureTextNotifier.addListener(_safeRefresh);
    super.initState();
  }

  @override
  void dispose() {
    widget.submitNotifier?.removeListener(_onSubmit);
    widget.cancelNotifier?.removeListener(_onCancel);
    _obscureTextNotifier.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (executionState == ExecutionState.successful) {
      Future.delayed(Duration(seconds: widget.popNavAfterSubmission ? 1 : 2),
          () {
        setState(() {
          executionState = ExecutionState.idle;
        });
      });
    }
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    var textInputChildren = <Widget>[];
    if (widget.label != null) {
      textInputChildren.add(Text(widget.label!));
    }
    textInputChildren.add(
      ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
        child: Material(
          child: TextFormField(
            textCapitalization: widget.textCapitalization!,
            autofocus: widget.autoFocus ?? false,
            controller: _textController,
            focusNode: widget.focusNode,
            inputFormatters: widget.maxLength != null
                ? [LengthLimitingTextInputFormatter(50)]
                : null,
            obscureText: _obscureTextNotifier.value,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: textTheme.body.copyWith(color: colorScheme.textMuted),
              filled: true,
              fillColor: colorScheme.fillFaint,
              contentPadding: const EdgeInsets.fromLTRB(
                12,
                12,
                0,
                12,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.strokeFaint),
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 175),
                  switchInCurve: Curves.easeInExpo,
                  switchOutCurve: Curves.easeOutExpo,
                  child: SuffixIconWidget(
                    key: ValueKey(executionState),
                    executionState: executionState,
                    shouldSurfaceExecutionStates:
                        widget.shouldSurfaceExecutionStates,
                    obscureTextNotifier: _obscureTextNotifier,
                    isPasswordInput: widget.isPasswordInput,
                    textController: _textController,
                    isClearable: widget.isClearable,
                    shouldUnfocusOnClearOrSubmit:
                        widget.shouldUnfocusOnClearOrSubmit,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                maxHeight: 44,
                maxWidth: 44,
                minHeight: 44,
                minWidth: 44,
              ),
              suffixIconConstraints: const BoxConstraints(
                maxHeight: 24,
                maxWidth: 48,
                minHeight: 24,
                minWidth: 48,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: colorScheme.strokeMuted,
                    )
                  : null,
            ),
            onEditingComplete: () {
              _onSubmit();
            },
          ),
        ),
      ),
    );
    if (widget.message != null) {
      textInputChildren.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: widget.alignMessage ?? Alignment.centerLeft,
            child: Text(
              widget.message!,
              style: textTheme.small.copyWith(color: colorScheme.textMuted),
            ),
          ),
        ),
      );
    }
    textInputChildren =
        addSeparators(textInputChildren, const SizedBox(height: 4));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: textInputChildren,
    );
  }

  void _safeRefresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSubmit() async {
    _debouncer.run(
      () => Future(() {
        setState(() {
          executionState = ExecutionState.inProgress;
        });
      }),
    );
    if (widget.shouldUnfocusOnClearOrSubmit) {
      FocusScope.of(context).unfocus();
    }
    try {
      await widget.onSubmit!.call(_textController.text);
    } catch (e) {
      executionState = ExecutionState.error;
      _debouncer.cancelDebounce();
      _exception = e as Exception;
      if (!widget.popNavAfterSubmission) {
        rethrow;
      }
    }
    widget.alwaysShowSuccessState && _debouncer.isActive()
        ? executionState = ExecutionState.successful
        : null;
    _debouncer.cancelDebounce();
    if (executionState == ExecutionState.successful) {
      setState(() {});
    }

    // when the time taken by widget.onSubmit is approximately equal to the debounce
    // time, the callback is getting executed when/after the if condition
    // below is executing/executed which results in execution state stuck at
    // idle state. This Future is for delaying the execution of the if
    // condition so that the calback in the debouncer finishes execution before.
    await Future.delayed(const Duration(milliseconds: 5));
    if (executionState == ExecutionState.inProgress ||
        executionState == ExecutionState.error) {
      if (executionState == ExecutionState.inProgress) {
        if (mounted) {
          if (widget.showOnlyLoadingState) {
            setState(() {
              executionState = ExecutionState.idle;
            });
            _popNavigatorStack(context);
          } else {
            setState(() {
              executionState = ExecutionState.successful;
              Future.delayed(
                  Duration(
                    seconds: widget.shouldSurfaceExecutionStates
                        ? (widget.popNavAfterSubmission ? 1 : 2)
                        : 0,
                  ), () {
                widget.popNavAfterSubmission
                    ? _popNavigatorStack(context)
                    : null;
                if (mounted) {
                  setState(() {
                    executionState = ExecutionState.idle;
                  });
                }
              });
            });
          }
        }
      }
      if (executionState == ExecutionState.error) {
        setState(() {
          executionState = ExecutionState.idle;
          widget.popNavAfterSubmission
              ? Future.delayed(
                  const Duration(seconds: 0),
                  () => _popNavigatorStack(context, e: _exception),
                )
              : null;
        });
      }
    } else {
      if (widget.popNavAfterSubmission) {
        Future.delayed(
          Duration(seconds: widget.alwaysShowSuccessState ? 1 : 0),
          () => _popNavigatorStack(context),
        );
      }
    }
  }

  void _onCancel() {
    _textController.clear();
    FocusScope.of(context).unfocus();
  }

  void _popNavigatorStack(BuildContext context, {Exception? e}) {
    Navigator.of(context).canPop() ? Navigator.of(context).pop(e) : null;
  }
}

//todo: Add clear and custom icon for suffic icon
class SuffixIconWidget extends StatelessWidget {
  final ExecutionState executionState;
  final bool shouldSurfaceExecutionStates;
  final TextEditingController textController;
  final ValueNotifier? obscureTextNotifier;
  final bool isPasswordInput;
  final bool isClearable;
  final bool shouldUnfocusOnClearOrSubmit;

  const SuffixIconWidget({
    required this.executionState,
    required this.shouldSurfaceExecutionStates,
    required this.textController,
    this.obscureTextNotifier,
    this.isPasswordInput = false,
    this.isClearable = false,
    this.shouldUnfocusOnClearOrSubmit = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget trailingWidget;
    final colorScheme = getEnteColorScheme(context);
    if (executionState == ExecutionState.idle ||
        !shouldSurfaceExecutionStates) {
      if (isClearable) {
        trailingWidget = GestureDetector(
          onTap: () {
            textController.clear();
            if (shouldUnfocusOnClearOrSubmit) {
              FocusScope.of(context).unfocus();
            }
          },
          child: Icon(
            Icons.cancel_rounded,
            color: colorScheme.strokeMuted,
          ),
        );
      } else if (isPasswordInput) {
        assert(obscureTextNotifier != null);
        trailingWidget = GestureDetector(
          onTap: () {
            obscureTextNotifier!.value = !obscureTextNotifier!.value;
          },
          child: Icon(
            obscureTextNotifier!.value
                ? Icons.visibility_off_outlined
                : Icons.visibility,
            color: obscureTextNotifier!.value ? colorScheme.strokeMuted : null,
          ),
        );
      } else {
        trailingWidget = const SizedBox.shrink();
      }
    } else if (executionState == ExecutionState.inProgress) {
      trailingWidget = EnteLoadingWidget(
        color: colorScheme.strokeMuted,
      );
    } else if (executionState == ExecutionState.successful) {
      trailingWidget = Icon(
        Icons.check_outlined,
        size: 22,
        color: colorScheme.primary500,
      );
    } else {
      trailingWidget = const SizedBox.shrink();
    }
    return trailingWidget;
  }
}
