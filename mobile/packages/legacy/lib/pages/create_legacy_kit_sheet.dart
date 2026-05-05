import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_legacy/components/legacy_kit_icons.dart";
import "package:ente_legacy/components/recovery_date_selector.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/base_bottom_sheet.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class LegacyKitCreateInput {
  final List<String> partNames;
  final int noticePeriodInHours;

  const LegacyKitCreateInput({
    required this.partNames,
    required this.noticePeriodInHours,
  });
}

Future<LegacyKitCreateInput?> showCreateLegacyKitSheet(BuildContext context) {
  return showCreateLegacyKitPage(context);
}

Future<LegacyKitCreateInput?> showCreateLegacyKitPage(BuildContext context) {
  return Navigator.of(context).push<LegacyKitCreateInput>(
    MaterialPageRoute(
      builder: (context) => const CreateLegacyKitPage(),
    ),
  );
}

Future<LegacyKitCreateInput?> showCreateLegacyKitBottomSheet(
  BuildContext context,
) {
  return showBaseBottomSheet<LegacyKitCreateInput>(
    context,
    title: context.strings.createLegacyKit,
    headerSpacing: 20,
    isKeyboardAware: true,
    child: const CreateLegacyKitSheet(),
  );
}

Future<int?> showLegacyKitRecoveryWaitTimeSheet(
  BuildContext context, {
  required int selectedDays,
  bool showCancellationWarning = true,
}) {
  final colorScheme = getEnteColorScheme(context);
  final textTheme = getEnteTextTheme(context);
  return showBaseBottomSheet<int>(
    context,
    title: context.strings.recoveryWaitTime,
    headerSpacing: 16,
    backgroundColor: colorScheme.backgroundBase,
    padding: const EdgeInsets.all(20),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
    border: Border.all(color: colorScheme.fillMuted),
    titleTextStyle: textTheme.largeBold.copyWith(
      fontSize: 18.0,
      height: 24 / 18,
    ),
    child: _LegacyKitRecoveryWaitSheet(
      selectedDays: selectedDays,
      showCancellationWarning: showCancellationWarning,
    ),
  );
}

class CreateLegacyKitPage extends StatefulWidget {
  const CreateLegacyKitPage({super.key});

  @override
  State<CreateLegacyKitPage> createState() => _CreateLegacyKitPageState();
}

class _CreateLegacyKitPageState extends State<CreateLegacyKitPage> {
  final List<TextEditingController> _controllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());
  int _selectedDays = 7;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Text(
            "Create a legacy kit",
            style: textTheme.largeBold.copyWith(
              fontSize: 20.0,
              height: 28 / 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.strings.legacyKitCreateDescription,
            style: textTheme.smallMuted.copyWith(height: 20 / 14),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < _controllers.length; index++) ...[
            _LegacyKitNameField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              hintText: _hintForIndex(context, index),
              textInputAction:
                  index == 2 ? TextInputAction.done : TextInputAction.next,
              onSubmitted: (_) {
                if (index < 2) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                }
              },
              onChanged: (_) => setState(() {}),
            ),
            if (index < _controllers.length - 1) const SizedBox(height: 16),
          ],
          const SizedBox(height: 20),
          MenuSectionTitle(
            title: context.strings.settings,
            padding: EdgeInsets.zero,
            textStyle: textTheme.bodyBold,
          ),
          const SizedBox(height: 8),
          _RecoveryWaitTimeRow(
            title: context.strings.recoveryWaitTime,
            value: _formatNoticePeriod(_selectedDays * 24),
            onTap: _editRecoveryWaitTime,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: colorScheme.backgroundBase,
          padding: const EdgeInsets.all(24),
          child: GradientButton(
            text: context.strings.createKit,
            height: 48,
            textStyle: textTheme.small.copyWith(height: 20 / 14),
            onTap: _isValid ? _submit : null,
          ),
        ),
      ),
    );
  }

  Future<void> _editRecoveryWaitTime() async {
    final selectedDays = await showLegacyKitRecoveryWaitTimeSheet(
      context,
      selectedDays: _selectedDays,
      showCancellationWarning: false,
    );
    if (selectedDays != null && mounted) {
      setState(() {
        _selectedDays = selectedDays;
      });
    }
  }

  bool get _isValid {
    final names = _partNames;
    return names.length == 3 &&
        names.every((name) => name.isNotEmpty) &&
        names.toSet().length == 3;
  }

  List<String> get _partNames {
    return _controllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  void _submit() {
    Navigator.of(context).pop(
      LegacyKitCreateInput(
        partNames: _partNames,
        noticePeriodInHours: _selectedDays * 24,
      ),
    );
  }

  String _hintForIndex(BuildContext context, int index) {
    const examples = ["Mom", "Alex", "Lawyer"];
    return "e.g. ${examples[index]}";
  }

  String _formatNoticePeriod(int hours) {
    if (hours == 0) {
      return context.strings.immediate;
    }
    if (hours % 24 == 0) {
      return context.strings.nDays(hours ~/ 24);
    }
    return context.strings.nHours(hours);
  }
}

class _RecoveryWaitTimeRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _RecoveryWaitTimeRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final cardColor = colorScheme.isLightTheme
        ? Colors.white
        : colorScheme.backgroundElevated2;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  height: 36,
                  width: 36,
                  child: Center(
                    child: LegacyKitClockIcon(
                      color: colorScheme.primary700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.small.copyWith(height: 20 / 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: textTheme.mini.copyWith(
                          color: colorScheme.textMuted,
                          height: 16 / 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Center(
                    child: LegacyKitEditIcon(
                      color: colorScheme.textBase,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateLegacyKitSheet extends StatefulWidget {
  const CreateLegacyKitSheet({super.key});

  @override
  State<CreateLegacyKitSheet> createState() => _CreateLegacyKitSheetState();
}

class _LegacyKitRecoveryWaitSheet extends StatefulWidget {
  final int selectedDays;
  final bool showCancellationWarning;

  const _LegacyKitRecoveryWaitSheet({
    required this.selectedDays,
    required this.showCancellationWarning,
  });

  @override
  State<_LegacyKitRecoveryWaitSheet> createState() =>
      _LegacyKitRecoveryWaitSheetState();
}

class _LegacyKitRecoveryWaitSheetState
    extends State<_LegacyKitRecoveryWaitSheet> {
  late int _selectedDays = widget.selectedDays;
  bool get _hasChanges => _selectedDays != widget.selectedDays;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How long before account recovery can happen after your sheets are scanned.",
          style: textTheme.small.copyWith(
            color: colorScheme.textMuted,
            height: 20 / 14,
          ),
        ),
        if (widget.showCancellationWarning) ...[
          const SizedBox(height: 12),
          Text(
            "Changing this will cancel any ongoing attempts.",
            style: textTheme.small.copyWith(
              color: colorScheme.textMuted,
              height: 20 / 14,
            ),
          ),
        ],
        const SizedBox(height: 16),
        RecoveryDateSelector(
          selectedDays: _selectedDays,
          dayOptions: const [0, 1, 7, 15, 30],
          layout: RecoveryDateSelectorLayout.list,
          onDaysChanged: (days) {
            setState(() {
              _selectedDays = days;
            });
          },
        ),
        const SizedBox(height: 16),
        GradientButton(
          text: context.strings.confirm,
          height: 52,
          textStyle: textTheme.small.copyWith(height: 20 / 14),
          disabledTextColor: colorScheme.textFaint,
          onTap: _hasChanges
              ? () => Navigator.of(context).pop(_selectedDays)
              : null,
        ),
      ],
    );
  }
}

class _LegacyKitNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _LegacyKitNameField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textInputAction,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final fillColor = colorScheme.isLightTheme
        ? Colors.white
        : colorScheme.backgroundElevated2;

    return SizedBox(
      height: 52,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: textTheme.small.copyWith(height: 20 / 14),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          fillColor: fillColor,
          filled: true,
          hintText: hintText,
          hintStyle: textTheme.small.copyWith(
            color: colorScheme.textFaint,
            height: 20 / 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary700, width: 2),
          ),
        ),
        textCapitalization: TextCapitalization.words,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
      ),
    );
  }
}

class _CreateLegacyKitSheetState extends State<CreateLegacyKitSheet> {
  final List<TextEditingController> _controllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _selectedDays = 7;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final canCreate = _isValid;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.legacyKitCreateDescription,
            style: textTheme.smallMuted,
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
              child: TextFormField(
                controller: _controllers[index],
                decoration: InputDecoration(
                  fillColor: colorScheme.fillFaint,
                  filled: true,
                  hintText: context.strings.legacyKitPartNameHint(index + 1),
                  hintStyle: TextStyle(color: colorScheme.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.strokeMuted),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction:
                    index == 2 ? TextInputAction.done : TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text(
            context.strings.recoveryWaitTime,
            style: textTheme.bodyMuted,
          ),
          const SizedBox(height: 12),
          RecoveryDateSelector(
            selectedDays: _selectedDays,
            dayOptions: const [0, 1, 7, 15, 30],
            onDaysChanged: (days) {
              setState(() {
                _selectedDays = days;
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            context.strings.legacyKitStorageGuidance,
            style: textTheme.smallMuted,
          ),
          const SizedBox(height: 20),
          GradientButton(
            text: context.strings.createLegacyKit,
            onTap: canCreate ? _submit : null,
          ),
        ],
      ),
    );
  }

  bool get _isValid {
    final names = _partNames;
    return names.length == 3 &&
        names.every((name) => name.isNotEmpty) &&
        names.toSet().length == 3;
  }

  List<String> get _partNames {
    return _controllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  void _submit() {
    Navigator.of(context).pop(
      LegacyKitCreateInput(
        partNames: _partNames,
        noticePeriodInHours: _selectedDays * 24,
      ),
    );
  }
}
