import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/utils/debouncer.dart';
import 'package:photos/utils/separators_util.dart';

enum ExecutionState {
  idle,
  inProgress,
  error,
  successful;
}

class TextInputWidget extends StatefulWidget {
  final String? label;
  final String? message;
  final String? hintText;
  final IconData? prefixIcon;
  final String? initialValue;
  final Alignment? alignMessage;
  final bool? autoFocus;
  final int? maxLength;
  final ValueNotifier? submitNotifier;
  final bool alwaysShowSuccessState;
  final bool showOnlyLoadingState;
  final FutureVoidCallbackParamStr onSubmit;
  const TextInputWidget({
    required this.onSubmit,
    this.label,
    this.message,
    this.hintText,
    this.prefixIcon,
    this.initialValue,
    this.alignMessage,
    this.autoFocus,
    this.maxLength,
    this.submitNotifier,
    this.alwaysShowSuccessState = true,
    this.showOnlyLoadingState = false,
    super.key,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final _textController = TextEditingController();
  final _debouncer = Debouncer(const Duration(milliseconds: 300));
  final ValueNotifier<ExecutionState> _executionStateNotifier =
      ValueNotifier(ExecutionState.idle);

  @override
  void initState() {
    widget.submitNotifier?.addListener(() {
      _onSubmit();
    });
    _executionStateNotifier.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.submitNotifier?.dispose();
    _executionStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialValue != null) {
      _textController.value = TextEditingValue(
        text: widget.initialValue!,
        selection: TextSelection.collapsed(offset: widget.initialValue!.length),
      );
    }
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    var textInputChildren = <Widget>[];
    if (widget.label != null) textInputChildren.add(Text(widget.label!));
    textInputChildren.add(
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Material(
          child: TextFormField(
            autofocus: widget.autoFocus ?? false,
            controller: _textController,
            inputFormatters: widget.maxLength != null
                ? [LengthLimitingTextInputFormatter(50)]
                : null,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: textTheme.body.copyWith(color: colorScheme.textMuted),
              filled: true,
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
                borderSide: BorderSide(color: colorScheme.strokeMuted),
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 175),
                  switchInCurve: Curves.easeInExpo,
                  switchOutCurve: Curves.easeOutExpo,
                  child: SuffixIconWidget(
                    _executionStateNotifier.value,
                    key: ValueKey(_executionStateNotifier.value),
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
                maxWidth: 36,
                minHeight: 24,
                minWidth: 36,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: colorScheme.strokeMuted,
                    )
                  : null,
            ),
            onEditingComplete: () {},
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

  Future<void> _onSubmit() async {
    _debouncer.run(
      () => Future(
        () {
          _executionStateNotifier.value = ExecutionState.inProgress;
        },
      ),
    );
    await widget.onSubmit.call(_textController.text).then(
      (value) {
        widget.alwaysShowSuccessState
            ? _executionStateNotifier.value = ExecutionState.successful
            : null;
      },
      onError: (error, stackTrace) => _debouncer.cancelDebounce(),
    );
    _debouncer.cancelDebounce();
    if (widget.alwaysShowSuccessState) {
      Future.delayed(const Duration(seconds: 2), () {
        _executionStateNotifier.value = ExecutionState.idle;
      });
      return;
    }
    if (_executionStateNotifier.value == ExecutionState.inProgress) {
      if (widget.showOnlyLoadingState) {
        _executionStateNotifier.value = ExecutionState.idle;
      } else {
        _executionStateNotifier.value = ExecutionState.successful;
        Future.delayed(const Duration(seconds: 2), () {
          _executionStateNotifier.value = ExecutionState.idle;
        });
      }
    }
  }
}

class SuffixIconWidget extends StatelessWidget {
  final ExecutionState executionState;
  const SuffixIconWidget(this.executionState, {super.key});

  @override
  Widget build(BuildContext context) {
    final Widget trailingWidget;
    final colorScheme = getEnteColorScheme(context);
    if (executionState == ExecutionState.idle) {
      trailingWidget = const SizedBox.shrink();
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
